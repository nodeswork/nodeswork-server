import * as mongoose    from 'mongoose';

import * as tokens      from './tokens';
import * as users       from './users/users';
import * as devices     from './devices/devices';
import * as applets     from './applets/applets';
import * as userApplets from './applets/user-applets';
import * as accounts    from './accounts/accounts';

export let Token         = tokens.Token.$register<tokens.Token, tokens.TokenType>();
export let User          = users.User.$register<users.User, users.UserType>();
export let Device        = devices.Device.$register<devices.Device, devices.DeviceType>();
export let UserDevice    = devices.UserDevice.$register<devices.UserDevice, devices.UserDeviceType>();
export let Applet        = applets.Applet.$register<applets.Applet, applets.AppletType>();
export let UserApplet    = userApplets.UserApplet.$register<userApplets.UserApplet, userApplets.UserAppletType>();
export let Account       = accounts.Account.$register<accounts.Account, accounts.AccountType>();

export type Token        = tokens.Token;
export type User         = users.User;
export type Device       = devices.Device;
export type UserDevice   = devices.UserDevice;
export type Applet       = applets.Applet;
export type UserApplet   = userApplets.UserApplet;
export type Account      = accounts.Account;
