import * as sbase from "@nodeswork/sbase";

import { User } from "../models/models";

export class NRouter extends sbase.koa.NRouter {}

export const router = new NRouter({
  prefix: "/user",
});

router

  .post("/register", User.createMiddleware({}))

  .post("/login")

  .get("/logout")

  .get("/")
;
