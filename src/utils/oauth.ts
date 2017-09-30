import * as _     from 'underscore';
import {
  ErrorOptions,
  NodesworkError,
}                 from '@nodeswork/utils';

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
    return await new Promise<AccessTokenPair>((resolve, reject) => {
      this.oAuthClient.getOAuthAccessToken(
        oAuthTokenPair.oAuthToken, oAuthTokenPair.oAuthTokenSecret, verifier,
        (err: any, accessToken: string, accessTokenSecret: string) => {
          if (err != null) {
            reject(err);
          } else {
            resolve({ accessToken, accessTokenSecret });
          }
        },
      );
    });
  }

  public async get(
    url: string, accessToken: string, accessTokenSecret: string,
  ): Promise<any> {
    return await new Promise((resolve, reject) => {
      this.oAuthClient.get(
        url, accessToken, accessTokenSecret,
        (err: any, data: any) => {
          if (err != null) {
            reject(err);
          } else {
            resolve(JSON.parse(data));
          }
        },
      );
    });
  }

  public async post(
    url: string, accessToken: string, accessTokenSecret: string, body: any,
  ): Promise<any> {
    return await new Promise((resolve, reject) => {
      this.oAuthClient.post(
        url, accessToken, accessTokenSecret, body,
        (err: any, data: any) => {
          if (err != null) {
            reject(err);
          } else {
            resolve(JSON.parse(data));
          }
        },
      );
    });
  }

  public async put(
    url: string, accessToken: string, accessTokenSecret: string, body: any,
  ): Promise<any> {
    return await new Promise((resolve, reject) => {
      this.oAuthClient.put(
        url, accessToken, accessTokenSecret, body,
        (err: any, data: any) => {
          if (err != null) {
            reject(err);
          } else {
            resolve(JSON.parse(data));
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

const OAuthErrorCaster = {

  filter: (error: any, options: ErrorOptions): boolean => {
    return error.statusCode != null && error.data != null;
  },

  cast: (error: any, options: ErrorOptions): NodesworkError => {
    const data = _.isString(error.data) ? JSON.parse(error.data) : error.data;
    return new NodesworkError('OAuth Client Error', {
      responseCode: error.statusCode,
      data,
    });
  },
};

NodesworkError.addErrorCaster(OAuthErrorCaster);
