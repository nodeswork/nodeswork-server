_                            = require 'underscore'
KoaRouter                    = require 'koa-router'
momentTimezones              = require 'moment-timezone'

{ AccountCategory }          = require '../models'


resourceRouter = new KoaRouter()

  .prefix '/resources'

  .get  '/timezones', (ctx) ->
    ctx.body = momentTimezones.tz.names()

  .get '/account-categories', AccountCategory.findMiddleware {
    populate: [ 'implements' ]
  }

  .get '/account-categories/:categoryId', AccountCategory.getMiddleware {
    field: 'categoryId'
  }


module.exports = {
  resourceRouter
}
