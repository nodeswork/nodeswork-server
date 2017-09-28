import { URL }            from 'url';
import * as mongoose      from 'mongoose';
import * as _             from 'underscore';

import * as sbase         from '@nodeswork/sbase';
import { NodesworkError } from '@nodeswork/utils';

import {
  Account,
  AccountType,
  AccountOperateOptions,
  AccountOperateResult,
}                         from './accounts';
import { OAuth }          from '../../../utils/oauth';
import { config }         from '../../../config';
import * as errors        from '../../errors';
import * as models        from '../../models';

const CALLBACK_URL  = config.app.oAuthCallbackUrl;

export type OAuthAccountTypeT = typeof OAuthAccount & AccountType;
export interface OAuthAccountType extends OAuthAccountTypeT {}

const OAuthConfig = new mongoose.Schema({
  requestTokenUrl:  String,
  accessTokenUrl:   String,
  authorizeUrl:     String,
  consumerKey:      String,
  consumerSecret:   String,
}, { _id: false, id: false });

export interface OAuthConfig {
  requestTokenUrl:  string;
  accessTokenUrl:   string;
  authorizeUrl:     string;
  consumerKey:      string;
  consumerSecret:   string;
}

@sbase.mongoose.Config({})
export class OAuthAccount extends Account {

  @sbase.mongoose.Field({
    type: OAuthConfig,
  })
  public oAuthConfig: OAuthConfig;

  @sbase.mongoose.Field({
    type:      String,
    level:     Account.DATA_LEVELS.CREDENTIAL,
    api:       sbase.mongoose.AUTOGEN,
  })
  public oAuthToken: string;

  @sbase.mongoose.Field({
    type:      String,
    level:     Account.DATA_LEVELS.CREDENTIAL,
    api:       sbase.mongoose.AUTOGEN,
  })
  public oAuthTokenSecret: string;

  @sbase.mongoose.Field({
    type:      String,
    level:     Account.DATA_LEVELS.TOKEN,
    api:       sbase.mongoose.AUTOGEN,
  })
  public accessToken: string;

  @sbase.mongoose.Field({
    type:      String,
    level:     Account.DATA_LEVELS.CREDENTIAL,
    api:       sbase.mongoose.AUTOGEN,
  })
  public accessTokenSecret: string;

  public reset() {
    this.oAuthToken         = null;
    this.oAuthTokenSecret   = null;
    this.accessToken        = null;
    this.accessTokenSecret  = null;
  }

  /**
   * Return the oauth config based on provider.
   */
  public getOAuthConfig(): OAuthConfig {
    const oAuthTokenUrls = config.app.oAuthTokenUrls[this.provider];
    if (oAuthTokenUrls !== null) {
      const oAuthSecrets = config.secrets.oAuthSecrets[this.provider];
      return _.extend({}, oAuthTokenUrls, oAuthSecrets);
    }

    return this.oAuthConfig;
  }

  private getOAuthClient(): OAuth {
    const oAuthConfig = this.getOAuthConfig();
    return new OAuth(
      oAuthConfig.requestTokenUrl, oAuthConfig.accessTokenUrl,
      oAuthConfig.consumerKey, oAuthConfig.consumerSecret, CALLBACK_URL,
    );
  }

  /**
   * Override verify method.
   */
  public async verify(): Promise<object> {
    this.reset();
    const oAuth         = this.getOAuthConfig();
    const authorizeUrl  = new URL(oAuth.authorizeUrl);
    await this.requestOAuthToken(oAuth);
    authorizeUrl.searchParams.append('oauth_token', this.oAuthToken);
    return {
      redirectTo: authorizeUrl.toString(),
    };
  }

  /**
   * Step 1 of the verification process, triggered after account creation or
   * manually start the verify process.  The target is to gain oAuthToken and
   * redirect user's browser to 3rd-party website to gain the access token.
   */
  public async requestOAuthToken(oAuthConfig: OAuthConfig) {
    const oAuth             = this.getOAuthClient();
    const oAuthTokenPair    = await oAuth.getOAuthRequestToken();
    this.oAuthToken         = oAuthTokenPair.oAuthToken;
    this.oAuthTokenSecret   = oAuthTokenPair.oAuthTokenSecret;
    await this.save();
  }

  /**
   * Step 2 of the verfication process, handling the callbacks from 3rd-party
   * website with the verifier to gain the access token.
   */
  public async requestAccessToken(verifier: string) {
    const oAuth             = this.getOAuthClient();
    const accessTokenPair   = await oAuth.getOAuthAccessToken({
      oAuthToken:        this.oAuthToken,
      oAuthTokenSecret:  this.oAuthTokenSecret,
    }, verifier);
    this.accessToken        = accessTokenPair.accessToken;
    this.accessTokenSecret  = accessTokenPair.accessTokenSecret;
    this.verified           = true;
    await this.updateAccountInfoFromRemote();
    await this.save();
  }

  public async updateAccountInfoFromRemote() {
    const oAuth             = this.getOAuthClient();
    if (this.provider === 'twitter') {
      const data = await oAuth.get(
        'https://api.twitter.com/1.1/account/verify_credentials.json',
        this.accessToken, this.accessTokenSecret,
      );
      this.name = data.name;
      this.imageUrl = data.profile_image_url;
      await this.save();
    }
  }

  public async operate(
    options: AccountOperateOptions,
    userApplet: models.UserApplet,
  ): Promise<AccountOperateResult> {
    return {
      status: 'operated by oauth account',
    };
  }
}
