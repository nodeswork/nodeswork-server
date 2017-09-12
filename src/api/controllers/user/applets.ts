import * as _               from 'underscore';
import * as Router          from 'koa-router';

import * as sbase           from '@nodeswork/sbase';

import * as errors          from '../../errors';
import * as models          from '../../models';
import { requireUserLogin } from './auth';
import { overrides }        from '../middlewares';

export const appletRouter = new Router({
  prefix: '/applets',
});

appletRouter

  .use(requireUserLogin)

  .post(
    '/', sbase.koa.overrides('user._id->doc.owner'),
    models.Applet.createMiddleware({}),
  )

  .get(
    '/', sbase.koa.overrides('user._id->query.owner'),
    models.Applet.findMiddleware({}),
  )

  .get(
    '/:appletId', sbase.koa.overrides('user._id->query.owner'),
    models.Applet.getMiddleware({ field: 'appletId' }),
  )

  .post(
    '/:appletId', sbase.koa.overrides('user._id->query.owner'),
    models.Applet.updateMiddleware({ field: 'appletId' }),
  )
;
