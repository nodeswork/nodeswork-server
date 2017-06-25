# Device API accessed by device.

_                           = require 'underscore'
KoaRouter                   = require 'koa-router'

{ requireRoles, roles }     = require './middlewares/roles'

{
  overrideToQuery
  overrideToDoc
  expandDevice
}                           = require './middlewares'
{ Device
  Execution
  UserApplet }              = require '../models'
{ MINIMAL_DATA_LEVEL }      = require '../constants'


deviceApiRouter = new KoaRouter()

  .use requireRoles roles.DEVICE

  # .post '/users/:userId/applet/:appletId/execute', (ctx) -> {}

  .useModel Device, {

    prefix:            '/device-api'

    instanceProvider:  _.property 'device'

    binds:             [ 'applets', 'current' ]
  }

  .useModel UserApplet, {

    prefix:            '/device-api/usersApplets'

    idField:           'relationId'

    binds:             [ 'execute' ]
  }

  .useModel Execution, {

    prefix:            '/device-api/executions'

    idField:           'executionId'

    cruds:             [ 'update' ]

    pres:

      update:          [ overrideToQuery(src: 'device') ]
  }


module.exports = {
  deviceApiRouter
}
