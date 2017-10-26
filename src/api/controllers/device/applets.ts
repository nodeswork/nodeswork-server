import * as _                  from 'underscore';
import * as Router             from 'koa-router';

import * as sbase              from '@nodeswork/sbase';

import * as models             from '../../models';
import * as errors             from '../../errors';
import { deviceSocketManager } from '../../sockets';
import { requireDevice }       from './auth';
import {
  AccountContext,
  DeviceContext,
  UserAppletContext,
}                              from '../def';
import { transformUserApplet } from '../common';

const APPLET_ID_FIELD       = 'appletId';
const ACCOUNT_ID_FIELD      = 'accountId';

export const appletsRouter: Router = new Router({ prefix: '/applets' })

  .use(requireDevice)

  .post(
    `/:${APPLET_ID_FIELD}/accounts/:${ACCOUNT_ID_FIELD}/operate`,
    sbase.koa.overrides(
      'device.user->query.user',
      `params.${APPLET_ID_FIELD}->query.applet`,
    ),
    async (ctx: DeviceContext, next: () => void) => {
      ctx.overrides.query.enabled = true;
      await next();
    },
    models.UserApplet.getMiddleware({
      field:       '*',
      populate:    [
        { path: 'applet' },
      ],
      target:      'userApplet',
      noBody:      true,
      triggerNext: true,
    }),
    sbase.koa.clearOverrides(),
    verifyAccountId,
    sbase.koa.overrides('device.user->query.user'),
    models.Account.getMiddleware({
      field:       ACCOUNT_ID_FIELD,
      target:      'account',
      noBody:      true,
      triggerNext: true,
      level:       models.Account.DATA_LEVELS.CREDENTIAL,
    }),
    operate,
  )
;

async function verifyAccountId(ctx: UserAppletContext, next: () => void) {
  // TODO: Verify applet token
  const accountConfig = _.find(ctx.userApplet.config.accounts, (account) => {
    return account.account.toString() === ctx.params[ACCOUNT_ID_FIELD];
  });

  if (accountConfig == null) {
    throw errors.NO_ACCOUNT_OPERATE_PERMISSION_ERROR;
  }

  await next();
}

async function operate(ctx: AccountContext & UserAppletContext) {
  if (!ctx.account.verified) {
    throw errors.ACCOUNT_IS_NOT_VERIFIED;
  }

  // TODO: Verify body.
  ctx.body = await ctx.account.operate(ctx.request.body, ctx.userApplet);
}
