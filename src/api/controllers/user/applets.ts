import * as _                  from 'underscore';
import * as Router             from 'koa-router';

import * as errors             from '../../errors';
import * as models             from '../../models';
import { requireUserLogin }    from './auth';
import { overrides }           from '../middlewares';

export const appletRouter = new Router({
  prefix: '/applelts',
});

appletRouter

  .use(requireUserLogin)

  .post(
    '/', overrides('user._id->doc.owner'), models.Applet.createMiddleware({}),
  )

  .get(
    '/', overrides('user._id->query.owner'), models.Applet.findMiddleware({}),
  )

  .get(
    '/:appletId', overrides('user._id->query.owner'),
    models.Applet.getMiddleware({ field: 'appletId' }),
  )

  .post(
    '/:appletId', overrides('user._id->query.owner'),
    models.Applet.updateMiddleware({ field: 'appletId' }),
  )
;
