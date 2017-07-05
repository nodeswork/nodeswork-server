_                              = require 'underscore'
KoaRouter                      = require 'koa-router'

{
  overrideUserToQuery
  overrideUserToDoc
  expandedInJSON
}                              = require './middlewares'
{ requireRoles, roles }        = require './middlewares/roles'
{ pop }                        = require '../models/plugins/data-levels'
{
  Applet
  Device
  UserApplet
}                              = require '../models'
{ params, rules }              = require './params'
{ ParameterValidationError }   = require '../errors'
{ MINIMAL_DATA_LEVEL }         = require '../constants'


validateUserApplet = (ctx, next) ->
  [userApplet, applet] = [ctx.userApplet, ctx.userApplet.applet]

  if userApplet.device? and !applet.containers.userDevice
    throw new ParameterValidationError 'Applet is not suitable for device.'

  unless applet.avaiableTo ctx.user
    throw new ParameterValidationError 'Applet is not available for you.'

  if !userApplet.device and applet.requireDevice
    throw new ParameterValidationError 'Applet requires device.'

  await next()


usersAppletsRouter = new KoaRouter()

  .prefix '/v1/my-applets'

  .use requireRoles roles.USER

  .useModel UserApplet, {

    virtualPrefix:     '/api/v1/my-applets'

    idField:           'relationId'

    cruds:             [ 'find', 'get', 'create' ]

    options:

      gets:

        populate:      [
          pop 'applet', MINIMAL_DATA_LEVEL
          pop 'device', MINIMAL_DATA_LEVEL
        ]

      create:

        fromExtend:  false

        populate:      [
          pop 'applet', MINIMAL_DATA_LEVEL
          pop 'device', MINIMAL_DATA_LEVEL
        ]

        target:      'userApplet'

    pres:

      create:          [
        params.body(
          applet: [
            rules.isRequired
            rules.populateFromModel Applet
          ]
          device: [
            rules.isRequired
            rules.populateFromModel Device, user: '@user'
          ]
        )

        overrideUserToDoc()
      ]

    posts:

      get:             [ expandedInJSON() ]

      create:          [ validateUserApplet ]

    binds:             [ 'run', 'restart' ]
  }

  # TODO: Move to expose
  .post('/:relationId', overrideUserToQuery(), overrideUserToDoc()
    UserApplet.updateMiddleware {
      field:     'relationId'
      omits:     ['user', 'applet', 'errMsg']
      target:    'userApplet'
      populate:  ['applet', 'device']
    }
    validateUserApplet
  )


module.exports = {
  usersAppletsRouter
}
