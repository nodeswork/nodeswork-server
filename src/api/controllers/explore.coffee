_               = require 'underscore'
KoaRouter       = require 'koa-router'

{NpmApplet}     = require '../models'


exports.exploreRouter = exploreRouter = new KoaRouter prefix: '/explore'


exploreRouter
  .get '/', (ctx) -> ctx.body = await NpmApplet.find {}
