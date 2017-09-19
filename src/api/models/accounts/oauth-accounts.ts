import * as mongoose            from 'mongoose';
import * as _                   from 'underscore';

import * as sbase               from '@nodeswork/sbase';
import { NodesworkError }       from '@nodeswork/utils';

import { Account, AccountType } from './accounts';
import { OAuth }                from '../../../utils/oauth';

const CALLBACK_URL  = '/';

export type OAuthAccountTypeT = typeof OAuthAccount & AccountType;
export interface OAuthAccountType extends OAuthAccountTypeT {}

const OAuthConfig = new mongoose.Schema({
  requestTokenUrl:  String,
  accessTokenUrl:   String,
  consumerKey:      String,
  consumerSecret:   String,
}, { _id: false, id: false });

export interface OAuthConfig {
  requestTokenUrl:  string;
  accessTokenUrl:   string;
  consumerKey:      string;
  consumerSecret:   string;
}

@sbase.mongoose.Config({})
export class OAuthAccount extends Account {

  @sbase.mongoose.Field({
    type:      String,
    enum:      ['twitter', 'customized'],
    required:  true,
  })
  public provider: string;

  @sbase.mongoose.Field({
    type: OAuthConfig,
  })
  public oAuthConfig: OAuthConfig;

  @sbase.mongoose.Field({
    type:      String,
    level:     Account.DATA_LEVELS.CREDENTIAL,
  })
  public oAuthToken: string;

  @sbase.mongoose.Field({
    type:      String,
    level:     Account.DATA_LEVELS.CREDENTIAL,
  })
  public oAuthTokenSecret: string;

  @sbase.mongoose.Field({
    type:      String,
    level:     Account.DATA_LEVELS.TOKEN,
  })
  public accessToken: string;

  @sbase.mongoose.Field({
    type:      String,
    level:     Account.DATA_LEVELS.CREDENTIAL,
  })
  public accessTokenSecret: string;

  /**
   * Return the oauth config based on provider.
   */
  public getOAuthConfig(): OAuthConfig {
    return null;
  }

  private getOAuthClient(): OAuth {
    const config = this.getOAuthConfig();
    return new OAuth(
      config.requestTokenUrl, config.accessTokenUrl, config.consumerKey,
      config.consumerSecret, CALLBACK_URL,
    );
  }

  /**
   * Step 1 of the verification process, triggered after account creation or
   * manually start the verify process.  The target is to gain oAuthToken and
   * redirect user's browser to 3rd-party website to gain the access token.
   */
  public async requestOAuthToken() {
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
    await this.save();
  }
}
