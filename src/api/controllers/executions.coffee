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


exports.executionRouter = executionRouter = new KoaRouter prefix: '/executions'


executionRouter

  .use requireRoles roles.USER

  .get '/', overrideUserToDoc(), AppletExecution.findMiddleware {
    allowedQueryFields:  ['applet']
    sort:                '-createdAt'
    pagination:          20
  }
