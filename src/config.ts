export let config: Config = require("yaml-env-config")("../config");

export interface Config {
  app:                      {
    env:                    string;
    port:                   number;
    db:                     string;
    publicHost:             string;
    CORS:                   string;
    oAuthCallbackUrl:       string;
    oAuthTokenUrls:         {
      [provider: string]:   OAuthTokenUrls;
    };
  };

  mailer:                   {
    sender:                 string;
  };

  secrets:                  {
    mailerUsername:         string;
    mailerSMPTTransporter:  string;
    oAuthSecrets:           {
      [provider: string]:   OAuthSecrets;
    };
  };
}

export interface OAuthTokenUrls {
  requestTokenUrl:  string;
  accessTokenUrl:   string;
  authorizeUrl:     string;
}

export interface OAuthSecrets {
  consumerKey:      string;
  consumerSecret:   string;
}
