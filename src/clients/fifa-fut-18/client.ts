/* tslint:disable:no-console */

import * as _           from 'underscore';
import {
  RequestAPI,
  RequiredUriUrl,
  CookieJar,
}                       from 'request';
import * as request     from 'request-promise';
import { URL }          from 'url';

import * as logger      from '@nodeswork/logger';

import * as defaults    from './defaults';
import * as urls        from './urls';
import * as errors      from './errors';
import {
  DEFAULT_METADATA,
  Fifa18ClientMetadata,
  STATES,
  STATE_INDEX,
}                       from './defs';

import * as fs          from 'fs-extra';

const hasher                             = require('./hasher');

const LOG                                = logger.getLogger();

/**
 * State 1: require login
 * Stete 2: require security code verification
 * State 3: require gameSku
 * State 4: require phishing questions
 * State 5: ready
 */
export class FifaFut18Client {

  private defaultRequest: RequestAPI<request.RequestPromise, request.RequestPromiseOptions, RequiredUriUrl>;
  public  metadata: Fifa18ClientMetadata;

  constructor(public options: FifaFut18ClientOptions) {
    this.defaultRequest = request.defaults({
      jar:                  options.jar,
      json:                 true,
      followAllRedirects:   true,
      gzip:                 true,
      headers:              {
        'User-Agent':       defaults.DEFAULT_USER_AGENT,
        'Accept':           defaults.DEFAULT_ACCEPT,
        'Accept-Encoding':  'gzip, deflate',
        'Accept-Language':  'en-US,en;q=0.8',
        'Connection':       'keep-alive',
        'DNT':              '1',
        'Cache-Control':    'max-age=0',
        'Origin':           urls.fut18.EASPORTS,
        'Referer':          urls.HOME,
      },
    });
    this.metadata = _.extend({}, DEFAULT_METADATA, options.metadata);
  }

  /**
   * Refresh metadata.
   */
  public async refresh() {
    await this.initializeWithAuth();
    if (this.metadata.stateIndex > STATE_INDEX.REQUIRE_LOGIN) {
      await this.initializeWithGameSku();
    }
    if (this.metadata.stateIndex > STATE_INDEX.REQUIRE_GAME_SKU) {
      await this.initializeWithPhishing();
    }
  }

  /**
   * Login with credentials.
   */
  public async login(password: string) {
  }

  /**
   * Verify account with security code.
   */
  public async verifySecurityCode(code: string) {
  }

  /**
   * Choose platform for the account.
   */
  public async choosePlatform(platform: string) {
  }

  /**
   * Verify account with secret.
   */
  public async verifySecret(secret: string) {
    const hash: string = hasher(secret);
    await this.getUserAccountInfo();
    await this.getAuth(true);

    const resp = await this.defaultRequest.post({
      uri:                               this.metadata.sharedHost + urls.fut18.PHISHING_VALIDATE_PATH + hash,
      headers:                           {
        'Easw-Session-Data-Nucleus-Id':  this.metadata.pid.pidId,
        'X-UT-SID':                      this.metadata.auth.sid,
      },
      body:                              hash,
    });

    if (resp.code === "200") {
      this.metadata.phishingToken = resp.token;
      this.setState(STATES.READY);
    } else {
      this.setState(STATES.REQUIRE_PHISHING_QUESTIONS);
      this.metadata.errors = resp;
    }
  }

  private setState(state: string) {
    this.metadata.state       = state;
    this.metadata.stateIndex  = STATE_INDEX[state];
  }

  private async initializeWithAuth() {
    const resp = await this.defaultRequest.get({
      uri: urls.accounts.AUTH,
    });

    if (resp.error === 'login_required') {
      this.setState(STATES.REQUIRE_LOGIN);
    } else if (resp.access_token) {
      this.metadata.accessToken = resp.access_token;
      this.metadata.tokenType   = resp.token_type;
      this.setState(STATES.REQUIRE_GAME_SKU);
    } else {
      throw errors.UNKNOWN_AUTH_RESPONSE_ERROR;
    }
  }

  private async initializeWithGameSku() {
    if (this.metadata.gameSku != null) {
      this.setState(STATES.REQUIRE_PHISHING_QUESTIONS);
      return;
    }
    const skus = await this.getPossibleSku();
    if (skus.length === 1) {
      this.metadata.gameSku = skus[0];
      this.setState(STATES.REQUIRE_PHISHING_QUESTIONS);
      return;
    }
    this.setState(STATES.REQUIRE_GAME_SKU);
    this.metadata.gameSkuChoices = skus;
  }

  private async initializeWithPhishing() {
    await this.getUserAccountInfo();
    await this.getAuth();

    const resp = await this.defaultRequest.get({
      uri:                               this.metadata.sharedHost + urls.fut18.PHISHING_QUESTION_PATH,
      headers:                           {
        'Easw-Session-Data-Nucleus-Id':  this.metadata.pid.pidId,
        'X-UT-SID':                      this.metadata.auth.sid,
      },
    });

    if (resp.question != null) {
      this.metadata.phishingQuestionId = resp.question;
      this.setState(STATES.REQUIRE_PHISHING_QUESTIONS);
    } else {
      this.setState(STATES.READY);
    }
  }

