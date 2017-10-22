import * as _                  from 'underscore';
import * as Router             from 'koa-router';

import * as sbase              from '@nodeswork/sbase';

import * as errors             from '../../errors';
import * as models             from '../../models';
import {
  requireUserLogin,
  updateUserProperties,
}                              from './auth';
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
    updateAndCheckUserAppletsAndDevices(
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

  .delete(
    `/:${USER_APPLET_ID_FIELD}`, sbase.koa.overrides('user._id->query.user'),
    models.UserApplet.deleteMiddleware({
      field:        USER_APPLET_ID_FIELD,
      triggerNext:  true,
    }),
    updateUserProperties,
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

  .get(
    `/:${USER_APPLET_ID_FIELD}/route/:path*`,
    sbase.koa.overrides('user._id->query.user'),
    models.UserApplet.getMiddleware({
      field:       USER_APPLET_ID_FIELD,
      populate:    [
        { path: 'applet' },
      ],
      transform:   transformUserApplet,
      target:      'userApplet',
      noBody:      true,
      triggerNext: true,
    }),
    route,
  )
;

async function work(ctx: UserAppletContext) {
  ctx.body = await ctx.userApplet.work({
    handler:  ctx.params.handler,
    name:     ctx.params.name,
  });
}

async function route(ctx: UserAppletContext) {
  ctx.body = await ctx.userApplet.routeGet(ctx.params.path);
}

function updateAndCheckUserAppletsAndDevices(
  middleware: Router.IMiddleware,
): Router.IMiddleware {
  return async (ctx: UserContext, next: () => void) => {
    await next();
    await ctx.user.checkAppletsAndDevices();
    await middleware(ctx, null);
  };
}
