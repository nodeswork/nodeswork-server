import * as Router          from 'koa-router';

import * as sbase           from '@nodeswork/sbase';

import { requireUserLogin } from './auth';
import * as models          from '../../models';

export const accountRouter = new Router({
  prefix: '/accounts',
});

const ACCOUNT_ID_FIELD = 'accountId';

interface AccountContext extends Router.IRouterContext {
  account: models.Account;
}

accountRouter

  .use(requireUserLogin)

  .post(
    '/', sbase.koa.overrides('user._id->doc.user'),
    models.Account.createMiddleware({}),
  )

  .get(
    '/', sbase.koa.overrides('user._id->query.user'),
    models.Account.findMiddleware({}),
  )

  .get(
    `/:${ACCOUNT_ID_FIELD}`, sbase.koa.overrides('user._id->query.user'),
    models.Account.getMiddleware({ field: ACCOUNT_ID_FIELD }),
  )

  .post(
    `/:${ACCOUNT_ID_FIELD}`, sbase.koa.overrides('user._id->query.user'),
    models.Account.updateMiddleware({ field: ACCOUNT_ID_FIELD }),
  )

  .post(
    `/:${ACCOUNT_ID_FIELD}/verify`,
    sbase.koa.overrides('user._id->query.user'),
    models.Account.getMiddleware({
      field:        ACCOUNT_ID_FIELD,
      target:       'account',
      noBody:       true,
      triggerNext:  true,
    }),
    verifyAccount,
  )
;

async function verifyAccount(ctx: AccountContext) {
  ctx.body = await ctx.account.verify();
}
