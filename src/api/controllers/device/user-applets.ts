import * as _                  from 'underscore';
import * as Router             from 'koa-router';

import * as sbase              from '@nodeswork/sbase';

import * as models             from '../../models';
import { transformUserApplet } from '../common';
import { requireDevice }       from './auth';
import {
  DeviceContext,
  UserAppletContext,
}                              from '../def';

const USER_APPLET_ID_FIELD = 'userAppletId';

export const userAppletsRouter: Router = new Router({ prefix: '/user-applets' })

  .use(requireDevice)

  .get('/',
    sbase.koa.overrides('device.user->query.user'),
    overrideDeviceQuery,
    models.UserApplet.findMiddleware({
      populate:    [
        { path: 'applet' },
      ],
      target:      'userApplet',
      transform:   transformUserApplet,
    }),
  )

  .get(`/:${USER_APPLET_ID_FIELD}/accounts`,
    sbase.koa.overrides('device.user->query.user'),
    overrideDeviceQuery,
    models.UserApplet.getMiddleware({
      field: USER_APPLET_ID_FIELD,
      populate:    [
        { path: 'applet' },
        { path: 'config.accounts.account' },
      ],
      target:      'userApplet',
      triggerNext: true,
      noBody:      true,
    }),
    fetchAccounts,
  )

  .post(`/:${USER_APPLET_ID_FIELD}/execute`,
    sbase.koa.overrides('device.user->query.user'),
    overrideDeviceQuery,
    models.UserApplet.getMiddleware({
      field: USER_APPLET_ID_FIELD,
      populate:    [
        { path: 'applet' },
        { path: 'config.accounts.account' },
      ],
      target:      'userApplet',
      triggerNext: true,
      noBody:      true,
    }),
    sbase.koa.overrides(
      'device.user->doc.user',
      `params.${USER_APPLET_ID_FIELD}->doc.userApplet`,
      'userApplet.applet._id->doc.applet',
      'device._id->doc.device',
    ),
    models.AppletExecution.createMiddleware({}),
  )
;

async function overrideDeviceQuery(ctx: DeviceContext, next: () => void) {
  ctx.overrides.query['config.devices.device'] = ctx.device._id;
  ctx.overrides.query.enabled = true;
  await next();
}

async function fetchAccounts(ctx: UserAppletContext) {
  ctx.body = _.map(
    ctx.userApplet.config.accounts,
    (account) => account.account,
  );
}
