import * as Router          from 'koa-router';

import * as sbase           from '@nodeswork/sbase';

import { requireUserLogin } from './auth';
import { Device }           from '../../models/models';

const dotty               = require('dotty');

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

function overrides(...rules: string[]): Router.IMiddleware {
  const rs: Array<{ src: string[], dst: string[] }> = [];
  for (const rule of rules) {
    const [os, od] = rule.split('->');
    if (!od) {
      throw new Error(`Rule ${rule} is not correct`);
    }
    rs.push({ src: os.split('.'), dst: od.split('.') });
  }
  return async (ctx: Router.IRouterContext, next: () => void) => {
    for (const { src, dst } of rs) {
      const value = dotty.get(ctx, src);
      if (value !== undefined) {
        dotty.put(ctx.overrides, dst, value);
      }
    }
    await next();
  };
}
