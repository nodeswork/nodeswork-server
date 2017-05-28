_                           = require 'underscore'
KoaRouter                   = require 'koa-router'

{fetchAccount}              = require './middlewares'
{
  Account
  Applet
  AppletMessage
  Device
  Message
  User
  UserApplet
}                           = require '../models'
{ParameterValidationError}  = require '../errors'


exports.appletApiRouter = appletApiRouter = new KoaRouter {
  prefix: '/applet-api/:appletId'
}

fetchDevice = (ctx, next) ->
  deviceToken  = ctx.request.headers['device-token']
  unless deviceToken?
    throw new ParameterValidationError 'Device token is missing.'

  ctx.device   = await Device.findOne deviceToken: deviceToken

  unless ctx.device?
    throw new ParameterValidationError 'Device is not available.'

  await next()

# Fetch applet and verify applet token.
fetchApplet = (ctx, next) ->
  ctx.applet   = await Applet.findById ctx.params.appletId
  appletToken  = ctx.request.headers['applet-token']

  unless ctx.applet?
    throw new ParameterValidationError 'Applet is not avaliable.'

  switch
    when appletToken == ctx.applet.devToken
      ctx.appletDevMode = true
    when appletToken == ctx.applet.prodToken
      ctx.appletDevMode = false
    else
      throw new ParameterValidationError 'Applet is not authorized.', 401

  await next()

# Fetch user and verify user's authorization.
fetchUser = (ctx, next) ->
  ctx.user    = await User.findById ctx.params.userId

  unless ctx.params.userId.toString() == ctx.device.user.toString()
    throw new ParameterValidationError 'Device is not belong to user.'

  unless ctx.user?
    throw new ParameterValidationError "User doesn't exists."

  ctx.userApplet = await(
    UserApplet.findOne user: ctx.user, applet: ctx.applet
      .populate 'accounts device'
  )

  unless ctx.userApplet? or ctx.applet.appletType == 'SystemApplet'
    throw new ParameterValidationError "Applet is not installed for user."

  await ctx.userApplet?.validateStatus {
    applet:  ctx.applet
    user:    ctx.user
    device:  ctx.device
  }

  unless not ctx.userApplet? or ctx.userApplet.status == "ON"
    throw new ParameterValidationError "Applet is not active."

  await next()

# Fetch account and verify account status and authroization.
fetchAccount = (ctx, next) ->
  ctx.account = _.find ctx.userApplet.accounts, (account) ->
    account._id.toString() == ctx.params.accountId

  unless ctx.account?
    throw new ParameterValidationError "Account doesn't exist."

  await next()


appletApiRouter

  .use fetchDevice

  # Returns include: 1) user; 2) user's applet relationship; 3) applet.
  .get '/users/:userId', fetchApplet, fetchUser, (ctx) ->
    ctx.body = {
      user:        ctx.user
      userApplet:  ctx.userApplet
      applet:      ctx.applet
    }

  .post('/users/:userId/accounts/:accountId/operate'
    fetchApplet
    fetchUser
    fetchAccount
    (ctx) ->
  )

  .post('/users/:userId/messages'
    fetchApplet, fetchUser
    (ctx, next) ->
      ctx.overrides = {
        doc:
          receiver:     ctx.user._id
          sender:       ctx.applet._id
          via:          ctx.userApplet?._id
          messageType:  'AppletMessage'
      }
      await next()
    Message.createMiddleware()
  )
