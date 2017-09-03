import * as sbase from "@nodeswork/sbase";

export class NRouter extends sbase.koa.NRouter {}

// server's root router.
export const router = new NRouter({});
