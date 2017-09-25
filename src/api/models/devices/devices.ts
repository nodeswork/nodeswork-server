import * as _                  from 'underscore';
import * as mongoose           from 'mongoose';
import * as sbase              from '@nodeswork/sbase';

import { generateToken }       from '../../../utils/tokens';
import { deviceSocketManager } from '../../sockets';
import { Applet, AppletImage } from '../applets/applets';
import * as models             from '../../models';

export const DEVICE_DATA_LEVELS = {
  DETAIL: 'DETAIL',
  TOKEN:  'TOKEN',
};

export type DeviceTypeT = typeof Device & sbase.mongoose.NModelType;
export interface DeviceType extends DeviceTypeT {}

export class AppletStatus extends AppletImage {

  @sbase.mongoose.Field({
    type:       Number,
    required:   true,
  })
  public port:    number;

  @sbase.mongoose.Field({
    type:       String,
    required:   true,
  })
  public status:  string;
}

@sbase.mongoose.Config({
  collection:        'devices',
  discriminatorKey:  'deviceType',
  dataLevel:         {
    levels:          [ DEVICE_DATA_LEVELS.DETAIL, DEVICE_DATA_LEVELS.TOKEN ],
    default:         DEVICE_DATA_LEVELS.DETAIL,
  },
  toObject:          {
    virtuals:        true,
  },
  id: false,
})
export class Device extends sbase.mongoose.NModel {

  public static DATA_LEVELS = DEVICE_DATA_LEVELS;

  @sbase.mongoose.Field({
    type:            String,
    required:        true,
    index:           true,
    unique:          true,
    default:         generateToken,
    api:             sbase.mongoose.AUTOGEN,
    level:           DEVICE_DATA_LEVELS.TOKEN,
  })
  public token:             string;

  @sbase.mongoose.Field({
    type:            String,
    enum:            [ 'MacOS', 'Linux', 'Windows' ],
    required:        true,
    level:           DEVICE_DATA_LEVELS.DETAIL,
  })
  public os:                string;

  @sbase.mongoose.Field({
    type:            String,
    required:        true,
    level:           DEVICE_DATA_LEVELS.DETAIL,
  })
  public osVersion:         string;

  @sbase.mongoose.Field({
    type:            String,
    required:        true,
    level:           DEVICE_DATA_LEVELS.DETAIL,
  })
  public containerVersion:  string;

  @sbase.mongoose.Field({
    type:            [ AppletStatus.$mongooseOptions().mongooseSchema ],
    level:           DEVICE_DATA_LEVELS.DETAIL,
    api:             sbase.mongoose.AUTOGEN,
    default:         [],
  })
  public runningApplets:    AppletStatus[];

  @sbase.mongoose.Field({
    type:            [ AppletImage.$mongooseOptions().mongooseSchema ],
    level:           DEVICE_DATA_LEVELS.DETAIL,
    api:             sbase.mongoose.AUTOGEN,
    default:         [],
  })
  public installedApplets:  AppletImage[];

  @sbase.mongoose.Field({
    type:            [ AppletImage.$mongooseOptions().mongooseSchema ],
    level:           DEVICE_DATA_LEVELS.DETAIL,
    api:             sbase.mongoose.AUTOGEN,
    default:         [],
  })
  public scheduledApplets:  AppletImage[];

  public async updateScheduledApplets(userApplets: models.UserApplet[]) {
    const scheduledApplets: AppletImage[] = [];

    for (const ua of userApplets) {
      const appletConfig = await ua.populateAppletConfig();
      scheduledApplets.push(appletConfig);
    }

    this.scheduledApplets = scheduledApplets;
    await this.save();
  }

  get online(): boolean {
    return deviceSocketManager.isDeviceOnline(this._id.toString());
  }
}

export type UserDeviceTypeT = typeof UserDevice & sbase.mongoose.NModelType;
export interface UserDeviceType extends UserDeviceTypeT {}

export class UserDevice extends Device {

  public static $SCHEMA: object = {

    user:              {
      type:            mongoose.Schema.Types.ObjectId,
      ref:             'User',
      required:        true,
      index:           true,
      api:             sbase.mongoose.READONLY,
    },

    deviceIdentifier:  {
      type:            String,
      required:        true,
      level:           DEVICE_DATA_LEVELS.DETAIL,
      api:             sbase.mongoose.READONLY,
    },

    name:              {
      type:            String,
      default:         'My Device',
    },

    dev:               {
      type:            Boolean,
      default:         false,
      level:           DEVICE_DATA_LEVELS.DETAIL,
      api:             sbase.mongoose.AUTOGEN,
    },
  };
}
