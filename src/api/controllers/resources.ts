import * as Router            from 'koa-router';

import { ACCOUNT_CATEGORIES } from '../models/accounts/account-categories';

export const resourcesRouter = new Router({
  prefix: '/resources',
});

resourcesRouter

  .get('/account-categories', (ctx: Router.IRouterContext) => {
    ctx.body = ACCOUNT_CATEGORIES;
  })
;
