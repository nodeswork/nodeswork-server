import * as mongoose from 'mongoose';

import * as sbase    from '@nodeswork/sbase';

import * as models   from '../../models';

export type AppletExecutionType = (
  typeof AppletExecution
  & sbase.metrics.MetricsModelType
  & sbase.mongoose.NModelType
);

export interface AppletExecution extends sbase.metrics.MetricsModel {}

@sbase.mongoose.Config({
  collection:        'executions.applets',
})
@sbase.mongoose.Mixin(sbase.metrics.MetricsModel)
@sbase.mongoose.Index({ fields: { 'user': 1, 'userApplet': 1, 'timerange.start': -1 } })
@sbase.mongoose.Index({ fields: { 'applet': 1, 'timerange.start': -1 } })
export class AppletExecution extends sbase.mongoose.NModel {

  @sbase.mongoose.Field({
    type:      mongoose.Schema.Types.ObjectId,
    ref:       'User',
    required:  true,
    api:       sbase.mongoose.READONLY,
  })
  public user: mongoose.Types.ObjectId | models.User;

  @sbase.mongoose.Field({
    type:      mongoose.Schema.Types.ObjectId,
    ref:       'Applet',
    required:  true,
    api:       sbase.mongoose.READONLY,
  })
  public applet: mongoose.Types.ObjectId | models.Applet;

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

  @sbase.mongoose.Field({
    type:      {
      handler: String,
      name:    String,
    },
    required:  true,
    api:       sbase.mongoose.READONLY,
  })
  public worker: { handler: string; name: string; };
}
