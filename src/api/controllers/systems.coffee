_                            = require 'underscore'
KoaRouter                    = require 'koa-router'

{ requireRoles, roles }      = require './middlewares/roles'
{ SystemApplet }             = require '../models'


exports.systemRouter = systemRouter = new KoaRouter prefix: '/v1/systems'


# TODO: Change to resources.
systemRouter

  .use requireRoles roles.USER

  .get '/container-applet', (ctx) ->
    systemApplet = await SystemApplet.containerApplet()

    ctx.body = _.pick systemApplet.toObject(), [
      '_id', 'appletType', 'systemAppletType', 'prodToken'
    ]
