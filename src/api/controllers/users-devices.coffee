# User's device management API.
_                           = require 'underscore'
KoaRouter                   = require 'koa-router'

{ NAMED }                   = require 'nodeswork-utils'

{
  overrideUserToQuery
  overrideUserToDoc
  expandDevice
}                           = require './middlewares'
{ requireRoles, roles }     = require './middlewares/roles'
{
  Device
  User
  UserApplet
}                           = require '../models'


userDeviceRouter = new KoaRouter()

  .prefix '/v1/my-devices'

  .use requireRoles roles.USER

  # TODO: consolidate with Device.expose()
  .post('/'
    overrideUserToDoc(),
    (ctx, next) ->
      device = await Device.findOne {
        user:      ctx.user
        deviceId:  ctx.request.body.deviceId
      }
      if device?
        device.user = ctx.user
        ctx.device = _.extend device, _.omit ctx.request.body, [
          '_id', 'createdAt', 'lastUpdateTime', 'user', 'deviceToken'
        ]
        await ctx.device.save()
      else
        await next()
      ctx.device.withFieldsToJSON 'deviceToken'
      ctx.body = ctx.device
    Device.createMiddleware fromExtend: false, target: 'device'
  )

  .post('/:deviceId'
    overrideUserToQuery()
    Device.updateMiddleware(
      field: 'deviceId'
      omits: ['user', 'deviceToken']
      triggerNext: true
    )
    (ctx) ->
      if ctx.params.deviceToken == null
        ctx.object.regenerateDeviceToken()
        ctx.object.withFieldsToJSON 'deviceToken'
  )

  .useModel Device, {

    virtualPrefix: '/api/v1/my-devices'

    idField: 'deviceId'

    cruds:   [ 'find', 'get' ]

    pres:
      get:   [ overrideUserToQuery() ]

    posts:
      get:   [ expandDevice() ]
  }


module.exports = {
  userDeviceRouter
}
