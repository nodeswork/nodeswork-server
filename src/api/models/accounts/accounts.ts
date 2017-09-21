import * as mongoose                           from 'mongoose';
import * as _                                  from 'underscore';

import * as sbase                              from '@nodeswork/sbase';
import { NodesworkError }                      from '@nodeswork/utils';

import { AccountCategory, ACCOUNT_CATEGORIES } from './account-categories';

const DATA_LEVELS = {
  DETAIL:      'DETAIL',
  TOKEN:       'TOKEN',
  CREDENTIAL:  'CREDENTIAL',
};

export type AccountTypeT = typeof Account & sbase.mongoose.NModelType;
export interface AccountType extends AccountTypeT {}

@sbase.mongoose.Config({
  collection:        'accounts',
  discriminatorKey:  'accountType',
  dataLevel:         {
    levels:          [ DATA_LEVELS.DETAIL, DATA_LEVELS.TOKEN, DATA_LEVELS.CREDENTIAL ],
    default:         DATA_LEVELS.DETAIL,
  },
  toObject:          {
    virtuals:        true,
  },
  id:                false,
})
export class Account extends sbase.mongoose.NModel {

  public static DATA_LEVELS = DATA_LEVELS;

  public accountType: string;

  @sbase.mongoose.Field({
    type:      mongoose.Schema.Types.ObjectId,
    ref:       'User',
    required:  true,
    index:     true,
  })
  public user: mongoose.Schema.Types.ObjectId;

  @sbase.mongoose.Field({
    type:      String,
    enum:      ['twitter', 'customized'],
    required:  true,
  })
  public provider: string;

  @sbase.mongoose.Field({
    type:      String,
    required:  true,
    min:       [   2, 'Min length of the name is 2 charactors.'   ],
    max:       [ 140, 'Max length of the name is 140 charactors.' ],
  })
  public name: string;

  @sbase.mongoose.Field({
    type:      String,
  })
  public imageUrl: string;

  @sbase.mongoose.Field({
    type:      Boolean,
    default:   false,
    api:       sbase.mongoose.AUTOGEN,
  })
  public verified: boolean;

  public verify(): any {
    // Abstract method
  }

  get accountCategory(): AccountCategory {
    return _.find(ACCOUNT_CATEGORIES, (accountCategory) => {
      return this.accountType === accountCategory.accountType &&
        this.provider === accountCategory.provider;
    });
  }
}
