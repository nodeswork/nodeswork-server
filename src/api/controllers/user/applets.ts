import * as _               from 'underscore';
import * as Router          from 'koa-router';

import * as sbase           from '@nodeswork/sbase';

import * as errors          from '../../errors';
import * as models          from '../../models';
import { requireUserLogin } from './auth';

export const appletRouter = new Router({
  prefix: '/applets',
});

const APPLET_ID_FIELD = 'appletId';

appletRouter

  .use(requireUserLogin)

  .post(
    '/', sbase.koa.overrides('user._id->doc.owner'),
    models.Applet.createMiddleware({
      level: models.Applet.DATA_LEVELS.TOKEN,
    }),
  )

  .get(
    '/', sbase.koa.overrides('user._id->query.owner'),
    models.Applet.findMiddleware({
      level: models.Applet.DATA_LEVELS.TOKEN,
    }),
  )

  .get(
    `/:${APPLET_ID_FIELD}`, sbase.koa.overrides('user._id->query.owner'),
    models.Applet.getMiddleware({ field: APPLET_ID_FIELD }),
  )

  .post(
    `/:${APPLET_ID_FIELD}`, sbase.koa.overrides('user._id->query.owner'),
    updateConfig(models.Applet.getMiddleware({
      field:   APPLET_ID_FIELD,
      target:  'applet',
      noBody:  true,
    })),
    models.Applet.updateMiddleware({
      field: APPLET_ID_FIELD,
      level: models.Applet.DATA_LEVELS.TOKEN,
    }),
  )
;

function updateConfig(get: Router.IMiddleware): Router.IMiddleware {
  return async (ctx: UpdateContext, next: () => void) => {
    if (ctx.request.body.config != null) {
      await get(ctx, null);
      ctx.applet.config                  = ctx.request.body.config;
      ctx.overrides.doc.configHistories  = ctx.applet.configHistories;
    }
    await next();
  };
}

interface UpdateContext extends Router.IRouterContext {
  applet: models.Applet;
}
