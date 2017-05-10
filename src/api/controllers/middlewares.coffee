LRU                                = require 'lru-cache'
futapi                             = require 'fut-api'

{Account, FifaFutAccount}          = require '../models'

exports.requireLogin = (ctx, next) ->
  unless ctx.user?._id? then ctx.response.status = 401
  else await next()


FIFA_FUT_API_CLIENT = LRU {
  max: 100                      # max size
  maxAge: 1000 * 60 * 60 * 24   # 24 hours
}

exports.fetchAccount = (ctx, next) ->
  try
    ctx.account = await Account.findById ctx.params.accountId
  catch
    ctx.response.status = 401
    return

  switch
    when ctx.account instanceof FifaFutAccount
      apiClient = FIFA_FUT_API_CLIENT.get ctx.account._id.toString()
      unless apiClient?
        FIFA_FUT_API_CLIENT.set(
          ctx.account._id.toString(),
          apiClient = new futapi
        )
        if ctx.account.cookieJar?
          apiClient.setCookieJarJSON JSON.parse ctx.account.cookieJar
      ctx.account.setApiClient apiClient

  await next()

  switch
    when ctx.account instanceof FifaFutAccount
      cookieJar = JSON.stringify apiClient.getCookieJarJSON()
      if cookieJar != ctx.account.cookieJar
        ctx.account.cookieJar = cookieJar
        await ctx.account.save()
