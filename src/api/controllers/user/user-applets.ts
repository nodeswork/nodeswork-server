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

userAppletRouter

  .use(requireUserLogin)

  .post(
    '/', sbase.koa.overrides('user._id->doc.user'),
    models.UserApplet.createMiddleware({
      populate: {
        path: 'applet',
      },
    }),
  )

  .get(
    '/', sbase.koa.overrides('user._id->query.user'),
    models.UserApplet.findMiddleware({
      populate: {
        path: 'applet',
      },
    }),
  )

  .get(
    `/:${USER_APPLET_ID_FIELD}`, sbase.koa.overrides('user._id->query.user'),
    models.UserApplet.getMiddleware({ field: USER_APPLET_ID_FIELD }),
  )
;
