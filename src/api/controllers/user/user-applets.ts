import * as _                  from 'underscore';
import * as Router             from 'koa-router';

import * as sbase              from '@nodeswork/sbase';

import * as errors             from '../../errors';
import * as models             from '../../models';
import { requireUserLogin }    from './auth';
import {
  UserAppletContext,
  UserContext,
}                              from '../def';
import { transformUserApplet } from '../common';

export const userAppletRouter = new Router({
  prefix: '/my-applets',
});

const USER_APPLET_ID_FIELD = 'userAppletId';

userAppletRouter

  .use(requireUserLogin)

  .post(
    '/', sbase.koa.overrides('user._id->doc.user'),
    models.UserApplet.createMiddleware({
      populate: { path: 'applet' },
      transform: transformUserApplet,
    }),
  )

  .get(
    '/', sbase.koa.overrides('user._id->query.user'),
    models.UserApplet.findMiddleware({
      populate: { path: 'applet' },
      transform: transformUserApplet,
    }),
  )

  .get(
    `/:${USER_APPLET_ID_FIELD}`, sbase.koa.overrides('user._id->query.user'),
    models.UserApplet.getMiddleware({
      field: USER_APPLET_ID_FIELD,
      populate: { path: 'applet' },
      transform: transformUserApplet,
    }),
  )

  .post(
    `/:${USER_APPLET_ID_FIELD}`, sbase.koa.overrides('user._id->query.user'),
    checkUserAppletsAndDevices(
      models.UserApplet.getMiddleware({
        field: USER_APPLET_ID_FIELD,
        populate: { path: 'applet' },
        transform: transformUserApplet,
      }),
    ),
    models.UserApplet.updateMiddleware({
      field: USER_APPLET_ID_FIELD,
      populate: { path: 'applet' },
      transform: transformUserApplet,
      noBody: true,
    }),
  )

  .post(
    `/:${USER_APPLET_ID_FIELD}/work/:handler/:name`,
    sbase.koa.overrides('user._id->query.user'),
    models.UserApplet.getMiddleware({
      field:       USER_APPLET_ID_FIELD,
      populate:    [
        { path: 'applet' },
        { path: 'config.accounts.account' },
      ],
      transform:   transformUserApplet,
      target:      'userApplet',
      noBody:      true,
      triggerNext: true,
    }),
    work,
  )
;

async function work(ctx: UserAppletContext) {
  ctx.body = await ctx.userApplet.work({
    handler:  ctx.params.handler,
    name:     ctx.params.name,
  });
}

function checkUserAppletsAndDevices(
  middleware: Router.IMiddleware,
): Router.IMiddleware {
  return async (ctx: UserContext, next: () => void) => {
    await next();
    await ctx.user.checkAppletsAndDevices();
    await middleware(ctx, null);
  };
}
