import * as mongoose      from 'mongoose';
import * as _             from 'underscore';

import * as sbase         from '@nodeswork/sbase';
import { NodesworkError } from '@nodeswork/utils';

import {
  Account,
  AccountType,
}                         from './accounts';

export type CookieAccountType = typeof CookieAccount & AccountType;

@sbase.mongoose.Config({})
export class CookieAccount extends Account {

  @sbase.mongoose.Field({
    type:      String,
    api:       sbase.mongoose.AUTOGEN,
  })
  public cookieString: string;
}
