import * as sbase from '@nodeswork/sbase';

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

  .post('/login')

  .get('/logout')

  .get('/', (ctx) => {
    ctx.body = { hello: 'world' };
  })
;

const SEND_VERIFY_EMAIL_MESSAGE =
  'A verification email has been sent to your registered email address';

async function sendVerifyEmail(ctx: any, next: () => void) {
  await next();
  await ctx.user.sendVerifyEmail();
  ctx.body = {
    status: 'ok',
    message: SEND_VERIFY_EMAIL_MESSAGE,
  };
}
