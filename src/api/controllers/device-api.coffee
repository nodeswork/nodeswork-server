# Device API accessed by device.

_                           = require 'underscore'
KoaRouter                   = require 'koa-router'

{ requireRoles, roles }     = require './middlewares/roles'

{
  overrideUserToQuery
  overrideUserToDoc
  expandDevice
}                           = require './middlewares'
{
  Device
  User
  UserApplet
}                           = require '../models'
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


module.exports = {
  deviceApiRouter
}
