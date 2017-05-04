Koa               = require 'koa'
KoaRouter         = require 'koa-router'
bodyParser        = require 'koa-bodyparser'
convert           = require 'koa-convert'
csrf              = require 'koa-csrf'
mongoose          = require 'mongoose'
mongooseStore     = require 'koa-session-mongoose'
session           = require 'koa-generic-session'

{registerModels}  = require './api/models'


do () ->
  mongoose.Promise = global.Promise
  dbURI            = 'localhost:27017/nodeswork-dev'

  await mongoose.connect dbURI

  registerModels mongoose

  api        = require './api'
  app        = new Koa

  app.keys = ['my keys']

  app
    # .use new csrf.default()  # ES6 style
    .use convert session store: mongooseStore.create {
      model:       'KoaSession'
      collection:  'sessions'
      expires:     60 * 60 * 24 * 7 # 1 week
    }
    .use bodyParser()
    .use api.router.routes()
    .use api.router.allowedMethods()

  app.listen 3000, ->
    console.log 'server is started.'
