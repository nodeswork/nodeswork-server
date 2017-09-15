import * as Router          from 'koa-router';
import * as devices         from './devices';

export const deviceRouter = new Router({ prefix: '/v1/d' })
  .use(devices.deviceRouter.routes(), devices.deviceRouter.allowedMethods())
;
