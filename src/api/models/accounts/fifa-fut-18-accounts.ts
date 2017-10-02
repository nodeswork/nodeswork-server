import * as mongoose      from 'mongoose';
import * as _             from 'underscore';

import * as sbase         from '@nodeswork/sbase';
import { NodesworkError } from '@nodeswork/utils';

import {
  CookieAccount,
  CookieAccountType,
}                         from './cookie-accounts';

export type FifaFut18AccountType = typeof FifaFut18Account & CookieAccountType;

@sbase.mongoose.Config({})
export class FifaFut18Account extends CookieAccount {

  @sbase.mongoose.Field({
    type:      String,
    api:       sbase.mongoose.READONLY,
  })
  public email: string;
}
