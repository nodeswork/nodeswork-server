import * as _               from 'underscore';
import * as Router          from 'koa-router';

import * as sbase           from '@nodeswork/sbase';
import { metrics }          from '@nodeswork/utils';

import { requireUserLogin } from './auth';
import * as models          from '../../models';
import { UserContext }      from '../def';

export const metricsRouter = new Router({
  prefix: '/metrics',
})
  .use(requireUserLogin)
  .use(sbase.koa.overrides('user._id->query.user'))

  .post(
    '/system/user-applets/:userAppletId/executions',
    sbase.koa.overrides('params.userAppletId->query.userApplet'),
    prepareMetricsParams(),
  )

  .post(
    '/user-applets/:userAppletId/executions',
    sbase.koa.overrides('params.userAppletId->query.userApplet'),
    prepareMetricsParams(),
  )

  .get('/applets/:appletId')

;

function prepareMetricsParams() {
  return async (ctx: UserContext) => {
    const datas = await models.AppletExecution.aggregateMetrics({
      timerange:            ctx.request.body.timerange,
      granularityInSecond:  ctx.request.body.granularity || 3600,
      query:                ctx.overrides.query,
      metrics:              ctx.request.body.metrics,
    });

    ctx.body = metrics.operator.filterMetricsDatasByValue(
      datas, {
        dimensions: ctx.request.body.dimensions,
        metrics:    ctx.request.body.metrics,
      },
    );
  };
}
