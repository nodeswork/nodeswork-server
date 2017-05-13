_              = require 'underscore'
KoaRouter      = require 'koa-router'

{requireLogin} = require './middlewares'
{NpmApplet}    = require '../models'


exports.devRouter = devRouter = new KoaRouter prefix: '/dev'

devRouter.use requireLogin


devRouter.post '/applets', (ctx) ->

  switch ctx.request.body.appletType
    when 'NpmApplet'
      NpmApplet.create _.extend {}, ctx.request.body, {
        owner:    ctx.user
      }
    else
      ctx.response.status = 422
      ctx.body = message: 'Unkown or missing appletType.'


devRouter.post '/applets/:appletId', (ctx) ->


devRouter.get '/applets', (ctx) ->


devRouter.get '/applets/:appletId', (ctx) ->
