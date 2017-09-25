_                         = require 'underscore'
{ clearDB, AgentSession } = require '../../resource-helper'

describe 'endpoints - user user applets', ->

  session = new AgentSession()

  user    = {
    email:     'andy+nodeswork+test@nodeswork.com'
    password:  '123456'
    status:    'ACTIVE'
  }

  beforeEach ->
    await clearDB()

  it 'requires user login: 401', ->
    await session.agent
      .post '/v1/u/my-applets'
      .send {}
      .expect 401


  describe 'create user applet', ->

    loginUser  = null
    device     = null
    applet     = null

    beforeEach ->
      loginUser  = await session.createUserAndLogin(user)
      device     = await session.createDevice()
      applet     = await session.createApplet()

    it 'misses required fields: 422', ->
      await session.agent
        .post '/v1/u/my-applets'
        .send {}
        .expect 422, {
          errors: {
            applet: {
                kind: "required"
                path: "applet"
              }
            config: {
                kind: "required"
                path: "config"
              }
          }
          message: 'invalid value'
          responseCode:  422
        }

    it 'misses config.appletConfig: 422', ->
      await session.agent
        .post '/v1/u/my-applets'
        .send {
          applet: applet._id,
          config: {}
        }
        .expect 422, {
          errors:
            config: {}
            'config.appletConfig':
              kind: 'required'
              path: 'appletConfig'
          message: 'invalid value'
          responseCode: 422
        }

    it 'creates successfully', ->
      resp = await session.agent
        .post '/v1/u/my-applets'
        .send {
          applet: applet._id
          config: {
            appletConfig: applet.config._id
          }
        }
        .expect 200
      resp.body.should.have.properties {
        config:
          appletConfig: applet.config
          devices: []
          upToDate: true
          accounts: []
        user: loginUser._id
      }
      resp.body.applet.should.be.deepEqual _.omit(applet, '__v', 'tokens')

    it 'creates successfully pass-in device', ->
      resp = await session.agent
        .post '/v1/u/my-applets'
        .send {
          applet: applet._id
          config: {
            appletConfig: applet.config._id
            devices: [
              device: device._id
            ]
          }
        }
        .expect 200
      resp.body.should.have.properties {
        config:
          appletConfig: applet.config
          devices: [
            device: device._id
          ]
          accounts: []
          upToDate: true
        user: loginUser._id
      }
      resp.body.applet.should.be.deepEqual _.omit(applet, '__v', 'tokens')

  describe 'find user applets', ->

    loginUser  = null
    device     = null
    applet     = null

    beforeEach ->
      loginUser  = await session.createUserAndLogin(user)
      device     = await session.createDevice()
      applet     = await session.createApplet()

    it 'returns nested applet', ->
      userApplet = (await session.agent
        .post '/v1/u/my-applets'
        .send {
          applet: applet._id
          config: {
            appletConfig: applet.config._id
          }
        }
        .expect 200
      ).body

      resp = await session.agent
        .get '/v1/u/my-applets'
        .expect 200
      resp.body.should.have.length 1
      resp.body[0].applet.should.be.deepEqual _.omit(applet, '__v', 'tokens')
