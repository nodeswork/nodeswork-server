# Device API accessed by device.

_                           = require 'underscore'
KoaRouter                   = require 'koa-router'
{ NAMED }                   = require 'nodeswork-utils'

{ requireRoles, roles }     = require './middlewares/roles'

{ clearOverrideQuery
  overrideToQuery
  overrideToDoc
  expandDevice }            = require './middlewares'

{ Account
  Device
  Execution
  ExecutionAction
  UserApplet }              = require '../models'

{ MINIMAL_DATA_LEVEL }      = require '../constants'


deviceApiRouter = new KoaRouter()

  .use requireRoles roles.DEVICE

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

  .useModel ExecutionAction, {

    prefix:            '/device-api/executions/:executionId/accounts/:accountId/actions'

    idField:           'actionId'

    cruds:             [ 'create' ]

    pres:

      create:          [

        overrideToQuery(src: 'device')

        Execution.getMiddleware {
          field:        'executionId'
          writeToBody:  false
          target:       'execution'
        }

        clearOverrideQuery()

        Account.getMiddleware {
          field:        'accountId'
          writeToBody:  false
          target:       'account'
        }

        NAMED 'VerifyAccountPermission', (ctx, next) ->
          unless ctx.execution.hasAccount ctx.account
            throw new NodesworkError "No permission to account.", {
              responseCode: 402
            }
          await next()

        overrideToDoc(src: 'execution')

        overrideToDoc(src: 'account')

        NAMED 'PrepareOverrideDoc', (ctx, next) ->
          _.extend ctx.overrides, {
            user:        ctx.execution.user
            applet:      ctx.execution.applet
            userApplet:  ctx.execution.userApplet
            device:      ctx.device
          }
      ]

  }


module.exports = {
  deviceApiRouter
}
