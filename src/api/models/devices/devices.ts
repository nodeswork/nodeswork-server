import * as mongoose           from 'mongoose';
import * as sbase              from '@nodeswork/sbase';

import { generateToken }       from '../../../utils/tokens';
import { deviceSocketManager } from '../../sockets';
import { Applet, AppletImage } from '../applets/applets';

export const DEVICE_DATA_LEVELS = {
  DETAIL: 'DETAIL',
  TOKEN:  'TOKEN',
};

export type DeviceTypeT = typeof Device & sbase.mongoose.NModelType;
export interface DeviceType extends DeviceTypeT {}

export class AppletStatus extends AppletImage {

  public static $SCHEMA: object = {

    port:         {
      type:       Number,
      required:   true,
    },

    status:       {
      type:       String,
      required:   true,
    },
  };
}

export class Device extends sbase.mongoose.NModel {

  public DATA_LEVELS = DEVICE_DATA_LEVELS;

  public static $CONFIG: mongoose.SchemaOptions = {
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
  };

  public static $SCHEMA: object = {

    token:             {
      type:            String,
      required:        true,
      index:           true,
      unique:          true,
      default:         generateToken,
      api:             sbase.mongoose.AUTOGEN,
      level:           DEVICE_DATA_LEVELS.TOKEN,
    },

    os:                {
      type:            String,
      enum:            [ 'MacOS', 'Linux', 'Windows' ],
      required:        true,
      level:           DEVICE_DATA_LEVELS.DETAIL,
    },

    osVersion:         {
      type:            String,
      required:        true,
      level:           DEVICE_DATA_LEVELS.DETAIL,
    },

    containerVersion:  {
      type:            String,
      required:        true,
      level:           DEVICE_DATA_LEVELS.DETAIL,
    },

    runningApplets:    {
      type:            [ AppletStatus.$mongooseOptions().mongooseSchema ],
      level:           DEVICE_DATA_LEVELS.DETAIL,
      api:             sbase.mongoose.AUTOGEN,
      default:         [],
    },

    installedApplets:  {
      type:            [ Applet.$mongooseOptions().mongooseSchema ],
      level:           DEVICE_DATA_LEVELS.DETAIL,
      api:             sbase.mongoose.AUTOGEN,
      default:         [],
    },

    scheduledApplets:  {
      type:            [ Applet.$mongooseOptions().mongooseSchema ],
      level:           DEVICE_DATA_LEVELS.DETAIL,
      api:             sbase.mongoose.AUTOGEN,
      default:         [],
    },
  };

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
