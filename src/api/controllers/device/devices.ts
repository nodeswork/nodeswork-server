import * as _            from 'underscore';
import * as Router       from 'koa-router';

import * as sbase        from '@nodeswork/sbase';

import { DeviceContext } from './auth';
import { Device }        from '../../models';

export const deviceRouter: Router = new Router({ prefix: '/devices' })
  .post('/', filterDeviceUpdates, Device.updateMiddleware({
    field: '*',
  }))
;

async function filterDeviceUpdates(ctx: DeviceContext, next: () => void) {
  ctx.request.body = _.pick(
    ctx.request.body, 'osVersion', 'containerVersion', 'runningApplets',
  );
  await next();
}
