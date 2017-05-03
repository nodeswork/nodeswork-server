mongoose          = require 'mongoose'
Koa               = require 'koa'
KoaRouter         = require 'koa-router'
bodyParser        = require 'koa-bodyparser'

{registerModels}  = require './api/models'


do () ->
  mongoose.Promise = global.Promise
  dbURI            = 'localhost:27017/nodeswork-dev'

  await mongoose.connect dbURI

  registerModels mongoose

  api        = require './api'
  app        = new Koa

  app
    .use bodyParser()
    .use api.router.routes()
    .use api.router.allowedMethods()

  app.listen 3000, ->
    console.log 'server is started.'
