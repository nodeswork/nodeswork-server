import * as Router        from 'koa-router';

import { userAuthRouter } from './auth';

export const userRouter = new Router({ prefix: '/v1/u' })
  .use(userAuthRouter.routes(), userAuthRouter.allowedMethods())
;
