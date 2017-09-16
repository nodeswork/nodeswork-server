import * as _      from 'underscore';
import * as Router from 'koa-router';

import * as sbase  from '@nodeswork/sbase';

import {
  DeviceContext,
  requireDevice,
}                  from './auth';
import { Device }  from '../../models';

export const deviceRouter: Router = new Router({ prefix: '/devices' })
  .use(requireDevice)
  .use(sbase.koa.overrides('headers.device-token->query.token'))
  .post('/', filterDeviceUpdates, Device.updateMiddleware({
    field: '*',
  }))
;

async function filterDeviceUpdates(ctx: DeviceContext, next: () => void) {
  _.extend(
    ctx.overrides.doc,
    _.pick(
      ctx.request.body,
      'osVersion', 'containerVersion', 'runningApplets', 'installedApplets',
    ),
  );
  await next();
}
