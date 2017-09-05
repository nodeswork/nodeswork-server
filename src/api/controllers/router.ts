import * as Router from 'koa-router';

import * as sbase  from '@nodeswork/sbase';

import { User }    from '../models/users/users';

declare module 'koa-router' {
  interface IRouterContext {
    session: any;
    user?:   User;
  }
}

export class NRouter extends sbase.koa.NRouter {}
