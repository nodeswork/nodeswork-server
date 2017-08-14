# Device API accessed by device.

_                           = require 'underscore'
KoaRouter                   = require 'koa-router'

{ NAMED
  NodesworkError }          = require '@nodeswork/utils'

{ requireRoles, roles }     = require './middlewares/roles'

{ clearOverrideQuery
  overrideToQuery
  overrideToDoc
  expandDevice }            = require './middlewares'
{ params
  rules }                   = require './params'

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

    prefix:            '/userApplets'

    idField:           'relationId'

    binds:             [ 'execute' ]
  }

  .useModel Execution, {

    virtualPrefix:     '/api/v1/device-api'

    prefix:            '/executions'

    idField:           'executionId'

    cruds:             [ 'update' ]

    options:

      update:          [

        params.body    {

          status:      [

            rules.isRequired

            rules.notEquals 'IN_PROGRESS', {
              message: 'Execution is already finished.'
            }
          ]
        }

        overrideToQuery(src: 'device')
      ]
  }

  .useModel ExecutionAction, {

    virtualPrefix:     '/api/v1/device-api'

    prefix:            '/executions/:executionId/accounts/:accountId/actions'

    idField:           'actionId'

    cruds:             [ 'create', 'update' ]

    middlewares:

      create:          [

        params.body    {
          action:      [ rules.isRequired ]
        }

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
          unless ctx.execution.userApplet.hasAccount ctx.account
            throw new NodesworkError "No permission to account.", {
              responseCode: 402
            }
          action        = ctx.request.body.action
          actionFn      = ctx.account[action]
          ctx.apiLevel  = switch
            when actionFn?.method == 'GET'  then 'READ'
            when actionFn?.method == 'POST' then 'WRITE'
            else null

          unless ctx.apiLevel?
            throw new NodesworkError 'Action does not exist.', {
              responseCode: 405
              action: action
            }

          await next()

        NAMED 'PrepareOverrideDoc', (ctx, next) ->
          ctx.overrides     ?= {}
          ctx.overrides.doc ?= {}
          _.extend ctx.overrides.doc, {
            user:        ctx.execution.user
            applet:      ctx.execution.applet
            userApplet:  ctx.execution.userApplet._id
            device:      ctx.device._id
            execution:   ctx.execution._id
            account:     ctx.account._id
          }
          await next()
          ctx.body = _.extend ctx.action.toJSON(), {
            # TODO: Implmennt toJSON with $level.
            account: ctx.account.toJSON $level: 'TOKEN'
          }

        {
          fromExtend:   false
          triggerNext:  true
          target:       'action'
          writeToBody:  false
        }

        (ctx) ->
          ctx.action.apiLevel = ctx.apiLevel
      ]

      update:          [

        params.body    {

          status:      [

            rules.isRequired

            rules.notEquals 'IN_PROGRESS', {
              message: 'Action is already finished.'
            }
          ]
        }

        overrideToQuery src: 'device'

        Execution.getMiddleware {
          field:        'executionId'
          writeToBody:  false
          triggerNext:  true
          target:       'execution'
        }

        overrideToQuery(
          { src: 'execution' }
          { from: 'params', src: 'accountId', dst: 'account' }
        )

        NAMED 'VerifyModelNotComplete', (ctx, next) ->
          unless ctx.execution.status == 'IN_PROGRESS'
            throw new NodesworkError 'Execution is already finished.'
          await next()

        { target: 'action' }
      ]
  }


module.exports = {
  deviceApiRouter
}
