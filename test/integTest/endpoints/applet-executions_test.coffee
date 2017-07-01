request         = require 'supertest'

{ app }         = require '../../../src/server'
models          = require '../../../src/api/models'

{ createUser
  clearDB }     = require './resource-helper'


describe 'applet execution flow', ->

  agent = null
  user  = null

  before ->
    await clearDB()
    agent = request.agent app.server
    user  = await createUser agent
