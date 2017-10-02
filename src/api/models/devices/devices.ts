import * as _                  from 'underscore';
import * as mongoose           from 'mongoose';
import * as sbase              from '@nodeswork/sbase';

import * as logger             from '@nodeswork/logger';

import { generateToken }       from '../../../utils/tokens';
import { deviceSocketManager } from '../../sockets';
import { Applet, AppletImage } from '../applets/applets';
import * as models             from '../../models';

const LOG = logger.getLogger();

export const DEVICE_DATA_LEVELS = {
  DETAIL: 'DETAIL',
  TOKEN:  'TOKEN',
};

export type DeviceType = typeof Device & sbase.mongoose.NModelType;

export class AppletStatus extends AppletImage {

  @sbase.mongoose.Field({
    type:  mongoose.Schema.Types.ObjectId,
    ref:   'Applet',
  })
  public appletId: string;

  @sbase.mongoose.Field({
    type:       String,
    required:   true,
  })
  public ip:    string;

  @sbase.mongoose.Field({
    type:       Number,
    required:   true,
  })
  public port:  number;

  @sbase.mongoose.Field({
    type:       String,
    required:   true,
  })
  public status: string;
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
    await this.checkAppletRunningStatus(userApplets);
  }

  public async checkAppletRunningStatus(
    userApplets: models.UserApplet[],
  ): Promise<void> {

    const deviceSocketRpc = deviceSocketManager.getNAMSocketRpcClient(
      this._id.toString(),
    );
    if (deviceSocketRpc == null) {
      return;
    }

    LOG.info('Check online device environment', {
      device: JSON.parse(JSON.stringify(this.toObject())),
    });

    for (const runningApplet of this.runningApplets) {
      const scheduledApplet = _.find(this.scheduledApplets, (sa) => {
        return sa.packageName === runningApplet.packageName &&
          sa.version === runningApplet.version;
      });

      if (scheduledApplet == null) {
        try {
          await deviceSocketRpc.kill(runningApplet);
          LOG.info('Stop running applet successfully', {
            device: this._id.toString(),
            applet: JSON.parse(JSON.stringify(runningApplet.toJSON())),
          });
        } catch (e) {
          LOG.error('Stop running applet failed', {
            device: this._id.toString(),
            applet: JSON.parse(JSON.stringify(runningApplet.toJSON())),
            error: e,
          });
          throw e;
        }
      }
    }

    const appletsInfo = [];

    for (const userApplet of userApplets) {
      const appletConfig = await userApplet.populateAppletConfig();
      appletsInfo.push({
        userApplet,
        appletConfig,
      });
    }

    for (const scheduledApplet of this.scheduledApplets) {
      const runningApplet = _.find(this.runningApplets, (ra) => {
        return ra.packageName === scheduledApplet.packageName &&
          ra.version === scheduledApplet.version;
      });

      if (runningApplet != null) {
        continue;
      }

      const appletInfo = _.find(appletsInfo, (info) => {
        return info.appletConfig.packageName === scheduledApplet.packageName &&
          info.appletConfig.version === scheduledApplet.version;
      });

      if (appletInfo == null) {
        continue;
      }

      if (runningApplet == null) {
        try {
          await deviceSocketRpc.install(scheduledApplet);
          LOG.info('Install applet successfully', {
            device: this._id.toString(),
            applet: JSON.parse(JSON.stringify(scheduledApplet.toJSON())),
          });
          const applet = appletInfo.userApplet.applet as models.Applet;
          const runOptions = {
            packageName:  scheduledApplet.packageName,
            version:      scheduledApplet.version,
            naType:       scheduledApplet.naType,
            naVersion:    scheduledApplet.naVersion,
            appletId:     applet._id.toString(),
            appletToken:  applet.tokens.prodToken,
          };
          await deviceSocketRpc.run(runOptions);
          LOG.info('Run applet successfully', {
            device: this._id.toString(),
            applet: JSON.parse(JSON.stringify(scheduledApplet.toJSON())),
          });
        } catch (e) {
          LOG.error('Run applet failed', {
            device: this._id.toString(),
            applet: JSON.parse(JSON.stringify(scheduledApplet.toJSON())),
            error: e,
          });
          throw e;
        }
      }
    }
  }

  get online(): boolean {
    return deviceSocketManager.isDeviceOnline(this._id.toString());
  }
}

export type UserDeviceType = typeof UserDevice & DeviceType;

export class UserDevice extends Device {

  @sbase.mongoose.Field({
    type:            mongoose.Schema.Types.ObjectId,
    ref:             'User',
    required:        true,
    index:           true,
    api:             sbase.mongoose.READONLY,
  })
  public user: models.User;

  @sbase.mongoose.Field({
    type:            String,
    required:        true,
    level:           DEVICE_DATA_LEVELS.DETAIL,
    api:             sbase.mongoose.READONLY,
  })
  public deviceIdentifier: string;

  @sbase.mongoose.Field({
    type:            String,
    default:         'My Device',
  })
  public name: string;

  @sbase.mongoose.Field({
    type:            Boolean,
    default:         false,
    level:           DEVICE_DATA_LEVELS.DETAIL,
    api:             sbase.mongoose.AUTOGEN,
  })
  public dev: boolean;
}
