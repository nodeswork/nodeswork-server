export let config: Config = require('yaml-env-config')('../config');

export interface Config {
  app:                      {
    env:                    string
    publicHost:             string
  }

  mailer:                   {
    sender:                 string
  }

  secrets:                  {
    mailerUsername:         string
    mailerSMPTTransporter:  string
  }
}
