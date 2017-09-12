import * as _                  from 'underscore';
import * as Router             from 'koa-router';

import * as errors             from '../../errors';
import { NRouter }             from '../router';
import { User }                from '../../models';
import { DETAIL, USER_STATUS } from '../../models/users/users';

export const userAuthRouter = new NRouter({
  prefix: '/user',
});

userAuthRouter

  .post('/register', sendVerifyEmail, User.createMiddleware({
    target:                      'user',
    allowCreateFromParentModel:  true,
    noBody:                      true,
  }))

  .post('/verifyUserEmail', User.verifyUserEmail as any)

  .post('/login', login)

  .get('/logout', logout)

  .get('/', requireUserLogin, (ctx) => {
    ctx.body = ctx.user;
  })

  .post('/sendVerifyEmail', sendVerifyEmail, requireUnActiveUserLogin, _.noop)
;

export async function requireUserLogin(
  ctx: Router.IRouterContext, next: () => void,
) {
  if (ctx.session.userId) {
    ctx.user = await User.findById(ctx.session.userId);
  }

  if (ctx.user == null) {
    throw errors.REQUIRE_LOGIN_ERROR;
  }

  await next();
}

async function requireUnActiveUserLogin(
  ctx: Router.IRouterContext, next: () => void,
) {
  if (ctx.session.userId) {
    ctx.user = await User.findById(ctx.session.userId, null, {
      withUnActive: true,
    });
  }

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
  ctx.session.userId  = user._id;

  if (user.status === USER_STATUS.UNVERIFIED) {
    throw errors.USER_NOT_ACTIVE_ERROR;
  }

  ctx.body            = user.toJSON({ level: DETAIL });
}

async function logout(ctx: Router.IRouterContext) {
  ctx.session.userId  = null;
  ctx.status = 200;
}
