/* tslint:disable:max-line-length */

export const HOME = 'https://www.easports.com/fifa/ultimate-team/web-app/';

export namespace fut18 {

  export const REFERER   = 'https://www.easports.com/iframe/fut17/?locale=en_US&baseShowoffUrl=https%3A%2F%2Fwww.easports.com%2Fde%2Ffifa%2Fultimate-team%2Fweb-app%2Fshow-off&guest_app_uri=http%3A%2F%2Fwww.easports.com%2Fde%2Ffifa%2Fultimate-team%2Fweb-app';
  export const EASPORTS  = 'https://www.easports.com';

  export const ACCOUNT_INFO_PATH = '/ut/game/fifa18/user/accountinfo?filterConsoleLogin=true&sku=FUT18WEB&returningUserGameYear=2017';

  export const PHISHING_QUESTION_PATH = '/ut/game/fifa18/phishing/question';

  export const PHISHING_VALIDATE_PATH = '/ut/game/fifa18/phishing/validate?answer=';

  export const GET_SID_PATH = '/ut/auth';
}

export namespace accounts {

  export const AUTH = 'https://accounts.ea.com/connect/auth?client_id=FIFA-18-WEBCLIENT&response_type=token&display=web2/login&locale=en_US&redirect_uri=nucleus:rest&prompt=none&scope=basic.identity+offline+signin';

  export const AUTH_PROMPT = 'https://accounts.ea.com/connect/auth?prompt=login&accessToken=null&client_id=FIFA-18-WEBCLIENT&response_type=token&display=web2/login&locale=en_US&redirect_uri=https://www.easports.com/fifa/ultimate-team/web-app/auth.html&scope=basic.identity+offline+signin';

  export const PROXY_IDENTITY = 'https://gateway.ea.com/proxy/identity/pids/me';

  export const AUTH_CHECK = 'https://accounts.ea.com/connect/auth?client_id=FOS-SERVER&redirect_uri=nucleus:rest&response_type=code&access_token=';

  export const SHARD_INFO_URL = 'https://utas.mob.v4.fut.ea.com/ut/shards/v2';
}
