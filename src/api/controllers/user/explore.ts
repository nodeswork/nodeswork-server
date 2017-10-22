import * as _               from 'underscore';
import * as Router          from 'koa-router';

import * as sbase           from '@nodeswork/sbase';

import * as models          from '../../models';
import { requireUserLogin } from './auth';
import {
  UserAppletsContext,
  UserContext,
}                           from '../def';

export const exploreRouter = new Router({
  prefix: '/explore',
});

exploreRouter

  .use(requireUserLogin)

  .get(
    '/',
    sbase.koa.overrides('user._id->query.user'),
    models.UserApplet.findMiddleware({
      target:       'userApplets',
      triggerNext:  true,
      noBody:       true,
    }),
    explore(),
  )
;

function explore(): Router.IMiddleware {
  return async (ctx: UserAppletsContext & UserContext) => {
    const publicApplets = await models.Applet.find({
      permission: models.Applet.PERMISSIONS.PUBLIC,
    });
    const privateApplets = await models.Applet.find({
      permission: models.Applet.PERMISSIONS.PRIVATE,
      owner:      ctx.user._id,
    });
    const allApplets = publicApplets.concat(privateApplets);

    const installed  = _.map(ctx.userApplets, (ua) => ua.applet.toString());

    ctx.body = _.filter(allApplets, (applet) => {
      return installed.indexOf(applet._id.toString()) === -1;
    });
  };
}
