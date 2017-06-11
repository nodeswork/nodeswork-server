_                           = require 'underscore'
KoaRouter                   = require 'koa-router'

{fetchAccount}              = require './middlewares'
{requireRoles, roles}       = require './middlewares/roles'
{
  Account
  Applet
  AppletMessage
  AppletExecution
  Device
  Message
  User
  UserApplet
}                           = require '../models'
{ParameterValidationError}  = require '../errors'


exports.appletApiRouter = appletApiRouter = new KoaRouter {
  prefix: '/applet-api/:appletId/users/:userId'
}

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
  console.log 'fetching UUUUUUUUUUUUUUUUU'
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

  .use requireRoles roles.DEVICE

  .all /./, fetchApplet, fetchUser

  # Returns include: 1) user; 2) user's applet relationship; 3) applet.
  .get '/', (ctx) ->
    console.log 'FFFFFFFFFFFFFFFFFFFFF', ctx.user, ctx.userApplet, ctx.applet
    ctx.body = {
      user:        ctx.user
      userApplet:  ctx.userApplet
      applet:      ctx.applet
    }

  .post('/accounts/:accountId/operate'
    fetchAccount
    (ctx) ->
  )

  .post('/messages'
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

  .post('/executions'
    (ctx, next) ->
      ctx.overrides = {
        doc:
          user:         ctx.user._id
          device:       ctx.device?._id
      }
      await next()
    AppletExecution.createMiddleware fromExtend: false
  )

  .post('/executions/:executionId'
    (ctx, next) ->
      ctx.overrides = {
        query:
          _id:          ctx.params.executionId
          user:         ctx.user._id
          device:       ctx.device?._id
      }
      await next()
    AppletExecution.updateMiddleware {
      field: 'executionId'
      omits: ['user', 'applet', 'device']
    }
  )
