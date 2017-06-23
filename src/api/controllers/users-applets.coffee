_                              = require 'underscore'
KoaRouter                      = require 'koa-router'

{
  overrideUserToQuery
  overrideUserToDoc
  expandedInJSON
}                              = require './middlewares'
{ requireRoles, roles }        = require './middlewares/roles'
{
  Applet
  Device
  UserApplet
}                              = require '../models'
{ params, rules }              = require './params'
{ ParameterValidationError }   = require '../errors'
{ MINIMAL_DATA_LEVEL }         = require '../constants'


usersAppletsRouter = new KoaRouter()

  .use requireRoles roles.USER


UserApplet.expose usersAppletsRouter, {
  prefix:            '/my-applets'
  idField:           'relationId'
  cruds:             [ 'find', 'get' ]
  options:
    get:
      populate:      [
        {
          path:      'applet'
          select:
            $level:  MINIMAL_DATA_LEVEL
        }
        {
          path:      'device'
          select:
            $level:  MINIMAL_DATA_LEVEL
        }
      ]
  posts:
    get:             [ expandedInJSON() ]
}


validateUserApplet = (ctx, next) ->
  [userApplet, applet] = [ctx.userApplet, ctx.userApplet.applet]

  if userApplet.device? and !applet.containers.userDevice
    throw new ParameterValidationError 'Applet is not suitable for device.'

  unless applet.avaiableTo ctx.user
    throw new ParameterValidationError 'Applet is not available for you.'

  if !userApplet.device and applet.requireDevice
    throw new ParameterValidationError 'Applet requires device.'

  await next()


usersAppletsRouter

  # TODO: Move to expose
  .post('/my-applets/:relationId', overrideUserToQuery(), overrideUserToDoc()
    UserApplet.updateMiddleware {
      field:     'relationId'
      omits:     ['user', 'applet', 'errMsg']
      target:    'userApplet'
      populate:  ['applet', 'device']
    }
    validateUserApplet
  )

  # Load applet and verify the permission.
  .post('/my-applets'
    params.body(
      applet: [
        rules.isRequired
        rules.populateFromModel Applet
      ]
      device: [
        rules.populateFromModel Device
      ]
    )
    overrideUserToDoc()
    UserApplet.createMiddleware {
      fromExtend:  false
      populate:    ['applet']
      target:      'userApplet'
    }
    validateUserApplet
  )


module.exports = {
  usersAppletsRouter
}
