_                              = require 'underscore'
KoaRouter                      = require 'koa-router'

{ AccountCategory }            = require '../models'


resourceRouter = new KoaRouter()

  .prefix '/resources'

  .get '/account-categories', AccountCategory.findMiddleware {
    populate: [ 'implements' ]
  }

  .get '/account-categories/:categoryId', AccountCategory.getMiddleware {
    field: 'categoryId'
  }


module.exports = {
  resourceRouter
}
