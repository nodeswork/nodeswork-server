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
    overrides('user._id->user:doc', 'device._id->_id:doc'),
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
  const rs: Array<{ src: string[], dst: string, target: string }> = [];
  for (const rule of rules) {
    const [t, target] = rule.split(':');
    const [os, od]    = t.split('->');
    const src         = os.split('.');
    const dst         = od || os;

    rs.push({ src, dst, target });
  }
  return async (ctx: Router.IRouterContext, next: () => void) => {
    for (const { src, dst, target } of rs) {
      (ctx.overrides as any)[target][dst] = dotty.get(ctx, src);
    }
    await next();
  };
}
