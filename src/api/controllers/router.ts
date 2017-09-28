import * as Router from 'koa-router';

import * as sbase  from '@nodeswork/sbase';

declare module 'koa-router' {
  interface IRouterContext {
    session: any;
  }
}

export class NRouter extends sbase.koa.NRouter {}
