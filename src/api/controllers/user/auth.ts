import * as sbase from "@nodeswork/sbase";

import { User } from "../../models/models";
import { DETAIL } from "../../models/users/users";

export class NRouter extends sbase.koa.NRouter {}

export const router = new NRouter({
  prefix: "/user",
});

router

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

async function sendVerifyEmail(ctx: any, next: () => void) {
  await next();
  await ctx.user.sendVerifyEmail();
  ctx.body = {
    status: "ok",
    message: "A verification email has been sent to your registered email address",
  };
}
