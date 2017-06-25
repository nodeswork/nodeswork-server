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

  # # Start an execution.
  # .post '/usersApplets/:relationId/execute', (ctx) -> {}

  # .post '/users/:userId/applet/:appletId/execute', (ctx) -> {}


Device.expose deviceApiRouter, {

  prefix:            '/device-api'

  instanceProvider:  _.property 'device'

  binds:             [ 'applets', 'current' ]
}


UserApplet.expose deviceApiRouter, {

  prefix:            '/device-api/usersApplets'

  idField:           'relationId'

  binds:             [ 'execute' ]

}


Execution.expose deviceApiRouter, {

  prefix:            '/device-api/executions'

  idField:           'executionId'

  cruds:             [ 'update' ]

  pres:

    update:          [ overrideToQuery(src: 'device') ]
}


module.exports = {
  deviceApiRouter
}
