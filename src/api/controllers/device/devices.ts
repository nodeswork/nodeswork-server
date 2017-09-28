import * as _                  from 'underscore';
import * as Router             from 'koa-router';

import * as sbase              from '@nodeswork/sbase';

import { deviceSocketManager } from '../../sockets';

import { requireDevice }       from './auth';
import { Device }              from '../../models';
import { DeviceContext }       from '../def';

export const deviceRouter: Router = new Router({ prefix: '/devices' })
  .use(requireDevice)
  .use(sbase.koa.overrides('headers.device-token->query.token'))
  .post('/', filterDeviceUpdates, Device.updateMiddleware({
    field:   '*',
    target:  'device',
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
  deviceSocketManager.updateDevice(ctx.device);
}
