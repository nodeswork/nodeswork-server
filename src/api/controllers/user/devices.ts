import * as Router          from 'koa-router';

import * as sbase           from '@nodeswork/sbase';

import { requireUserLogin } from './auth';
import { Device }           from '../../models';
import { overrides }        from '../middlewares';

export const deviceRouter = new Router({
  prefix: '/devices',
})
  .use(requireUserLogin)
  .use(overrides('user._id->query.user'))

  .post(
    '/',
    updateExistingDevice(Device.updateMiddleware({ field: 'deviceId' })),
    overrides('user._id->doc.user'),
    Device.createMiddleware({}),
  )

  .get('/:deviceId', Device.getMiddleware({ field: 'deviceId' }))

  .get('/', Device.findMiddleware({}))

  .post('/:deviceId', Device.updateMiddleware({ field: 'deviceId' }))

;

function updateExistingDevice(
  updateMiddleware: Router.IMiddleware,
): Router.IMiddleware {
  return async (ctx: Router.IRouterContext, next: () => void) => {
    const query  = {
      user:             ctx.user._id,
      deviceIdentifier: ctx.request.body.deviceIdentifier,
    };
    const device = await Device.findOne(query);
    if (device == null) {
      await next();
    } else {
      ctx.params.deviceId = device._id;
      await updateMiddleware(ctx, null);
    }
  };
}
