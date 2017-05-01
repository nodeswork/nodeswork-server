Koa        = require 'koa'
KoaRouter  = require 'koa-router'

api        = require './api'

app        = new Koa

app
  .use api.router.routes()
  .use api.router.allowedMethods()


app.listen 3000, ->
  console.log 'API', api
