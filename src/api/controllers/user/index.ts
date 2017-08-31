import * as Router from "koa-router";
import * as _ from "underscore";

import {
  ErrorCaster,
  ErrorOptions,
  NodesworkError,
  NodesworkErrorClass,
} from "@nodeswork/utils";

import * as errors from "../../errors";
import * as auth from "./auth";

export const router = new Router({
  prefix: "/v1/u",
});

router
  .use(handleApiRequest)
  .use(auth.router.routes(), auth.router.allowedMethods());

async function handleApiRequest(ctx: any, next: () => void) {
  try {
    await next();
  } catch (e) {
    e = NodesworkError.cast(e);
    ctx.status = e.meta.responseCode || 500;
    ctx.body = _.extend({
      message: e.message,
    }, e.meta);
  }
}

class MongooseErrorCaster implements ErrorCaster {

  public filter(error: any, options: ErrorOptions): boolean {
    if (error.name === "ValidationError" && error.errors != null) {
      return true;
    }
    if (error.name === "MongoError" && error.code === 11000) {
      return true;
    }
    return false;
  }

  public cast(error: any, options: ErrorOptions, cls: NodesworkErrorClass): NodesworkError {
    if (error.errors) {
      return new NodesworkError("invalid value", {
        errors: _.mapObject(error.errors, mapMongooseError),
        responseCode: 422,
      });
    }
    if (error.code === 11000) {
      return new NodesworkError("duplicate record", {
        responseCode: 422,
      });
    }
    return null;
  }
}

function mapMongooseError(error: any) {
  if (error && error.kind === "user defined") {
    return {
      kind: error.message,
      path: error.path,
    };
  }
  return _.pick(error, "kind", "path");
}

NodesworkError.addErrorCaster(new MongooseErrorCaster());
