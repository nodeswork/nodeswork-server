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
        applet: applet._id
        config:
          appletConfig: applet.config._id
          devices: []
        user: loginUser._id
      }

    it 'creates successfully passin device', ->
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
        applet: applet._id
        config:
          appletConfig: applet.config._id
          devices: [
            device: device._id
          ]
        user: loginUser._id
      }
