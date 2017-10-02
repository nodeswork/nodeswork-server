/* tslint:disable:no-console */

import * as _             from 'underscore';
import {
  RequestAPI,
  RequiredUriUrl,
  CookieJar,
}                         from 'request';
import * as request       from 'request-promise';

import * as logger        from '@nodeswork/logger';
import { NodesworkError } from '@nodeswork/utils';

import * as defaults      from './defaults';
import * as urls          from './urls';

import * as fs            from 'fs-extra';

const LOG                                = logger.getLogger();
const FIFA_FUT18_CLIENT_OPTIONS_DEFAULT  = {
  userAgent: defaults.DEFAULT_USER_AGENT,
};

export namespace errors {

  export const UNKNOWN_AUTH_RESPONSE_ERROR = NodesworkError.internalServerError(
    'Unknown Fifa FUT 18 auth response',
  );

  export const UNKNOWN_AUTH_PROMPT_RESPONSE_ERROR =
    NodesworkError.internalServerError(
      'Unknown Fifa FUT 18 auth prompt response',
    );

  export const UNKNOWN_LOGIN_FORM_RESPONSE_ERROR =
    NodesworkError.internalServerError(
      'Unknown Fifa FUT 18 login form response',
    );

  export const UNKNOWN_LOGIN_FORM_VERIFY_RESPONSE_ERROR =
    NodesworkError.internalServerError(
      'Unknown Fifa FUT 18 login form verify response title',
    );

  export const REQUIRE_LOGIN_VERIFICATION_ERROR =
    NodesworkError.internalServerError(
      'Require Fifa FUT 18 Login Verification',
    );

  export const INVALID_CREDENTIALS_ERROR =
    NodesworkError.internalServerError(
      'Invalid Fifa FUT 18 Login Credentials',
    );
}

export class FifaFut18Client {

  private defaultRequest: RequestAPI<request.RequestPromise, request.RequestPromiseOptions, RequiredUriUrl>;

  constructor(private options: FifaFut18ClientOptions) {
    _.defaults(options, FIFA_FUT18_CLIENT_OPTIONS_DEFAULT);
    this.defaultRequest = request.defaults({
      jar: options.jar,
      followAllRedirects: true,
      gzip: true,
      headers: {
        'User-Agent':       options.userAgent,
        'Accept':           defaults.DEFAULT_ACCEPT,
        'Accept-Encoding':  'gzip, deflate',
        'Accept-Language':  'en-US,en;q=0.8',
        'Connection':       'keep-alive',
        'DNT':              '1',
        'Cache-Control':    'max-age=0',
      },
    });
  }

  public async ensureLogin() {
    console.log(this.options.jar);

    let resp = await this.defaultRequest.get({
      uri:                      urls.HOME,
      json:                     true,
      resolveWithFullResponse:  true,
    });

    // console.log('step 1');
    // console.log('home headers', resp.headers);
    // saveToFile('1.home.html', resp.body);
    // console.log('request headers', resp.request.headers);
    // console.log('location', resp.request.href);
    // console.log('jar', this.options.jar);
    // console.log('--------------------------------------------------------');

    resp = await this.defaultRequest.get({
      uri:                      urls.accounts.AUTH,
      json:                     true,
      resolveWithFullResponse:  true,
      headers:                  {
        Referer:                urls.HOME,
        Host:                   'accounts.ea.com',
        Origin:                 'https://www.easports.com',
      },
    });

    // console.log('step 2');
    // console.log('auth headers', resp.headers);
    // console.log('auth data', resp.body);
    // console.log('request headers', resp.request.headers);
    // console.log('location', resp.request.href);
    // console.log('jar', this.options.jar);
    // console.log('--------------------------------------------------------');

    if (resp.body.error === 'login_required') {
      LOG.debug('Auth check: account is not login');
      await this.login();
    } else {
      throw errors.UNKNOWN_AUTH_RESPONSE_ERROR;
    }

    LOG.debug('Final jar', this.options.jar);
    return;
  }

  private async login() {
    LOG.debug('Login Fifa FUT 18 account');
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

    LOG.debug('Auth Prompt result', {
      title,
      formUrl,
      jar: this.options.jar,
    });

    switch (title) {

      case 'Log In':
        await this.loginWithCredentials(formUrl);
        break;

      default:
        throw errors.UNKNOWN_AUTH_PROMPT_RESPONSE_ERROR;
    }

    // console.log('auth prompt headers', resp.headers);
    // saveToFile('2.1.1.auth prompt-data.html', resp.body);
    // console.log('request headers', resp.request.headers);
    // console.log('location', resp.request.href);
    // console.log('jar', this.options.jar);
    // console.log('title', parseTitle(resp.body));
    // console.log('--------------------------------------------------------');

    // const loginFormUrl = resp.request.href;

    // console.log('loginFormUrl', loginFormUrl);

    // resp = await this.defaultRequest.get({
      // uri:                            loginFormUrl,
      // json:                           true,
      // headers:                        {
        // 'Host':                       'signin.ea.com',
        // 'Origin':                     'https://signin.ea.com',
        // 'Referer':                    loginFormUrl,
        // 'Upgrade-Insecure-Requests':  '1',
      // },
      // resolveWithFullResponse:        true,
    // });

    // console.log('step 2.1.x');
    // console.log('headers', resp.headers);
    // saveToFile('2.2.x login.html', resp.body);
    // console.log('login data', resp.statusCode);
    // console.log('request headers', resp.request.headers);
    // console.log('location', resp.request.href);
    // console.log('jar', this.options.jar);
    // console.log('--------------------------------------------------------');
  }

  private async loginWithCredentials(formUrl: string) {
    LOG.debug('Login with credentials', { formUrl });
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
        password:                     this.options.password,
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

    switch (title) {
      case 'Login Verification':
        throw errors.REQUIRE_LOGIN_VERIFICATION_ERROR;

      default:
        throw errors.UNKNOWN_LOGIN_FORM_VERIFY_RESPONSE_ERROR;
    }
  }

  public async loginVerification(code: string) {
    // TODO:
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
  password:    string;
  secret:      string;
  platform:    string;
  jar:         CookieJar;

  userAgent?:  string;
}
