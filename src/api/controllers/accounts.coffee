_                      = require 'underscore'
KoaRouter              = require 'koa-router'

{
  fetchAccount
  requireLogin
  overrideUserToQuery
  overrideUserToDoc
}                      = require './middlewares'
{ Account }            = require '../models'
errors                 = require '../errors'


exports.accountRouter = accountRouter = new KoaRouter prefix: '/accounts'


accountRouter

  .use requireLogin

  .get '/', overrideUserToQuery(), Account.findMiddleware()

  .post '/', overrideUserToDoc(), Account.createMiddleware()

  .get '/:accountId', Account.getMiddleware field: 'accountId'

  .post('/:accountId/authorize'
    fetchAccount
    (ctx) ->
      try
        ctx.body = await ctx.account.authorize()
      catch e
        switch e
          when errors.FUT_TWO_FACTOR_CODE_REQUIRED
            ctx.body = message: errors.FUT_TWO_FACTOR_CODE_REQUIRED
          else throw e
  )

  .post('/:accountId/two-factor-authorize'
    fetchAccount
    (ctx) ->
      try
        ctx.body = await ctx.account.twoFactorAuthorize {
          code: ctx.request.body.code
        }
      catch e
        switch e
          when errors.FUT_TWO_FACTOR_FUNCTION_NOT_FOUND
            ctx.body = message: errors.FUT_TWO_FACTOR_FUNCTION_NOT_FOUND
          else throw e
  )

  .post('/:accountId/operate'
    fetchAccount
    (ctx) ->
      try
        ctx.body = await ctx.account.operate ctx.request.body
      catch e
        ctx.body = error: e.toString()
        ctx.response.status = 401
  )
