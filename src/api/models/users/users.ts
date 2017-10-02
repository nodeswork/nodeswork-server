import * as bcrypt        from 'bcrypt';
import * as mongoose      from 'mongoose';
import * as _             from 'underscore';

import * as sbase         from '@nodeswork/sbase';
import { NodesworkError } from '@nodeswork/utils';

import { config }         from '../../../config';
import { sendMail }       from '../../../mail/mailer';
import * as errors        from '../../errors';
import { Token }          from '../';
import * as models        from '..';

import 'mongoose-type-email';

const VERIFY_EMAIL_TOKEN_PURPOSE = 'verifyEmail';
const VERIFY_EMAIL_TEMPLATE = 'email-verification';
const EMAIL_EXPIRATION_TIME_IN_MS = 10 * 60 * 1000;

export type UserType = typeof User & sbase.mongoose.NModelType;

const DATA_LEVELS = {
  DETAIL:      'DETAIL',
  CREDENTIAL:  'CREDENTIAL',
};

const USER_STATUS = {
  ACTIVE:      'ACTIVE',
  INACTIVE:    'INACTIVE',
  UNVERIFIED:  'UNVERIFIED',
};

@sbase.mongoose.Config({
  collection:        'users',
  discriminatorKey:  'userType',
  dataLevel:         {
    levels:          [ DATA_LEVELS.DETAIL, DATA_LEVELS.CREDENTIAL ],
    default:         DATA_LEVELS.DETAIL,
  },
})
export class User extends sbase.mongoose.NModel {

  public static DATA_LEVELS = DATA_LEVELS;
  public static USER_STATUS = USER_STATUS;

  @sbase.mongoose.Field({
    type:      (mongoose.SchemaTypes as any).Email,
    required:  true,
    unique:    true,
    trim:      true,
    api:       sbase.mongoose.READONLY,
    level:     DATA_LEVELS.DETAIL,
  })
  public email:     string;

  @sbase.mongoose.Field({
    type:      String,
    required:  true,
    min:       [6,  'Password should be at least 6 charactors.'],
    max:       [80, 'Password should be at most 80 charactors.'],
    level:     DATA_LEVELS.CREDENTIAL,
  })
  public password:  string;

  @sbase.mongoose.Field({
    type:      String,
    enum:      _.values(USER_STATUS),
    default:   USER_STATUS.UNVERIFIED,
    api:       sbase.mongoose.AUTOGEN,
  })
  public status:    string;

  /**
   * Check if user's applets and devices are up-to-date.
   *
   *   1. For user installed applets, validate current configuration and
   *      fail reasons.
   *   2. For user's devices, calculate scheduledApplets. Install and run user's
   *      applets if necessary.
   */
  public async checkAppletsAndDevices() {
    const accounts = await models.Account.find({ user: this._id });
    const devices = await models.UserDevice.find({ user: this._id });
    const enabledUserApplets = await models.UserApplet.validateUserApplets(
      this._id, accounts, devices,
    );

    const grouped = _.groupBy(enabledUserApplets, (ua) => {
      return ua.config.devices[0].device.toString();
    });

    for (const deviceId of Object.keys(grouped)) {
      const userApplets = grouped[deviceId];
      const device = _.find(devices, (d) => d._id.toString() === deviceId);
      await device.updateScheduledApplets(userApplets);
    }
  }

  @sbase.koa.bind('POST')
  public static async forgotPassword(
    @sbase.koa.params('request.body.email') email: string,
  ) {
    // TODO
  }

  /**
   * Send verification email for current user to verify the email address.
   */
  @sbase.koa.bind('POST')
  public async sendVerifyEmail(): Promise<{ token: string }> {
    if (this.status !== USER_STATUS.UNVERIFIED) {
      throw errors.EMAIL_ADDRESS_IS_ALREADY_VERIFIED;
    }

    const token = await Token.createToken(
      VERIFY_EMAIL_TOKEN_PURPOSE, this, {
        maxRedeemTimes: 1,
        expireInMs: EMAIL_EXPIRATION_TIME_IN_MS,
      },
    );
    await sendMail(VERIFY_EMAIL_TEMPLATE, this.email, {
      host:    config.app.publicHost,
      token:   token.token,
    });
    return { token: token.token };
  }

  @sbase.koa.bind('GET')
  public static async verifyUserEmail(
    @sbase.koa.params('request.body.token') token: string,
  ): Promise<void> {
    const tokenDoc = await Token.redeemToken(token, {
      populate: { withUnActive: true },
    });
    if (tokenDoc == null || tokenDoc.purpose !== VERIFY_EMAIL_TOKEN_PURPOSE) {
      throw errors.UNRECOGNIZED_TOKEN_ERROR;
    }

    const user: User = await tokenDoc.payload.data as User;
    user.status = USER_STATUS.ACTIVE;
    await user.save();
  }

  public static async verifyEmailPassword(email: string, password: string)
    : Promise<User> {
      const self = this.cast<User>();
      const user = await self.findOne({ email }, null, {
        withUnActive:  true,
        level:         DATA_LEVELS.CREDENTIAL,
      });
      if (user == null) {
        throw errors.USER_NOT_EXISTS_ERROR;
      }
      if (!await bcrypt.compare(password, user.password)) {
        throw errors.INVALID_PASSWORD_ERROR;
      }
      return user;
  }

  public async _hashPasswordPreSave(next: (err?: any) => void) {
    if (!this.isModified('password')) {
      return next();
    }
    if (this.password.length < 6) {
      return next(errors.PASSWORD_TOO_SHORT_ERROR);
    }
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  }
}

User.Pre({
  name:  'save',
  fn:    User.prototype._hashPasswordPreSave,
});

for (const name of sbase.mongoose.preQueries) {
  User.Pre({ name, fn: patchStatus });
}

function patchStatus() {
  if (this._conditions == null) {
    this._conditions = {};
  }

  if (this._conditions.status === undefined && !this.options.withUnActive) {
    this._conditions.status = USER_STATUS.ACTIVE;
  }
}
