_               = require 'underscore'
KoaRouter       = require 'koa-router'
{requireLogin}  = require './middlewares'
{SystemApplet}  = require '../models'


exports.systemRouter = systemRouter = new KoaRouter prefix: '/systems'


systemRouter

  .use requireLogin

  .get '/container-applet', (ctx) ->
    systemApplet = await SystemApplet.containerApplet()

    ctx.body = _.pick systemApplet.toObject(), [
      '_id', 'appletType', 'systemAppletType', 'prodToken'
    ]
