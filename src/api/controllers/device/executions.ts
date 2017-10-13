import * as _                  from 'underscore';
import * as Router             from 'koa-router';

import * as sbase              from '@nodeswork/sbase';

import * as models             from '../../models';
import { requireDevice }       from './auth';
import {
  DeviceContext,
  UserAppletContext,
}                              from '../def';

const EXECUTION_ID_FIELD = 'executionId';

export const executionRouter: Router = new Router({ prefix: '/executions' })

  .use(requireDevice)

  .post(`/:${EXECUTION_ID_FIELD}/metrics`,
    sbase.koa.overrides(
      'device._id->query.device',
      'device.user->query.user',
    ),
    models.AppletExecution.getMiddleware({
      field:        EXECUTION_ID_FIELD,
      triggerNext:  true,
      target:       'execution',
      noBody:       true,
    }),
    updateMetrics('execution'),
  )

;

function updateMetrics(field: string) {
  return async (ctx: Router.IRouterContext, next: () => void) => {
    const target: sbase.metrics.MetricsModel = (ctx as any)[field];
    target.appendMetrics({
      dimensions:  ctx.request.body.dimensions,
      name:        ctx.request.body.name,
      value:       ctx.request.body.value,
    });
    await target.save();
  };
}
