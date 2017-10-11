import * as Router             from 'koa-router';

import * as logger             from '@nodeswork/logger';

import { userRouter }          from './user';
import { deviceRouter }        from './device';
import { resourcesRouter }     from './resources';
import { config }              from '../../config';

import { deviceSocketManager } from '../sockets';

const packageConfig = require('../../../package.json');

const LOG = logger.getLogger();

export const router = new Router()
  .use(handleApiRequest)
  .use(intializeOverrides)
  .use(userRouter.routes(), userRouter.allowedMethods())
  .use(deviceRouter.routes(), deviceRouter.allowedMethods())
  .use(resourcesRouter.routes(), resourcesRouter.allowedMethods())
  .get('/sstats', sstats)
;

async function sstats(ctx: Router.IRouterContext) {
  ctx.body = {
    app:        {
      env:         config.app.env,
      port:        config.app.port,
      publicHost:  config.app.publicHost,
      version:     packageConfig.version,
    },
    devices: {
      connected:   deviceSocketManager.size,
    },
  };
}

// -------------------------------------------------------------------------

import * as _ from 'underscore';

import {
  ErrorCaster,
  ErrorOptions,
  NodesworkError,
  NodesworkErrorClass,
} from '@nodeswork/utils';

// TODO: Find a better place for these helper functions.
async function handleApiRequest(ctx: any, next: () => void) {
  try {
    LOG.info('Receive request', {
      url: ctx.request.url,
      method: ctx.request.method,
      headers: ctx.request.headers,
    });
    await next();
  } catch (e) {
    e = NodesworkError.cast(e);
    const statusCode = e.meta.responseCode || 500;
    if (statusCode >= 500) {
      console.log(e);
      LOG.error('internal service error', e);
    }

    ctx.status = statusCode;
    ctx.body = _.extend({
      message: e.message,
    }, e.meta);
  }
}

async function intializeOverrides(ctx: any, next: () => void) {
  ctx.overrides = {
    query: {},
    doc:   {},
  };
  await next();
}

class MongooseErrorCaster implements ErrorCaster {

  public filter(error: any, options: ErrorOptions): boolean {
    if (error.name === 'ValidationError' && error.errors != null) {
      return true;
    }
    if (error.name === 'MongoError' && error.code === 11000) {
      return true;
    }
    return false;
  }

  public cast(error: any, options: ErrorOptions, cls: NodesworkErrorClass): NodesworkError {
    if (error.errors) {
      return new NodesworkError('invalid value', {
        errors: _.mapObject(error.errors, mapMongooseError),
        responseCode: 422,
      });
    }
    if (error.code === 11000) {
      return new NodesworkError('duplicate record', {
        responseCode: 422,
      });
    }
    return null;
  }
}

function mapMongooseError(error: any) {
  if (error && error.kind === 'user defined') {
    return {
      kind: error.message,
      path: error.path,
    };
  }
  return _.pick(error, 'kind', 'path');
}

NodesworkError.addErrorCaster(new MongooseErrorCaster());
