/* tslint:disable:max-line-length */
import * as mongoose          from 'mongoose';

import {
  DataLevelModel,
  KoaMiddlewares,
  Model,
  NModel,
  SoftDeleteModel,
  TimestampModel,
}                             from '@nodeswork/sbase/dist/mongoose';
import {
  MetricsModel,
}                             from '@nodeswork/sbase/dist/metrics';

import * as accounts          from './accounts/accounts';
import * as cookieAccounts    from './accounts/cookie-accounts';
import * as oauthAccounts     from './accounts/oauth-accounts';
import * as fifaFut18Accounts from './accounts/fifa-fut-18-accounts';
import * as users             from './users/users';
import * as tokens            from './tokens';
import * as devices           from './devices/devices';
import * as applets           from './applets/applets';
import * as userApplets       from './applets/user-applets';
import * as accountOperations from './executions/account-operations';
import * as appletExecutions  from './executions/applet-executions';

export type Account            = accounts.Account;
export const Account           = accounts.Account.$register<accounts.Account, accounts.AccountType>();

export type OAuthAccount       = oauthAccounts.OAuthAccount;
export const OAuthAccount      = oauthAccounts.OAuthAccount.$register<oauthAccounts.OAuthAccount, oauthAccounts.OAuthAccountType>();

export type CookieAccount      = cookieAccounts.CookieAccount;
export const CookieAccount     = cookieAccounts.CookieAccount.$register<cookieAccounts.CookieAccount, cookieAccounts.CookieAccountType>();

export type FifaFut18Account   = fifaFut18Accounts.FifaFut18Account;
export const FifaFut18Account  = fifaFut18Accounts.FifaFut18Account.$register<fifaFut18Accounts.FifaFut18Account, fifaFut18Accounts.FifaFut18AccountType>();

export type User               = users.User;
export const User              = users.User.$register<users.User, users.UserType>();

export type Token              = tokens.Token;
export const Token             = tokens.Token.$register<tokens.Token, tokens.TokenType>();

export type Device             = devices.Device;
export const Device            = devices.Device.$register<devices.Device, devices.DeviceType>();

export type UserDevice         = devices.UserDevice;
export const UserDevice        = devices.UserDevice.$register<devices.UserDevice, devices.UserDeviceType>();

export type Applet             = applets.Applet;
export const Applet            = applets.Applet.$register<applets.Applet, applets.AppletType>();

export type UserApplet         = userApplets.UserApplet;
export const UserApplet        = userApplets.UserApplet.$register<userApplets.UserApplet, userApplets.UserAppletType>();

export type AccountOperation   = accountOperations.AccountOperation;
export const AccountOperation  = accountOperations.AccountOperation.$register<accountOperations.AccountOperation, accountOperations.AccountOperationType>();

export type AppletExecution    = appletExecutions.AppletExecution;
export const AppletExecution   = appletExecutions.AppletExecution.$register<appletExecutions.AppletExecution, appletExecutions.AppletExecutionType>();
