import * as moment from "moment";
import * as mongoose from "mongoose";

import * as sbase from "@nodeswork/sbase";

import { MAX_DATE } from "../../utils/time";
import { generateToken } from "../../utils/tokens";

export type TokenType = typeof Token & sbase.mongoose.NModelType;

export class Token extends sbase.mongoose.NModel {

  public static $CONFIG: mongoose.SchemaOptions = {
    collection:        "tokens",
    discriminatorKey:  "kind",
  };

  public static $SCHEMA = {

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
        refPath:      "payload.kind",
      },
    },

    expireAt:         {
      type:           Date,
      required:       true,
    },
  };

  public purpose:         string;
  public token:           string;
  public maxRedeemTimes:  number;
  public payload:         null | { kind:  string, data:  sbase.mongoose.NModel };
  public expireAt:        Date;

  public static async createToken(
    purpose: string,
    payload: sbase.mongoose.NModel,
    {
      expireInMs = 0,
      maxRedeemTimes = -1,
      tokenSize = 16,
    }: TokenOptions = {},
  ): Promise<Token> {
    const self = this.cast<Token>();
    const expireAt = !expireInMs ? MAX_DATE : moment().add(expireInMs, "ms");
    const kind: string = payload && (payload.constructor as any).modelName;

    const doc = {
      purpose,
      maxRedeemTimes,
      payload:         payload == null ? null : {
        kind,
        data:          payload._id,
      },
      expireAt,
      token:           generateToken(tokenSize),
    };
    return self.create(doc);
  }

  public static async redeemToken(
    token: string,
    { populate }: { populate?: object } = {},
  ): Promise<Token> {
    const self = this.cast<Token>();
    const query = {
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
      .populate({
        path: "payload.data",
        options: populate,
      });
  }

  get redeemTimesLeft(): number {
    return this.maxRedeemTimes < 0 ?
      Number.MAX_SAFE_INTEGER : this.maxRedeemTimes;
  }
}

export interface TokenOptions {
  expireInMs?:      number;   // 0 means no expiration
  maxRedeemTimes?:  number;   // -1 means no limitation
  tokenSize?:       number;
}
