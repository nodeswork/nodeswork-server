KoaRouter  = require 'koa-router'

models     = require './models'

router  = new KoaRouter

router
  .get '/', (ctx, next) ->
    ctx.body = 'hello world'
    await next

module.exports = {
  models: models
  router: router
}
