const OOAuth = require('oauth').OAuth;

export class OAuth {
  private oAuthClient: any;

  constructor(
    requestTokenUrl: string, accessTokenUrl: string, consumerKey: string,
    consumerSecret: string, callbackUrl: string,
  ) {
    this.oAuthClient = new OOAuth(
      requestTokenUrl, accessTokenUrl, consumerKey, consumerSecret, '1.0',
      callbackUrl, 'HMAC-SHA1',
    );
  }

  public async getOAuthRequestToken(): Promise<OAuthTokenPair> {
    return await new Promise<OAuthTokenPair>((resolve, reject) => {
      this.oAuthClient.getOAuthRequestToken(
        (err: any, oAuthToken: string, oAuthTokenSecret: string) => {
          if (err != null) {
            reject(err);
          } else {
            resolve({ oAuthToken, oAuthTokenSecret });
          }
        },
      );
    });
  }

  public async getOAuthAccessToken(
    oAuthTokenPair: OAuthTokenPair, verifier: string,
  ): Promise<AccessTokenPair> {
    console.log('requesting', oAuthTokenPair, verifier);
    return await new Promise<AccessTokenPair>((resolve, reject) => {
      this.oAuthClient.getOAuthAccessToken(
        oAuthTokenPair.oAuthToken, oAuthTokenPair.oAuthTokenSecret, verifier,
        (err: any, accessToken: string, accessTokenSecret: string) => {
          console.log('error from oAuthClient', err, accessToken, accessTokenSecret);
          if (err != null) {
            reject(err);
          } else {
            resolve({ accessToken, accessTokenSecret });
          }
        },
      );
    });
  }
}

export interface OAuthTokenPair {
  oAuthToken:        string;
  oAuthTokenSecret:  string;
}

export interface AccessTokenPair {
  accessToken:        string;
  accessTokenSecret:  string;
}
