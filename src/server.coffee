Koa                   = require 'koa'
KoaRouter             = require 'koa-router'
KoaSocket             = require 'koa-socket'
Pug                   = require 'koa-pug'
bodyParser            = require 'koa-bodyparser'
coffeescript          = require 'coffeescript'
connectCoffeeScript   = require 'connect-coffee-script'
convert               = require 'koa-convert'
csrf                  = require 'koa-csrf'
error                 = require 'koa-error'
koaConnect            = require 'koa-connect'
lessMiddleware        = require 'less-middleware'
mongoose              = require 'mongoose'
mongooseStore         = require 'koa-session-mongoose'
session               = require 'koa-generic-session'
staticCache           = require 'koa-static-cache'

{registerModels}      = require './api/models'


do () ->
  mongoose.Promise = global.Promise
  dbURI            = 'localhost:27017/nodeswork-dev'

  await mongoose.connect dbURI

  registerModels mongoose

  api        = require './api'
  app        = new Koa
  device     = new KoaSocket namespace: 'device'

  app.keys   = ['my keys']

  pug        = new Pug {
    debug:       true
    noCache:     true
    viewPath:    './src/views'
    helperPath:  []
    app:         app
  }

  router = new KoaRouter

  router
    .use api.router.routes(), api.router.allowedMethods()
    .get /^\/($|accounts|applets|settings|explore|devices)(.*)/, (ctx) ->
      ctx.render 'index'
    .get /\/views\/(.*)\.html/, (ctx) ->
      ctx.render ctx.params[0]

  app
    .use error {
      engine: 'pug'
      template: './src/views/errors.pug'
    }
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
    .use koaConnect connectCoffeeScript {
      src:     __dirname + '/coffee'
      prefix:  '/js'
      dest:    './public/js'
      bare:    true
      compile: (str, options, coffeePath) ->
        coffeescript.compile str, options
    }
    .use koaConnect lessMiddleware __dirname + '/less', {
      preprocess:
        path:      (lessPath, req) -> lessPath.replace '/styles', ''
      dest:        './public'
    }
    .use staticCache './public', dynamic: true
    .use router.routes()
    .use router.allowedMethods()

  device.attach app

  device.on 'connection', (ctx) ->
    console.log 'join event fired.', ctx.socket.id

  device.on 'disconnect', (ctx, data) ->
    # console.log 'left', ctx.io.id
    console.log 'left.', ctx.socket.id

  app.listen 3000, ->
    console.log 'server is started.'
