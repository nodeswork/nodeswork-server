import * as _                  from 'underscore';
import * as mongoose           from 'mongoose';

import * as sbase              from '@nodeswork/sbase';
import * as logger             from '@nodeswork/logger';

import * as models             from '../../models';
import { deviceSocketManager } from '../../sockets';
import { AppletConfig }        from './applets';
import * as errors             from '../../errors';

const LOG = logger.getLogger();

export const USER_APPLET_DATA_LEVELS = {
  DETAIL:  'DETAIL',
};

export type UserAppletTypeT = typeof UserApplet & sbase.mongoose.NModelType;
export interface UserAppletType extends UserAppletTypeT {}

export type ObjectId = mongoose.Types.ObjectId;

const UserAppletDeviceConfig = new mongoose.Schema({
  // TODO: Verify device ownership before saving.
  device:      {
    type:      mongoose.Schema.Types.ObjectId,
    ref:       'Device',
    required:  true,
  },
}, { _id: false });

const UserAppletAccountConfig = new mongoose.Schema({
  // TODO: Verify account ownership before saving.
  account:      {
    type:      mongoose.Schema.Types.ObjectId,
    ref:       'Account',
    required:  true,
  },
}, { _id: false });

const UserAppletConfig = new mongoose.Schema({
  appletConfig:  {
    type:        mongoose.Schema.Types.ObjectId,
    required:    true,
  },
  devices:       [ UserAppletDeviceConfig ],
  accounts:      [ UserAppletAccountConfig ],
}, { _id: false });

@sbase.mongoose.Config({
  collection:        'users.applets',
  dataLevel:         {
    levels:          [ USER_APPLET_DATA_LEVELS.DETAIL ],
    default:         USER_APPLET_DATA_LEVELS.DETAIL,
  },
  toObject:          {
    virtuals:        true,
  },
  id: false,
})
export class UserApplet extends sbase.mongoose.NModel {

  @sbase.mongoose.Field({
    type:           mongoose.Schema.Types.ObjectId,
    ref:            'User',
    required:       true,
    index:          true,
    api:            sbase.mongoose.READONLY,
  })
  public user:      mongoose.Schema.Types.ObjectId;

  @sbase.mongoose.Field({
    type:           mongoose.Schema.Types.ObjectId,
    ref:            'Applet',
    required:       true,
    api:            sbase.mongoose.READONLY,
  })
  public applet:    mongoose.Schema.Types.ObjectId | models.Applet;

  @sbase.mongoose.Field({
    type:           UserAppletConfig,
    required:       true,
  })
  public config:    UserAppletConfig;

  @sbase.mongoose.Field({
    type:           Boolean,
    default:        false,
  })
  public enabled:   boolean;

  @sbase.mongoose.Field({
    type: String,
  })
  public disableReason:    string;

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

    const device = rpcClient.socket.device;

    const installedApplet = _.find(device.installedApplets, (p) => {
      return (p.naType === config.naType && p.naVersion === config.naVersion &&
        p.packageName === config.packageName && p.version === config.version);
    });

    if (installedApplet == null) {
      return USER_APPLET_STATS_APPLET_NOT_INSTALLED;
    }

    const runningApplet = _.find(device.runningApplets, (p) => {
      return (p.naType === config.naType && p.naVersion === config.naVersion &&
        p.packageName === config.packageName && p.version === config.version);
    });

    if (runningApplet == null) {
      return USER_APPLET_STATS_APPLET_NOT_RUNNING;
    }

