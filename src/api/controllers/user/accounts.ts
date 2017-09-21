import * as Router          from 'koa-router';

import * as sbase           from '@nodeswork/sbase';

import { requireUserLogin } from './auth';
import * as models          from '../../models';
import * as errors          from '../../errors';
import { config }           from '../../../config';

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
    '/oauth-callback', sbase.koa.overrides('user._id->query.user'),
    oAuthCallback,
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

async function oAuthCallback(ctx: Router.IRouterContext) {
  const oAuthToken: string      = ctx.request.query.oauth_token;
  const oAuthVerifier: string   = ctx.request.query.oauth_verifier;

  const account: models.OAuthAccount = await models.OAuthAccount.findOne({
    user: ctx.user._id,
    oAuthToken,
  }, undefined, { level: models.OAuthAccount.DATA_LEVELS.CREDENTIAL });

  if (account == null) {
    throw errors.UNRECOGNIZED_TOKEN_ERROR;
  }

  await account.requestAccessToken(oAuthVerifier);

  ctx.redirect(config.app.publicHost);
}
