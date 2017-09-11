import * as mongoose from 'mongoose';

import * as tokens   from './tokens';
import * as users    from './users/users';
import * as devices  from './devices/devices';
import * as applets  from './applets/applets';

export let Token       = tokens.Token.$register<tokens.Token, tokens.TokenType>();
export let User        = users.User.$register<users.User, users.UserType>();
export let Device      = devices.Device.$register<devices.Device, devices.DeviceType>();
export let UserDevice  = devices.UserDevice.$register<devices.UserDevice, devices.UserDeviceType>();
export let Applet      = applets.Applet.$register<applets.Applet, applets.AppletType>();
