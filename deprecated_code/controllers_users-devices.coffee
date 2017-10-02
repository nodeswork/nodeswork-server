# User's device management API.
_                           = require 'underscore'
KoaRouter                   = require 'koa-router'

{ NAMED }                   = require '@nodeswork/utils'

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

  .useModel Device, {

    virtualPrefix:             '/api/v1/my-devices'

    idField:                   'deviceId'

    cruds:                     [ 'find', 'get', 'create' ]

    middlewares:

      gets:                    [

        overrideUserToQuery()

        {}

        expandDevice()
      ]

      create:                  [

        overrideUserToDoc()

        (ctx, next) ->
          # Find existing device
          device        = await Device.findOne {
            user:      ctx.user
            deviceId:  ctx.request.body.deviceId
          }
          if device?
            #TODO: Revisit here.
            ctx.device  = _.extend device, _.omit ctx.request.body, [
              '_id', 'createdAt', 'lastUpdateTime', 'user', 'deviceToken'
            ]
            await ctx.device.save()
          else
            await next()

          await ctx.device.ensureContainerApplet()

          ctx.device.withFieldsToJSON 'deviceToken'
          ctx.body = ctx.device

        {
          fromExtend: false
          target: 'device'
        }
      ]
  }


module.exports = {
  userDeviceRouter
}
