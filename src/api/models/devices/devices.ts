import * as mongoose     from 'mongoose';
import * as sbase        from '@nodeswork/sbase';

import { generateToken } from "../../../utils/tokens";

export const DETAIL = 'DETAIL';
export const TOKEN  = 'TOKEN';

export type DeviceTypeT = typeof Device & sbase.mongoose.NModelType;
export interface DeviceType extends DeviceTypeT {}

export class Device extends sbase.mongoose.NModel {

  public static $CONFIG: mongoose.SchemaOptions = {
    collection:        'devices',
    discriminatorKey:  'deviceType',
    dataLevel:         {
      levels:          [ DETAIL, TOKEN ],
      default:         DETAIL,
    },
  };

  public static $SCHEMA: object = {

    token:             {
      type:            String,
      required:        true,
      index:           true,
      unique:          true,
      default:         generateToken,
      api:             sbase.mongoose.AUTOGEN,
    },

    os:                {
      type:            String,
      enum:            [ 'MacOS', 'Linux', 'Windows' ],
      required:        true,
    },

    osVersion:         {
      type:            String,
      required:        true,
    },

    containerVersion:  {
      type:            String,
      required:        true,
    },
  };
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
      dataLevel:       DETAIL,
      api:             sbase.mongoose.READONLY,
    },

    name:              {
      type:            String,
      default:         'My Device',
    },

    dev:               {
      type:            Boolean,
      default:         false,
      dataLevel:       DETAIL,
      api:             sbase.mongoose.AUTOGEN,
    },
  };
}
