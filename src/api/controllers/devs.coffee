_                       = require 'underscore'
KoaRouter               = require 'koa-router'

{
  overrideUserToDoc
  overrideUserToQuery
}                       = require './middlewares'
{ requireRoles, roles } = require './middlewares/roles'
{Applet}                = require '../models'


exports.devRouter = devRouter = new KoaRouter prefix: '/dev/'

devRouter

  .use requireRoles roles.DEVELOPER

  .get 'applets', overrideUserToQuery('owner'), Applet.findMiddleware()

  .get('applets/:appletId'
    overrideUserToQuery 'owner'
    Applet.getMiddleware field: 'appletId'
  )

  .post('applets'
    overrideUserToDoc 'owner'
    Applet.createMiddleware {
      omits: ['devToken', 'prodToken', 'packageName_unique']
    }
  )

  .post('applets/:appletId'
    overrideUserToQuery 'owner'
    overrideUserToDoc 'owner'
    Applet.updateMiddleware {
      field: 'appletId'
      omits: ['packageName_unique', 'devToken', 'prodToken']
    }
  )