    return {
      online: true,
      status: runningApplet.status,
    };
  }

  public async work(worker: { name: string; action: string; }) {
    const appletConfig = await this.populateAppletConfig();
    const workerConfig = _.find(appletConfig.workers, (wc) => {
      return wc.name === `${worker.name}.${worker.action}`;
    });

    if (workerConfig == null) {
      throw errors.INVALID_WORKER;
    }

    const accounts = _.map(this.config.accounts, (account) => {
      return account.account;
    });

    const payload = {
      accounts,
    };

    const rpcClient = deviceSocketManager.getNAMSocketRpcClient(
      this.config.devices[0].device.toString(),
    );

    if (rpcClient == null) {
      throw errors.DEVICE_OFFLINE;
    }

    const appletImage = _.pick(
      appletConfig, 'packageName', 'version', 'naType', 'naVersion',
    );

    LOG.debug('Call rptClient to work', JSON.parse(JSON.stringify({
      appletImage,
      worker,
      payload,
    })));

    return await rpcClient.work(appletImage, worker, payload);
  }

  /**
   * Validate current configuration in case of
   *
   *   1. not reach the applet requirements.
   *   2. account is unavailable.
   */
  public async validateConfiguration(
    accounts: models.Account[], devices: models.Device[],
  ): Promise<UserApplet> {
    let changed = false;

    // Step 1, filter deleted accounts.
    if (this.filterDeletedAccounts(accounts)) { changed = true; }

    // Step 2, filter unanbled devices.
    if (this.filterUnenabledDevices(devices)) { changed = true; }

    if (this.config.devices.length === 0) {
      this.enabled        = false;
      this.disableReason  = 'Device is not specified';
    }

    if (this.enabled) {
      const currentAccounts = _.filter(accounts, (account) => {
        return _.find(
          this.config.accounts,
          (a) => a.account.toString() === account._id.toString(),
        ) != null;
      });
      const appletConfig = await this.populateAppletConfig();
      for (const appletAccount of appletConfig.accounts) {
        if (appletAccount.optional) {
          continue;
        }

        const filteredAccounts = _.filter(currentAccounts, (a) => {
          return a.accountType === appletAccount.accountType &&
            a.provider === appletAccount.provider;
        });
        if (filteredAccounts.length === 0) {
          this.enabled = false;
          this.disableReason = `Required ${appletAccount.accountType} ` +
            `provided by ${appletAccount.provider} is missing`;
          break;
        }
        if (filteredAccounts.length > 1 && !appletAccount.multiple) {
          this.enabled = false;
          this.disableReason = `Applet only accepts one ` +
            `${appletAccount.accountType} provided ` +
            `by ${appletAccount.provider}`;
          break;
        }
      }
    }

    if (this.enabled) {
      this.disableReason = null;
    }

    if (changed || this.isModified()) {
      await this.save();
    }

    return this;
  }

  private filterUnenabledDevices(devices: models.Device[]): boolean {
    const enabledDevices = _.filter(
      this.config.devices, (device) => {
        const target = _.find(
          devices,
          (d) => d._id.toString() === device.device.toString(),
        );
        return target != null;
      },
    );
    if (enabledDevices.length !== this.config.devices.length) {
      this.config.devices = enabledDevices;
      return true;
    }
    return false;
  }

  private filterDeletedAccounts(accounts: models.Account[]): boolean {
    const enabledAccounts = _.filter(
      this.config.accounts, (account) => {
        const target = _.find(
          accounts,
          (d) => d._id.toString() === account.account.toString(),
        );
        return target != null;
      },
    );
    if (enabledAccounts.length !== this.config.accounts.length) {
      this.config.accounts = enabledAccounts;
      return true;
    }
    return false;
  }

  /**
   * Validate all user's enabled applets.
   *
   * @param user    specifies the owner of enabled applets.
   * @param devices in most use cases, user's devices should be already
   *                retrieved.
   * @return user's enabled applets.
   */
  public static async validateUserApplets(
    user: mongoose.Types.ObjectId,
    accounts: models.Account[],
    devices: models.Device[],
  ): Promise<UserApplet[]> {
    const userApplets = await models.UserApplet.find(
      { user, enabled: true },
      undefined,
      {
        populate: [
          {
            path: 'applet',
            options: {
              level: models.Applet.DATA_LEVELS.TOKEN,
            },
          },
        ],
      },
    );
    for (const userApplet of userApplets) {
      await userApplet.validateConfiguration(accounts, devices);
    }
    return _.filter(userApplets, (x) => x.enabled);
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

const USER_APPLET_STATS_APPLET_NOT_INSTALLED = {
  online: false,
  reason: 'applet is not installed on device',
};

const USER_APPLET_STATS_APPLET_NOT_RUNNING = {
  online: false,
  reason: 'applet is not running on device',
};

export interface UserAppletConfig {
  appletConfig:  mongoose.Schema.Types.ObjectId | AppletConfig;
  devices:       UserAppletDeviceConfig[];
  accounts:      UserAppletAccountConfig[];
}

export interface UserAppletDeviceConfig {
  device: mongoose.Types.ObjectId;
}

export interface UserAppletAccountConfig {
  account: mongoose.Types.ObjectId;
}
