import * as Router from "koa-router";

import * as errors from "../../errors";
import * as auth from "./auth";

export const apiRouter = new Router({
  prefix: "/v1/u",
});

apiRouter
  .use(auth.router.routes(), auth.router.allowedMethods());
