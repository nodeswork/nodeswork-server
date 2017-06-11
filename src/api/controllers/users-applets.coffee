_                           = require 'underscore'
KoaRouter                   = require 'koa-router'

{
  overrideUserToQuery
  overrideUserToDoc
}                           = require './middlewares'
{ requireRoles, roles }     = require './middlewares/roles'
{
  Applet
  Device
  UserApplet
}                           = require '../models'
{params, rules}             = require './params'
{ParameterValidationError}  = require '../errors'
{deviceRpcClient}           = require '../sockets'


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

  .use requireRoles roles.USER

  .get('/', overrideUserToQuery(), UserApplet.findMiddleware {
    populate: ['applet', 'device']
  })

  .get('/:relationId', overrideUserToQuery(), UserApplet.getMiddleware {
    field:    'relationId'
    populate: ['applet', 'device']
  })

  .post('/:relationId', overrideUserToQuery(), overrideUserToDoc()
    UserApplet.updateMiddleware {
      field:     'relationId'
      omits:     ['user', 'applet', 'errMsg']
      target:    'userApplet'
      populate:  ['applet', 'device']
    }
    validateUserApplet
  )

  .post('/:relationId/run', overrideUserToQuery()
    UserApplet.getMiddleware {
      field:        'relationId'
      writeToBody:  false
      target:       'userApplet'
      populate:     ['device']
    }
    (ctx) ->
      unless ctx.userApplet.device?
        throw new ParameterValidationError "Applet is not running on device."


      rpc = deviceRpcClient.rpc ctx.userApplet.device.deviceToken

      unless rpc?
        throw new ParameterValidationError "Applet is not running on active device."

      try
        await rpc.run {
          appletId: ctx.userApplet.applet
          userId: ctx.user._id
        }
        ctx.userApplet.lastExecution = new Date
        await ctx.userApplet.save()
        ctx.body = await UserApplet.populate ctx.userApplet, 'device applet'
      catch e
        ctx.body = {
          status: 'error'
          error: e
        }
        ctx.response.status = 422
  )

  # Load applet and verify the permission.
  .post('/'
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
