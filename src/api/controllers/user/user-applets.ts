import * as _               from 'underscore';
import * as Router          from 'koa-router';

import * as sbase           from '@nodeswork/sbase';

import * as errors          from '../../errors';
import * as models          from '../../models';
import { requireUserLogin } from './auth';

export const userAppletRouter = new Router({
  prefix: '/my-applets',
});

const USER_APPLET_ID_FIELD = 'userAppletId';

interface UserAppletContext extends Router.IRouterContext {
  userApplet: models.UserApplet;
}

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
    `/:${USER_APPLET_ID_FIELD}/work/:workerName/:workerAction`,
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
    name:    ctx.params.workerName,
    action:  ctx.params.workerAction,
  });
}

function checkUserAppletsAndDevices(
  middleware: Router.IMiddleware,
): Router.IMiddleware {
  return async (ctx: Router.IRouterContext, next: () => void) => {
    await next();
    await ctx.user.checkAppletsAndDevices();
    await middleware(ctx, null);
  };
}

async function transformUserApplet(
  userApplet: models.UserApplet,
): Promise<models.UserApplet> {
  const result = userApplet.toJSON() as any;
  const target = await userApplet.populateAppletConfig();
  result.config.appletConfig = target;
  result.config.upToDate = (
    target._id.toString() === result.applet.config._id.toString()
  );
  const stats = await userApplet.stats();
  result.stats = stats;
  return result;
}
