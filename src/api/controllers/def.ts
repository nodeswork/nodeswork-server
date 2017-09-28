import * as Router          from 'koa-router';
import * as models          from '../models';

export interface UserAppletContext extends Router.IRouterContext {
  userApplet: models.UserApplet;
}

export interface AccountContext extends Router.IRouterContext {
  account: models.Account;
}

export interface UserContext extends Router.IRouterContext {
  user: models.User;
}

export interface DeviceContext extends Router.IRouterContext {
  device: models.Device;
}
