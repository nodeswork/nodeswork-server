_                                  = require 'underscore'
KoaRouter                          = require 'koa-router'

{requireLogin}                     = require './middlewares'
{Account, FifaFutAccount}          = require '../models'
errors                             = require '../errors'


exports.accountRouter = accountRouter = new KoaRouter prefix: '/accounts'


accountRouter.use requireLogin


accountRouter.get '/', (ctx) ->
  ctx.body = await Account.findByUser ctx.user


accountRouter.post '/', (ctx) ->
  switch ctx.request.body.accountType
    when 'FifaFutAccount'
      account = await FifaFutAccount.register _.extend {
        user:   ctx.user
      }, _.pick ctx.request.body, 'username', 'platform', 'password', 'secret'
      ctx.body = account
    else
      ctx.response.status = 422
      ctx.body = message: 'Unkown or missing accountType.'


fetchAccount = (ctx, next) ->
  try
    ctx.account = await Account.findById ctx.params.accountId
  catch
    ctx.response.status = 401
    return

  await next()


accountRouter.get '/:accountId', fetchAccount, (ctx) ->
  ctx.body = ctx.account


accountRouter.post '/:accountId/authorize', fetchAccount, (ctx) ->
  try
    ctx.body = await ctx.account.authorize()
  catch e
    switch e
      when errors.FUT_TWO_FACTOR_CODE_REQUIRED
        ctx.body = message: errors.FUT_TWO_FACTOR_CODE_REQUIRED
      else throw e


accountRouter.post '/:accountId/two-factor-authorize', fetchAccount, (ctx) ->
  try
    ctx.body = await ctx.account.twoFactorAuthorize code: ctx.request.body.code
  catch e
    switch e
      when errors.FUT_TWO_FACTOR_FUNCTION_NOT_FOUND
        ctx.body = message: errors.FUT_TWO_FACTOR_FUNCTION_NOT_FOUND
      else throw e
