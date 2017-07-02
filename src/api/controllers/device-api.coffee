# Device API accessed by device.

_                           = require 'underscore'
KoaRouter                   = require 'koa-router'
{ NAMED
  NodesworkError }          = require 'nodeswork-utils'

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

  .prefix '/v1/device-api'

  .use requireRoles roles.DEVICE

  .useModel Device, {

    virtualPrefix:     '/api/v1/device-api'

    instanceProvider:  _.property 'device'

    binds:             [ 'applets', 'current' ]
  }

  .useModel UserApplet, {

    virtualPrefix:     '/api/v1/device-api'

    prefix:            '/usersApplets'

    idField:           'relationId'

    binds:             [ 'execute' ]
  }

  .useModel Execution, {

    virtualPrefix:     '/api/v1/device-api'

    prefix:            '/executions'

    idField:           'executionId'

    cruds:             [ 'update' ]

    pres:

      update:          [ overrideToQuery(src: 'device') ]
  }

  .useModel ExecutionAction, {

    virtualPrefix:     '/api/v1/device-api'

    prefix:            '/executions/:executionId/accounts/:accountId/actions'

    idField:           'actionId'

    cruds:             [ 'create' ]

    pres:

      create:          [

        overrideToQuery(src: 'device')

        Execution.getMiddleware {
          field:        'executionId'
          writeToBody:  false
          triggerNext:  true
          target:       'execution'
          populate:     [
            'userApplet'
          ]
        }

        clearOverrideQuery()

        Account.getMiddleware {
          field:        'accountId'
          writeToBody:  false
          triggerNext:  true
          target:       'account'
        }

        NAMED 'VerifyAccountPermission', (ctx, next) ->
          console.log ctx.execution
          unless ctx.execution.userApplet.hasAccount ctx.account
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
