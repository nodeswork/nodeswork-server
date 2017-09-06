import * as Router          from 'koa-router';

import * as sbase           from '@nodeswork/sbase';

import { requireUserLogin } from './auth';
import { Device }           from '../../models/models';

const dotty               = require('dotty');

export const deviceRouter = new Router({
  prefix: '/devices',
})
  .use(requireUserLogin)
  .use(overrides('user:query'))

  .post(
    '/',
    findExistingDevice,
    overrides('user._id->doc.user', 'device._id->doc._id'),
    Device.createMiddleware({}),
  )

  .get('/:deviceId', Device.getMiddleware({ field: 'deviceId' }))

  .get('/', Device.findMiddleware({}))

  .post('/:deviceId', Device.updateMiddleware({ field: 'deviceId' }))

;

async function findExistingDevice(
  ctx: Router.IRouterContext, next: () => void,
) {
  const query = {
    user:             ctx.user,
    deviceIdentifier: ctx.body.deviceIdentifier,
  };
  (ctx as any).device = await Device.findOne(query);
  await next();
}

function overrides(...rules: string[]): Router.IMiddleware {
  const rs: Array<{ src: string[], dst: string[] }> = [];
  for (const rule of rules) {
    const [os, od] = rule.split('->');
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
