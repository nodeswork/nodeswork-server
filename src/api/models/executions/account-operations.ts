import * as mongoose from 'mongoose';

import * as sbase    from '@nodeswork/sbase';

import * as models   from '../../models';

export type AccountOperationType = (
  typeof AccountOperation
  & sbase.metrics.MetricsModelType
  & sbase.mongoose.NModelType
);

export interface AccountOperation extends sbase.metrics.MetricsModel {}

@sbase.mongoose.Config({
  collection:        'executions.accounts',
})
@sbase.mongoose.Mixin(sbase.metrics.MetricsModel)
export class AccountOperation extends sbase.mongoose.NModel {

  @sbase.mongoose.Field({
    type:      mongoose.Schema.Types.ObjectId,
    ref:       'User',
    required:  true,
    index:     true,
    api:       sbase.mongoose.READONLY,
  })
  public user: mongoose.Types.ObjectId | models.User;

  @sbase.mongoose.Field({
    type:      mongoose.Schema.Types.ObjectId,
    ref:       'Applet',
    index:     true,
    required:  true,
    api:       sbase.mongoose.READONLY,
  })
  public applet: mongoose.Types.ObjectId | models.Applet;

  @sbase.mongoose.Field({
    type:      mongoose.Schema.Types.ObjectId,
    ref:       'AppletExecution',
    index:     true,
    required:  true,
    api:       sbase.mongoose.READONLY,
  })
  public execution: mongoose.Types.ObjectId | models.AppletExecution;

  @sbase.mongoose.Field({
    type:      mongoose.Schema.Types.ObjectId,
    ref:       'UserApplet',
    required:  true,
    api:       sbase.mongoose.READONLY,
  })
  public userApplet: mongoose.Types.ObjectId | models.UserApplet;

  @sbase.mongoose.Field({
    type:      mongoose.Schema.Types.ObjectId,
    ref:       'Device',
    required:  true,
    api:       sbase.mongoose.READONLY,
  })
  public device: mongoose.Types.ObjectId | models.Device;

}
