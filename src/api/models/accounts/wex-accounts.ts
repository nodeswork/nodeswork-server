import * as mongoose      from 'mongoose';
import * as _             from 'underscore';

import * as sbase         from '@nodeswork/sbase';
import { NodesworkError } from '@nodeswork/utils';

import {
  Account,
  AccountType,
  AccountOperateOptions,
}                         from './accounts';

export type WEXAccountType = typeof WEXAccount & AccountType;

@sbase.mongoose.Config({})
export class WEXAccount extends Account {

  @sbase.mongoose.Field({
    type:      String,
    level:     Account.DATA_LEVELS.CREDENTIAL,
    required:  true,
  })
  public key: string;

  @sbase.mongoose.Field({
    type:      String,
    level:     Account.DATA_LEVELS.CREDENTIAL,
    required:  true,
  })
  public secret: string;

  @sbase.mongoose.Field({
    type:      Number,
    level:     Account.DATA_LEVELS.DETAIL,
    default:   0,
  })
  public nonce: number;

  public verify() {
    return { status: 'ok' };
  }
}
