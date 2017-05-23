_                           = require 'underscore'
KoaRouter                   = require 'koa-router'

{
  requireLogin
  overrideUserToQuery
  overrideUserToDoc
}                           = require './middlewares'
{
  Applet
  Device
  UserApplet
}                           = require '../models'
params                      = require './params'
{ParameterValidationError}  = require '../errors'


exports.usersAppletsRouter = usersAppletsRouter = new KoaRouter prefix: '/my-applets'


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

  .use requireLogin

  .get('/', overrideUserToQuery(), UserApplet.findMiddleware {
    populate: ['applet']
  })

  .get('/:relationId', overrideUserToQuery(), UserApplet.getMiddleware {
    field:    'relationId'
    populate: ['applet']
  })

  .post('/:relationId', overrideUserToQuery(), overrideUserToDoc()
    UserApplet.updateMiddleware {
      field:   'relationId'
      omits:   ['user', 'applet', 'errMsg']
      target:  'userApplet'
    }
    validateUserApplet
  )

  # Load applet and verify the permission.
  .post('/'
    params.body(
      applet: [
        params.isRequired
        params.populateFromModel Applet
      ]
      device: [
        params.populateFromModel Device
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
