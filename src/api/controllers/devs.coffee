_                       = require 'underscore'
KoaRouter               = require 'koa-router'

{
  overrideUserToDoc
  overrideUserToQuery
  requireLogin
}                       = require './middlewares'
{Applet}                = require '../models'


exports.devRouter = devRouter = new KoaRouter prefix: '/dev/'

devRouter

  .use requireLogin

  .get 'applets', overrideUserToQuery('owner'), Applet.findMiddleware()

  .get('applets/:appletId'
    overrideUserToQuery 'owner'
    Applet.getMiddleware field: 'appletId'
  )

  .post('applets'
    overrideUserToDoc 'owner'
    Applet.createMiddleware()
  )

  .post('applets/:appletId'
    overrideUserToQuery 'owner'
    overrideUserToDoc 'owner'
    Applet.updateMiddleware {
      omits: ['packageName_unique']
    }
  )
