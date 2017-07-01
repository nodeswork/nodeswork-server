request         = require 'supertest'

{ app }         = require '../../../src/server'
models          = require '../../../src/api/models'

{ createUser
  createApplet
  createUserApplet
  clearDB
  loginUser }   = require './resource-helper'


describe 'applet execution flow', ->

  agent   = null
  user    = null
  applet  = null

  before ->
    await clearDB()
    agent       = request.agent app.server
    user        = await createUser agent, developer: true
    user        = await loginUser agent, user
    applet      = await createApplet agent
    userApplet  = await createUserApplet agent, user, applet

  it 'should have proper user', ->
    user._id.should.be.ok
    user.attributes.developer.should.be.true
