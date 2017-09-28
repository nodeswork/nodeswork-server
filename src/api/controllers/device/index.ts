import * as Router            from 'koa-router';

import { deviceRouter as dr } from './devices';
import { appletsRouter }      from './applets';

export const deviceRouter = new Router({ prefix: '/v1/d' })
  .use(dr.routes(), dr.allowedMethods())
  .use(appletsRouter.routes(), appletsRouter.allowedMethods())
;
