import * as _ from 'underscore'
import * as mongoose from 'mongoose'
import * as sbase from '@nodeswork/sbase'

export const DETAIL      = 'DETAIL';
export const CREDENTIAL  = 'CREDENTIAL';
export const USER_STATUS = {
  ACTIVE:      'ACTIVE',
  INACTIVE:    'INACTIVE',
  UNVERIFIED:  'UNVERIFIED',
}

export type UserType = typeof User & sbase.mongoose.NModelType

export class User extends sbase.mongoose.NModel {

  static $CONFIG: sbase.mongoose.ModelConfig = {
    collection:        'users',
    discriminatorKey:  'userType',
    // levels:            [],
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

  @sbase.koa.bind('POST')
  static async forgotPassword(
    @sbase.koa.params('request.body.email') email: string
  ) {
  }

  @sbase.koa.bind('POST')
  async sendVerifyEmail(): Promise<void> {
  }

  @sbase.koa.bind('GET')
  async verifyUserEmail(
    @sbase.koa.params('request.query.token') token: string
  ): Promise<void> {
  }
}
