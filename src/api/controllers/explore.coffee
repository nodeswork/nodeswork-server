_               = require 'underscore'
KoaRouter       = require 'koa-router'

{requireLogin}  = require './middlewares'
{Applet}        = require '../models'


exports.exploreRouter = exploreRouter = new KoaRouter prefix: '/explore'


exploreRouter
  .get '/', (ctx) -> ctx.body = await Applet.find {}
