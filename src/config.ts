export let config: Config = require('yaml-env-config')('../config');

export interface Config {
  app:                      {
    env:                    string
  }

  secrets:                  {
    mailerSMPTTransporter:  string
  }
}
