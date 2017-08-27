import * as _ from 'underscore'
import * as bcrypt from 'bcrypt'
import * as mongoose from 'mongoose'

import * as sbase from '@nodeswork/sbase'
import { NodesworkError } from '@nodeswork/utils'

import { config } from '../../../config'
import { Token } from '../models'
import { sendMail } from '../../../mail/mailer'

import 'mongoose-type-email'

export const DETAIL      = 'DETAIL';
export const CREDENTIAL  = 'CREDENTIAL';
export const USER_STATUS = {
  ACTIVE:      'ACTIVE',
  INACTIVE:    'INACTIVE',
  UNVERIFIED:  'UNVERIFIED',
}

const VERIFY_EMAIL_TOKEN_PURPOSE = 'verifyEmail'
const VERIFY_EMAIL_TEMPLATE = 'email-verification'

export type UserTypeT = typeof User & sbase.mongoose.NModelType
export interface UserType extends UserTypeT {}

export class User extends sbase.mongoose.NModel {

  static $CONFIG: sbase.mongoose.ModelConfig = {
    collection:        'users',
    discriminatorKey:  'userType',
    levels:            [ DETAIL, CREDENTIAL ],
  }

  static $SCHEMA = {

    email:       {
      type:      (mongoose.SchemaTypes as any).Email,
      required:  true,
      unique:    true,
      trim:      true,
      api:       sbase.mongoose.READONLY,
      level:     DETAIL,
    },

    password:    {
      type:      String,
      required:  true,
      min:       [6,  'Password should be at least 6 charactors.'],
      max:       [80, 'Password should be at most 80 charactors.'],
      level:     CREDENTIAL,
    },

    status:      {
      type:      String,
      enum:      _.values(USER_STATUS),
      default:   USER_STATUS.UNVERIFIED,
      api:       sbase.mongoose.AUTOGEN,
    },
  }

  email:     string
  password:  string
  status:    string

  @sbase.koa.bind('POST')
  static async forgotPassword(
    @sbase.koa.params('request.body.email') email: string
  ) {
  }

  @sbase.koa.bind('POST')
  async sendVerifyEmail(): Promise<void> {
    let token = await Token.createToken(
      VERIFY_EMAIL_TOKEN_PURPOSE, this, { maxRedeemTimes: 1 }
    );
    await sendMail(VERIFY_EMAIL_TEMPLATE, this.email, {
      userId:  this._id,
      host:    config.app.publicHost,
      token:   token.token,
    })
  }

  @sbase.koa.bind('GET')
  async verifyUserEmail(
    @sbase.koa.params('request.query.token') token: string
  ): Promise<void> {
    let tokenDoc = await Token.redeemToken(token, {
      populate: { withUnActive: true }
    });
    if (tokenDoc == null || tokenDoc.purpose !== VERIFY_EMAIL_TOKEN_PURPOSE) {
      throw new NodesworkError('Unrecognized token', { responseCode: 422 });
    }

    let user: User = await tokenDoc.payload.data as User;
    user.status = USER_STATUS.ACTIVE;
    await user.save();
  }

  async _hashPasswordPreSave(next: Function) {
    if (!this.isModified('password')) {
      return next();
    }
    let salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next()
  }
}

User.Pre({
  name:  'save',
  fn:    User.prototype._hashPasswordPreSave,
});

for (let name of sbase.mongoose.preQueries) {
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
