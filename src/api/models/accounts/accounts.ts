import * as mongoose      from 'mongoose';
import * as _             from 'underscore';

import * as sbase         from '@nodeswork/sbase';
import { NodesworkError } from '@nodeswork/utils';

const DATA_LEVELS = {
  DETAIL:      'DETAIL',
  CREDENTIAL:  'CREDENTIAL',
};

export type AccountTypeT = typeof Account & sbase.mongoose.NModelType;
export interface AccountType extends AccountTypeT {}

@sbase.mongoose.Config({
  collection:        'accounts',
  discriminatorKey:  'accountType',
  dataLevel:         {
    levels:          [ DATA_LEVELS.DETAIL, DATA_LEVELS.CREDENTIAL ],
    default:         DATA_LEVELS.DETAIL,
  },
})
export class Account extends sbase.mongoose.NModel {

  public static DATA_LEVELS = DATA_LEVELS;

  @sbase.mongoose.Field({
    type:      mongoose.Schema.Types.ObjectId,
    ref:       'User',
    required:  true,
    index:     true,
  })
  public user: mongoose.Schema.Types.ObjectId;

  @sbase.mongoose.Field({
    type:      String,
    required:  true,
    min:       [   2, 'Min length of the name is 2 charactors.'   ],
    max:       [ 140, 'Max length of the name is 140 charactors.' ],
  })
  public name: string;

  @sbase.mongoose.Field({
    type:      Boolean,
    default:   false,
    api:       sbase.mongoose.AUTOGEN,
  })
  public verified: boolean;
}
