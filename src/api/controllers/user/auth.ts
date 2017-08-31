import * as sbase from "@nodeswork/sbase";

import { User } from "../../models/models";

export class NRouter extends sbase.koa.NRouter {}

export const router = new NRouter({
  prefix: "/user",
});

router

  .post("/register", catchMiddleware, User.createMiddleware({
    allowCreateFromParentModel: true,
  }))

  .post("/login")

  .get("/logout")

  .get("/", (ctx) => {
    ctx.body = { hello: "world" };
  })
;

async function catchMiddleware(ctx: any, next: () => void) {
  await next();
}
