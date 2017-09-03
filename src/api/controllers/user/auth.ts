import * as sbase from "@nodeswork/sbase";

import { router } from '../router';

import { User } from "../../models/models";
import { DETAIL } from "../../models/users/users";

export class NRouter extends sbase.koa.NRouter {}

export const apiRouter = new NRouter({
  prefix: "/user",
});

apiRouter

  .post("/register", sendVerifyEmail, User.createMiddleware({
    target:                      "user",
    allowCreateFromParentModel:  true,
    noBody:                      true,
  }))

  .post("/login")

  .get("/logout")

  .get("/", (ctx) => {
    ctx.body = { hello: "world" };
  })
;

router
  .get('/users/verifyUserEmail', User.verifyUserEmail as any)
;

async function sendVerifyEmail(ctx: any, next: () => void) {
  await next();
  await ctx.user.sendVerifyEmail();
  ctx.body = {
    status: "ok",
    message: "A verification email has been sent to your registered email address",
  };
}
