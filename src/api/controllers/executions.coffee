_                           = require 'underscore'
KoaRouter                   = require 'koa-router'

{
  requireLogin
  overrideUserToQuery
  overrideUserToDoc
}                           = require './middlewares'
{
  AppletExecution
}                           = require '../models'


exports.executionRouter = executionRouter = new KoaRouter prefix: '/executions'


executionRouter

  .use requireLogin

  .get '/', overrideUserToDoc(), AppletExecution.findMiddleware {
    allowedQueryFields:  ['applet']
    sort:                '-createdAt'
    pagination:          20
  }
