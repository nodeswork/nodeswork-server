import * as Router        from 'koa-router';

import * as errors        from '../../errors';
import { userAuthRouter } from './auth';

import { User }           from '../../models/models';

export const userRouter = new Router({ prefix: '/v1/u' })
  .use(fetchUserFromCookie)
  .use(userAuthRouter.routes(), userAuthRouter.allowedMethods())
;

async function fetchUserFromCookie(
  ctx: Router.IRouterContext, next: () => void,
) {
  if (ctx.session.userId) {
    ctx.user = await User.findById(ctx.session.userId);
  }
  await next();
}
