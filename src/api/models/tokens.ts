import * as moment from 'moment'
import * as mongoose from 'mongoose'
import * as sbase from '@nodeswork/sbase'

import { generateToken } from '../../utils/tokens'
import { MAX_DATE } from '../../utils/time'

export interface TokenType extends TokenTypeT {}
export type TokenTypeT = typeof Token & sbase.mongoose.NModelType

export class Token extends sbase.mongoose.NModel {

  static $CONFIG: sbase.mongoose.ModelConfig = {
    collection:        'tokens',
    discriminatorKey:  'kind',
  }

  static $SCHEMA = {

    token:            {
      type:           String,
      index:          true,
      required:       true,
      default:        generateToken,
    },

    maxRedeemTimes:  {
      type:           Number,
      default:        0,
    },

    purpose:          {
      type:           String,
      maxlength:      30,
    },

    payload:          {
      kind:           String,
      data:           {
        type:         mongoose.Schema.Types.ObjectId,
        refPath:      'payload.kind',
      }
    },

    expireAt:         {
      type:           Date,
      required:       true,
    },
  }

  purpose:         string
  token:           string
  maxRedeemTimes:  number
  payload:         null | { kind:  string, data:  sbase.mongoose.NModel }
  expireAt:        Date

  static async createToken(
    purpose: string,
    payload: sbase.mongoose.NModel,
    {
      expireInMs = 0,
      maxRedeemTimes = -1,
      tokenSize = 16,
    }: TokenOptions = {}
  ): Promise<Token> {
    let self = this.cast<Token>();
    let expireAt = !expireInMs ? MAX_DATE : moment().add(expireInMs, 'ms');
    let kind: string = (payload.constructor as any).modelName;

    let doc = {
      purpose,
      maxRedeemTimes,
      payload:         payload == null ? null :   {
        kind:          kind,
        data:          payload._id,
      },
      expireAt,
      token:           generateToken(tokenSize),
    };
    return self.create(doc);
  }

  static async redeemToken(token: string): Promise<Token> {
    let self = this.cast<Token>();
    let query = {
      token,
      maxRedeemTimes: {
        $ne: 0,
      },
      expireAt: {
        $gt: Date.now(),
      },
    };
    return self
      .findOneAndUpdate(query, {
        $inc: { maxRedeemTimes: -1 },
      }, { new: true })
      .populate('payload.data');
  }

  get redeemTimesLeft(): number {
    return this.maxRedeemTimes < 0 ?
      Number.MAX_SAFE_INTEGER : this.maxRedeemTimes;
  }
}

export interface TokenOptions {
  expireInMs?:      number   // 0 means no expiration
  maxRedeemTimes?:  number   // -1 means no limitation
  tokenSize?:       number
}
