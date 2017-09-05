import * as sbase  from '@nodeswork/sbase';
import * as Router from 'koa-router';

import * as errors from '../../errors';
import { NRouter } from '../router';
import { User }    from '../../models/models';
import { DETAIL }  from '../../models/users/users';

export const userAuthRouter = new NRouter({
  prefix: '/user',
});

userAuthRouter

  .post('/register', sendVerifyEmail, User.createMiddleware({
    target:                      'user',
    allowCreateFromParentModel:  true,
    noBody:                      true,
  }))

  .get('/verifyUserEmail', User.verifyUserEmail as any)

  .post('/login', login)

  .get('/logout', logout)

  .get('/', requireUserLogin, (ctx) => {
    ctx.body = ctx.user;
  })
;

export async function requireUserLogin(
  ctx: Router.IRouterContext, next: () => void,
) {
  if (ctx.user == null) {
    throw errors.REQUIRE_LOGIN_ERROR;
  }
  await next();
}

const SEND_VERIFY_EMAIL_MESSAGE =
  'A verification email has been sent to your registered email address';

async function sendVerifyEmail(ctx: any, next: () => void) {
  await next();
  await ctx.user.sendVerifyEmail();
  ctx.body = {
    status:   'ok',
    message:  SEND_VERIFY_EMAIL_MESSAGE,
  };
}

async function login(ctx: Router.IRouterContext) {
  const user = await User.verifyEmailPassword(
    ctx.request.body.email, ctx.request.body.password,
  );

  ctx.body            = user.toJSON({ level: DETAIL });
  ctx.session.userId  = user._id;
}

async function logout(ctx: Router.IRouterContext) {
  ctx.session.userId  = null;
  ctx.status = 200;
}
