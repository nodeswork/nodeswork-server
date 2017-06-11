_                           = require 'underscore'
KoaRouter                   = require 'koa-router'

{
  overrideUserToQuery
  overrideUserToDoc
}                           = require './middlewares'
{ requireRoles, roles }     = require './middlewares/roles'
{
  AppletExecution
}                           = require '../models'


executionRouter = new KoaRouter()

  .prefix '/executions'

  .use requireRoles roles.USER

  .get '/', overrideUserToDoc(), AppletExecution.findMiddleware {
    allowedQueryFields:  ['applet']
    sort:                '-createdAt'
    pagination:          20
  }


module.exports = {
  executionRouter
}
