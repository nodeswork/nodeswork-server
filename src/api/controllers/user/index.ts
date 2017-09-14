import * as Router          from 'koa-router';

import { userAuthRouter }   from './auth';
import { deviceRouter }     from './devices';
import { appletRouter }     from './applets';
import { userAppletRouter } from './user-applets';

export const userRouter = new Router({ prefix: '/v1/u' })
  .use(userAuthRouter.routes(), userAuthRouter.allowedMethods())
  .use(deviceRouter.routes(), deviceRouter.allowedMethods())
  .use(appletRouter.routes(), appletRouter.allowedMethods())
  .use(userAppletRouter.routes(), userAppletRouter.allowedMethods())
;