  private async getPossibleSku(year: string = "2018"): Promise<string[]> {
    await this.getUserAccountInfo();
    return _
      .chain(this.metadata.userAccountInfo.personas)
      .map((persona) => persona.userClubList)
      .flatten()
      .filter((userClub) => userClub.year === year)
      .map((userClub) => Object.keys(userClub.skuAccessList))
      .flatten()
      .value();
  }

  private async getLoginFormUrl(): Promise<string> {
    const resp = await this.defaultRequest.get({
      uri:                            urls.accounts.AUTH_PROMPT,
      json:                           true,
      headers:                        {
        'Referer':                    urls.HOME,
        'Host':                       'accounts.ea.com',
        'Upgrade-Insecure-Requests':  '1',
      },
      resolveWithFullResponse:        true,
    });
    const title    = parseTitle(resp.body);
    const formUrl  = resp.request.href;

    if (title !== 'Log In') {
      throw errors.UNKNOWN_AUTH_PROMPT_RESPONSE_ERROR;
    }

    LOG.debug('getLoginFormUrl result', { formUrl, jar: this.options.jar });
    return formUrl;
  }

  private async loginWithCredential(
    formUrl: string, password: string,
  ): Promise<string> {
    const resp = await this.defaultRequest.post({
      uri:                            formUrl,
      json:                           true,
      headers:                        {
        'Host':                       'signin.ea.com',
        'Origin':                     'https://signin.ea.com',
        'Referer':                    formUrl,
        'Upgrade-Insecure-Requests':  '1',
      },
      form:                           {
        email:                        this.options.email,
        password,
        country:                      'US',
        phoneNumber:                  '',
        passwordForPhone:             '',
        _rememberMe:                  'on',
        rememberMe:                   'on',
        _eventId:                     'submit',
        gCaptchaResponse:             '',
        isPhoneNumberLogin:           'false',
        isIncompletePhone:            '',
      },
      resolveWithFullResponse:        true,
    });

    let title = parseTitle(resp.body);
    if (title === 'Log In') {
      throw errors.INVALID_CREDENTIALS_ERROR;
    }

    const redirectUrl  = parseRedirectUrl(resp.body);

    LOG.debug('Login with credentials result', {
      formUrl: resp.request.href,
      redirectUrl,
      jar: this.options.jar,
    });

    const resp2 = await this.defaultRequest.get({
      uri:                            redirectUrl,
      json:                           true,
      headers:                        {
        'Host':                       'signin.ea.com',
        'Origin':                     'https://signin.ea.com',
        'Referer':                    resp.request.href,
        'Upgrade-Insecure-Requests':  '1',
      },
      resolveWithFullResponse:        true,
    });
    title = parseTitle(resp2.body);

    console.log(resp2.body);
    console.log(resp2.request.href);

    if (title !== 'Login Verification') {
      throw errors.UNKNOWN_LOGIN_FORM_VERIFY_RESPONSE_ERROR;
    }

    const verificationUrl = resp2.request.href;

    LOG.debug('Fetch verification url result', { verificationUrl });

    return verificationUrl;
  }

  private async sendVerificationCode(verificationUrl: string): Promise<string> {
    const resp = await this.defaultRequest.post({
      uri:                            verificationUrl,
      json:                           true,
      headers:                        {
        'Host':                       'signin.ea.com',
        'Origin':                     'https://signin.ea.com',
        'Referer':                    verificationUrl,
        'Upgrade-Insecure-Requests':  '1',
      },
      form:                           {
        _eventId:                     'submit',
      },
      resolveWithFullResponse:        true,
    });
    const securityCodeVerificationUrl = resp.request.href;
    LOG.debug('Send verification code result', { securityCodeVerificationUrl });
    return securityCodeVerificationUrl;
  }

  public async loginO(password: string): Promise<Fifa18ClientMetadata> {
    LOG.debug('Login Fifa FUT 18 account');

    // const metadata         = await this.initializeWithAuth();
    // if (metadata != null) {
      // return metadata;
    // }

    const formUrl          = await this.getLoginFormUrl();
    const verificationUrl  = await this.loginWithCredential(formUrl, password);
    const securityCodeVerificationUrl = await this.sendVerificationCode(
      verificationUrl,
    );
    return { securityCodeVerificationUrl };
  }

  private async sendSecurityCode(code: string): Promise<Fifa18ClientMetadata> {
    const resp = await this.defaultRequest.post({
      uri:                            this.options.metadata.securityCodeVerificationUrl,
      json:                           true,
      headers:                        {
        'Host':                       'signin.ea.com',
        'Origin':                     'https://signin.ea.com',
        'Referer':                    this.options.metadata.securityCodeVerificationUrl,
        'Upgrade-Insecure-Requests':  '1',
      },
      form:                           {
        oneTimeCode:                  code,
        _trustThisDevice:             'on',
        trustThisDevice:              'on',
        _eventId:                     'submit',
      },
      resolveWithFullResponse:        true,
    });

    const u = new URL((resp.request.href as string).replace('#', '?'));
    const metadata = {
      tokenType:   u.searchParams.get('token_type'),
      accessToken: u.searchParams.get('access_token'),
    };

    LOG.debug('Send security code result', { url: u.toString(), metadata });
    return metadata;
  }

