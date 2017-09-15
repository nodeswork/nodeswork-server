import * as _                  from 'underscore';
import * as mongoose           from 'mongoose';
import * as sbase              from '@nodeswork/sbase';

import * as models             from '../../models';
import { deviceSocketManager } from '../../sockets';
import { AppletConfig }        from './applets';

export const USER_APPLET_DATA_LEVELS = {
  DETAIL:  'DETAIL',
};

export type UserAppletTypeT = typeof UserApplet & sbase.mongoose.NModelType;
export interface UserAppletType extends UserAppletTypeT {}

const UserAppletDeviceConfig = new mongoose.Schema({
  // TODO: Verify device ownership before saving.
  device:      {
    type:      mongoose.Schema.Types.ObjectId,
    ref:       'Device',
    required:  true,
  },
}, { _id: false });

const UserAppletConfig = new mongoose.Schema({
  appletConfig:  {
    type:        mongoose.Schema.Types.ObjectId,
    required:    true,
  },
  devices:       [ UserAppletDeviceConfig ],
}, { _id: false });

export class UserApplet extends sbase.mongoose.NModel {

  public static $CONFIG: mongoose.SchemaOptions = {
    collection:        'users.applets',
    dataLevel:         {
      levels:          [ USER_APPLET_DATA_LEVELS.DETAIL ],
      default:         USER_APPLET_DATA_LEVELS.DETAIL,
    },
    toObject:          {
      virtuals:        true,
    },
    id: false,
  };

  public user:             mongoose.Schema.Types.ObjectId;
  public applet:           mongoose.Schema.Types.ObjectId | models.Applet;
  public config:           UserAppletConfig;
  public enabled:          boolean;

  public static $SCHEMA: object = {

    user:             {
      type:           mongoose.Schema.Types.ObjectId,
      ref:            'User',
      required:       true,
      index:          true,
      api:            sbase.mongoose.READONLY,
    },

    applet:           {
      type:           mongoose.Schema.Types.ObjectId,
      ref:            'Applet',
      required:       true,
      api:            sbase.mongoose.READONLY,
    },

    config:           {
      type:           UserAppletConfig,
      required:       true,
    },

    enabled:          {
      type:           Boolean,
      default:        false,
    },
  };

  public async populateAppletConfig(): Promise<AppletConfig> {
    let applet: models.Applet;
    if (this.populated('applet') == null) {
      applet = await models.Applet.findById(this.applet, {
        configHistories: 1,
      });
    } else {
      applet = this.applet as models.Applet;
    }

    if (applet == null) {
      return null;
    }

    const target = _.find(
      applet.configHistories,
      (v) => v._id.toString() === this.config.appletConfig.toString(),
    );

    return target;
  }

  public async stats(): Promise<UserAppletStats> {
    if (!this.enabled) {
      return USER_APPLET_STATS_APPLET_NOT_ENABLED;
    }
    if (this.config.devices.length === 0) {
      return USER_APPLET_STATS_NO_DEVICES;
    }

    const rpcClient = deviceSocketManager.getNAMSocketRpcClient(
      this.config.devices[0].device.toString(),
    );

    if (rpcClient == null) {
      return USER_APPLET_STATS_DEVICE_IS_NOT_CONNECTED;
    }

    const config = await this.populateAppletConfig();

    if (config == null) {
      return USER_APPLET_STATS_CONFIG_OUT_OF_DATE;
    }

    const ps = rpcClient.psInCache();

    if (ps == null) {
      return USER_APPLET_STATS_NO_STATS_UPDATES;
    }

    const appletPs = _.find(ps, (p) => {
      return (p.naType === config.naType && p.naVersion === config.naVersion &&
        p.appletPackage === config.packageName && p.version === config.version);
    });

    if (appletPs == null) {
      return USER_APPLET_STATS_APPLET_NOT_RUNNING;
    }

    return {
      online: true,
      status: appletPs.status,
    };
  }
}

export interface UserAppletStats {
  online:   boolean;
  reason?:  string;
  status?:  string;
}

const USER_APPLET_STATS_APPLET_NOT_ENABLED = {
  online: false,
  reason: 'applet is not enabled',
};

const USER_APPLET_STATS_NO_DEVICES = {
  online: false,
  reason: 'device is not selected',
};

const USER_APPLET_STATS_CONFIG_OUT_OF_DATE = {
  online: false,
  reason: 'user applet config is out of date',
};

const USER_APPLET_STATS_DEVICE_IS_NOT_CONNECTED = {
  online: false,
  reason: 'device is not connected',
};

const USER_APPLET_STATS_NO_STATS_UPDATES = {
  online: false,
  reason: 'no stats update from device yet',
};

const USER_APPLET_STATS_APPLET_NOT_RUNNING = {
  online: false,
  reason: 'applet is not running on device',
};

export interface UserAppletConfig {
  appletConfig:  mongoose.Schema.Types.ObjectId | AppletConfig;
  devices:       UserAppletDeviceConfig[];
}

export interface UserAppletDeviceConfig {
  device: models.Device;
}
