_                      = require 'underscore'
KoaRouter              = require 'koa-router'

{
  fetchAccount
  requireLogin
  overrideUserToQuery
  overrideUserToDoc
}                      = require './middlewares'
{
  Account
  AccountCategory
}                      = require '../models'
errors                 = require '../errors'
{params, rules}        = require './params'


exports.accountRouter = accountRouter = new KoaRouter prefix: '/accounts'


accountRouter

  .use requireLogin

  .get '/', overrideUserToQuery(), Account.findMiddleware {
    populate: [ 'category' ]
  }

  .post('/',
    params.body {
      accountType:  rules.isRequired
      category:     rules.populateFromModel AccountCategory
    }
    overrideUserToDoc()
    Account.createMiddleware {
      omits: ['oAuthToken', 'oAuthTokenSecret', 'accessToken', 'accessTokenSecret']
    }
  )

  .get('/categories'
    AccountCategory.findMiddleware triggerNext: false, populate: ['implements']
  )

  .get('/categories/:categoryId'
    AccountCategory.getMiddleware field: 'categoryId', triggerNext: false
  )

  .get '/oauth/:provider/callback', (ctx) ->
    category        = await AccountCategory.findOne name: ctx.params.provider
    oAuthToken      = ctx.request.query.oauth_token
    oAuthVerifier   = ctx.request.query.oauth_verifier

    account         = await Account.findOne {
      user:        ctx.user
      oAuthToken:  oAuthToken
    }
      .populate 'category'

    ctx.body        = await account.verifyOAuth oAuthVerifier


  .get '/:accountId', Account.getMiddleware {
    field: 'accountId'
    populate: ['category']
  }

  .post('/:accountId/reset'
    fetchAccount
    (ctx) ->
      await ctx.account.reset?()
      ctx.body = await ctx.account.save()
  )

  .post('/:accountId/authorize'
    fetchAccount
    (ctx) ->
      try
        await ctx.account.authorize()
        ctx.body = await ctx.account.save()
      catch e
        switch e
          when errors.FUT_TWO_FACTOR_CODE_REQUIRED
            ctx.body = message: errors.FUT_TWO_FACTOR_CODE_REQUIRED
            ctx.response.status = 422
          else throw e
  )

  .post('/:accountId/two-factor-authorize'
    fetchAccount
    (ctx) ->
      try
        await ctx.account.twoFactorAuthorize {
          code: ctx.request.body.code
        }
        ctx.body = await ctx.account.save()
      catch e
        switch e
          when errors.FUT_TWO_FACTOR_FUNCTION_NOT_FOUND
            ctx.body = message: errors.FUT_TWO_FACTOR_FUNCTION_NOT_FOUND
            ctx.response.status = 422
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
