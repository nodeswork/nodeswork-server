_                                  = require 'underscore'
LRU                                = require 'lru-cache'
futapi                             = require 'fut-api'

{ NAMED }                          = require 'nodeswork-utils'

{
  Account
  FifaFutAccount
  Message
}                                  = require '../models'
{
  MESSAGE_ROOM_SOCKET
  STATE_CHANGE_TOPIC
}                                  = require '../constants'

FIFA_FUT_API_CLIENT = LRU {
  max: 100                      # max size
  maxAge: 1000 * 60 * 60 * 24   # 24 hours
}

fetchAccount = (ctx, next) ->
  try
    ctx.account = await Account.findOne {
      _id:   ctx.params.accountId
      user:  ctx.user
    }
      .populate 'category'
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

  try
    await next()
  catch e
    throw e
  finally
    switch
      when ctx.account instanceof FifaFutAccount
        cookieJar = JSON.stringify apiClient.getCookieJarJSON()
        if cookieJar != ctx.account.cookieJar
          ctx.account.cookieJar = cookieJar
          await ctx.account.save()


overrideToQuery = (options={}) ->
  { src, dst } = options
  dst         ?= src
  NAMED "overrideToQuery(#{src}->#{dst})", (ctx, next) ->
    ctx.overrides ?= {}
    ctx.overrides.query ?= {}
    ctx.overrides.query[dst] = ctx[src]
    await next()


overrideToDoc = (options={}) ->
  { src, dst } = options
  dst         ?= src
  NAMED "overrideToDoc(#{src}->#{dst})", (ctx, next) ->
    ctx.overrides ?= {}
    ctx.overrides.doc ?= {}
    ctx.overrides.doc[dst] = ctx[src]
    await next()


overrideUserToDoc = (fieldName='user') ->
  NAMED 'overrideUserToDoc', (ctx, next) ->
    ctx.overrides ?= {}
    ctx.overrides.doc ?= {}
    ctx.overrides.doc[fieldName] = ctx.user
    await next()


overrideUserToQuery = overrideUserToQuery = (fieldName='user') ->
  NAMED 'overrideUserToQuery', (ctx, next) ->
    ctx.overrides ?= {}
    ctx.overrides.query ?= {}
    ctx.overrides.query[fieldName] = ctx.user
    await next()


expandDevice = (field='object') ->
  NAMED 'expandDevice', (ctx) ->
    if _.isArray ctx[field]
      ctx[field] = await _.map ctx[field], (device) -> device.expandedInJSON()
    else ctx[field] = await ctx[field].expandedInJSON()


expandedInJSON = (field='object') ->
  NAMED 'expandedInJSON', (ctx) ->
    if _.isArray ctx[field]
      ctx[field] = await _.map ctx[field], (obj) -> obj.expandedInJSON()
    else ctx[field] = await ctx[field].expandedInJSON()


updateState = (ctx, next) ->
  await next()

  {io}      = require '../sockets'
  roomName  = "state::#{ctx.user._id}"
  state     = await fetchState ctx.user

  io.of(MESSAGE_ROOM_SOCKET).to(roomName).emit STATE_CHANGE_TOPIC, state


getState = (ctx, next) ->
  ctx.state = await fetchState ctx.user
  await next()


fetchState = (user) ->
  unread    = await Message.find({
    receiver: user
    views:    0
    priority:
      '$in':  [1, 2]
  }).count()

  message:
    unread: unread


module.exports = {
  expandDevice
  expandedInJSON
  fetchAccount
  getState
  overrideUserToDoc
  overrideUserToQuery
  overrideToQuery
  overrideToDoc
  updateState
}
