Koa               = require 'koa'
KoaRouter         = require 'koa-router'
Pug               = require 'koa-pug'
bodyParser        = require 'koa-bodyparser'
convert           = require 'koa-convert'
csrf              = require 'koa-csrf'
mongoose          = require 'mongoose'
mongooseStore     = require 'koa-session-mongoose'
session           = require 'koa-generic-session'
staticCache       = require 'koa-static-cache'

{registerModels}  = require './api/models'


do () ->
  mongoose.Promise = global.Promise
  dbURI            = 'localhost:27017/nodeswork-dev'

  await mongoose.connect dbURI

  registerModels mongoose

  api        = require './api'
  app        = new Koa

  app.keys   = ['my keys']

  pug        = new Pug {
    viewPath:    './src/views'
    helperPath:  []
    app:         app
  }

  router = new KoaRouter

  router
    .use api.router.routes(), api.router.allowedMethods()
    .get '/', (ctx) ->
      ctx.render 'index'

  app
    # .use new csrf.default()  # ES6 style
    .use convert session store: mongooseStore.create {
      model:       'KoaSession'
      collection:  'sessions'
      expires:     60 * 60 * 24 * 7 # 1 week
    }
    .use bodyParser()
    .use staticCache './bower_components', {
      prefix:   '/bower_components'
      maxAge:   3600
      dynamic:  true
    }
    .use router.routes()
    .use router.allowedMethods()

  app.listen 3000, ->
    console.log 'server is started.'
