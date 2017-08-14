IO                    = require 'socket.io'
Koa                   = require 'koa'
KoaRouter             = require 'koa-router'
Pug                   = require 'koa-pug'
bodyParser            = require 'koa-bodyparser'
coffeescript          = require 'coffeescript'
connectCoffeeScript   = require 'connect-coffee-script'
convert               = require 'koa-convert'
csrf                  = require 'koa-csrf'
error                 = require 'koa-error'
http                  = require 'http'
koaConnect            = require 'koa-connect'
lessMiddleware        = require 'less-middleware'
mongoose              = require 'mongoose'
mongooseStore         = require 'koa-session-mongoose'
session               = require 'koa-generic-session'
staticCache           = require 'koa-static-cache'
{ MongoDB }           = require 'winston-mongodb'
winston               = require 'winston'

nwLogger              = require '@nodeswork/logger'

config                = require '../config'

if config.env == 'test'
  # mongoose.set 'debug', true
  nwLogger.transports = [
    nwLogger.transport winston.transports.File, {
      filename: '/tmp/nodeswork-server-test-log'
      colorize: true
      json:     false
    }
  ]

{ registerModels }    = require './api/models'


app = new Koa

do () ->
  mongoose.Promise = global.Promise

  await mongoose.connect config.db, useMongoClient: true

  db               = mongoose.connections[0].db
  logCollection    = 'logs'

  nwLogger.transports.push nwLogger.transport winston.transports.MongoDB, {
    db:          db
    collection:  logCollection
  }
  # Log              = nwLogger.registerMongooseModel {
    # collections: logCollection
    # mongoose:    mongoose
    # modelName:   'Log'
  # }

  logger           = nwLogger.logger

  await registerModels mongoose

  api        = require './api'

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
    .get /^\/($|accounts|my-applets|preferences|explore|devices|messages|register|dev)(.*)/, (ctx) ->
      ctx.render 'index'
    .get /\/views\/(.*)\.html/, (ctx) ->
      ctx.render ctx.params[0]
    .get '/sstats', (ctx) ->
      ctx.body = {
        config
      }

  app
    .use error {
      engine: 'pug'
      template: './src/views/errors.pug'
    }
    # .use new csrf.default()  # ES6 style
    .use convert(session store: mongooseStore.create {
      model:       'KoaSession'
      collection:  'sessions'
      expires:     60 * 60 * 24 * 7 # 1 week
    })
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
    .use (ctx) ->
      logger.warn 'Uncatched request', {
        url:      ctx.request.url
        method:   ctx.request.method
        headers:  ctx.request.headers
      }

  server = http.Server app.callback()
  api.attachIO IO server

  server.listen config.port, ->
    logger.info "server is started at http://localhost:#{config.port}."
    app._ready = true
    app.server = server


app.isReady = () ->
  return app if app._ready

  new Promise (resolve, reject) ->
    check = () ->
      if app._ready
        clearInterval interval
        resolve app
    interval = setInterval check, 0


module.exports = {
  app: app
}