  private async getPid() {
    if (this.metadata.pid != null) {
      return;
    }

    const resp = await this.defaultRequest.get({
      uri:                            urls.accounts.PROXY_IDENTITY,
      headers:                        {
        'Accept':                     'application/json; charset=utf-8; */*; q=0.01',
        'Upgrade-Insecure-Requests':  '1',
        'Authorization':              `${this.metadata.tokenType} ${this.metadata.accessToken}`,
      },
    });
    this.metadata.pid = resp.pid;
  }

  private async getAuthCode(): Promise<string> {
    const resp = await this.defaultRequest.get({
      uri: urls.accounts.AUTH_CHECK + this.metadata.accessToken,
    });
    return resp.code;
  }

  private async getShardInfo() {
    if (this.metadata.sharedInfo != null) {
      return;
    }

    await this.getPid();

    const resp = await this.defaultRequest.get({
      uri:                               urls.accounts.SHARD_INFO_URL,
      headers:                           {
        'Easw-Session-Data-Nucleus-Id':  this.metadata.pid.pidId,
      },
    });
    this.metadata.sharedInfo = resp.shardInfo;
  }

  private async getUserAccountInfo() {
    if (this.metadata.userAccountInfo != null) {
      return;
    }

    await this.getShardInfo();

    const hosts = _.map(this.metadata.sharedInfo, (shareInfo) => {
      return `${shareInfo.clientProtocol}://${shareInfo.clientFacingIpPort}`;
    });

    for (const host of hosts) {
      try {
        const resp = await this.defaultRequest.get({
          uri:                               host + urls.fut18.ACCOUNT_INFO_PATH,
          headers:                           {
            'Easw-Session-Data-Nucleus-Id':  this.metadata.pid.pidId,
          },
        });
        this.metadata.sharedHost      = host;
        this.metadata.userAccountInfo = resp.userAccountInfo;
      } catch (e) {
        // CONTINUE
      }
    }

    if (this.metadata.userAccountInfo == null) {
      throw errors.UNKNOWN_USER_ACCOUNT_INFO_ERROR;
    }
  }

  /**
   * require gameSku.
   */
  private async getAuth(force: boolean = false) {
    if (this.metadata.auth != null && !force) {
      return;
    }

    await this.getUserAccountInfo();

    const code = await this.getAuthCode();

    const payload = {
      clientVersion:     1,
      gameSku:           this.metadata.gameSku,
      identification:    {
        authCode:        code,
        redirectUrl:     'nucleus:rest',
      },
      isReadOnly:        false,
      locale:            'en-US',
      method:            'authcode',
      nucleusPersonaId:  this.metadata.userAccountInfo.personas[0].personaId,
      priorityLevel:     4,
      sku:               'FUT18WEB',
    };

    const resp = await this.defaultRequest.post({
      uri:   this.metadata.sharedHost + urls.fut18.GET_SID_PATH + '?' + Date.now(),
      body:  payload,
    });

    this.metadata.auth = resp;
  }

  public async verifySecurityCodeO(code: string): Promise<Fifa18ClientMetadata> {
    LOG.debug('Verify Fifa FUT 18 account Security Code');

    let metadata  = this.options.metadata;
    metadata      = await this.sendSecurityCode(code);

    // metadata      = await this.getPid(metadata);
    // metadata      = await this.getShardInfo(metadata);
    // metadata      = await this.getAuthCode(metadata);
    // metadata      = await this.getAuth(metadata);

    return metadata;
  }
}

const PARSE_TITLE_REGEX = /<title>(.*)<\/title>/;
function parseTitle(content: string): string {
  const result = content.match(PARSE_TITLE_REGEX);
  return result && result[1];
}

const PARSE_STR_REGEX = /['"](.*)['"]/;
function parseRedirectUrl(content: string): string {
  const rest = _.filter(
    content.split('\n'), (line) => line.indexOf('redirectUri') >= 0,
  );
  const parts = _.map(rest, (s) => {
    const matched = s.match(PARSE_STR_REGEX);
    return matched != null ? matched[1] : '';
  });
  const result = parts.join('');
  if (result === '') {
    throw errors.UNKNOWN_LOGIN_FORM_RESPONSE_ERROR;
  }
  return result;
}

async function saveToFile(step: string, context: string) {
  const filename = `/tmp/${step}`;
  console.log('saved to', filename);
  fs.writeFileSync(filename, context);
}

export interface FifaFut18ClientOptions {
  email:       string;
  jar:         CookieJar;
  metadata:    Fifa18ClientMetadata;
}
