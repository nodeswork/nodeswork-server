import * as _               from 'underscore';
import * as Router          from 'koa-router';

import * as sbase           from '@nodeswork/sbase';

import { requireUserLogin } from './auth';
import * as models          from '../../models';
import { UserContext }      from '../def';

export const metricsRouter = new Router({
  prefix: '/metrics',
})
  .use(requireUserLogin)
  .use(sbase.koa.overrides('user._id->query.user'))

  .get(
    '/system/user-applets/:userAppletId/executions',
    sbase.koa.overrides('params.userAppletId->query.userApplet'),
    prepareMetricsParams(),
  )

  .get('/applets/:appletId')

;

function prepareMetricsParams() {
  return async (ctx: UserContext) => {
    ctx.body = await models.AppletExecution.aggregateMetrics({
      timerange: {
        start: Number.parseInt(ctx.request.query.startTime),
        end:   Number.parseInt(ctx.request.query.endTime),
      },
      granularityInSecond: Number.parseInt(
        ctx.request.query.granularity,
      ) || 3600,
      query: ctx.overrides.query,
      metrics: _.flatten([ctx.request.query.metrics]),
    });
  };
}
