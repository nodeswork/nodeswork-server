{ clearDB, AgentSession } = require '../../resource-helper'

describe 'endpoints - user applets', ->

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
      .post '/v1/u/applets'
      .send {}
      .expect 401


  describe 'create applet', ->

    loginUser = null

    beforeEach ->
      loginUser = await session.createUserAndLogin(user)

    it 'misses name: 422', ->
      await session.agent
        .post '/v1/u/applets'
        .send {}
        .expect 422, {
          errors:
            name: { kind: 'required', path: 'name' }
            configHistories: { kind: "config is required",path: "configHistories"}
          responseCode: 422
          message: 'invalid value'
        }

    it 'misses config details: 422', ->
      await session.agent
        .post '/v1/u/applets'
        .send {
          name: 'applet name'
          config: {}
        }
        .expect 422, {
          errors:
            "configHistories.0.packageName":
              kind: 'required', path: 'packageName'
            "configHistories.0.version":
              kind: 'required', path: 'version'
          responseCode: 422
          message: 'invalid value'
        }

    it 'creates successfully: 200', ->
      resp = await session.agent
        .post '/v1/u/applets'
        .send {
          name: 'applet name'
          config:
            packageName: 'package name'
            version: 'version'
        }
        .expect 200

      resp.body.should.have.properties {
        name: 'applet name',
        owner: loginUser._id.toString()
        imageUrl: 'http://www.nodeswork.com/favicon.ico'
        permission: 'PRIVATE'
      }
      resp.body.configHistories.should.have.length 1
      resp.body.configHistories[0].should.have.properties {
        packageName: 'package name'
        version: 'version'
        na: 'npm'
        naVersion: '8.3.0'
        workers: []
      }
      resp.body.tokens.should.have.properties [ 'devToken', 'prodToken' ]
      resp.body.config.should.have.properties {
        packageName: 'package name'
        version: 'version'
        na: 'npm'
        naVersion: '8.3.0'
        workers: []
      }

  describe 'update applet', ->

    loginUser = null
    applet = null

    beforeEach ->
      loginUser = await session.createUserAndLogin(user)
      resp = await session.agent
        .post '/v1/u/applets'
        .send {
          name: 'applet name'
          config:
            packageName: 'package name'
            version: '0.0.1'
        }
        .expect 200
      applet = resp.body

    # it 'updates a newer version', ->
      # resp = await session.agent
        # .post "/v1/u/applets/#{applet._id}"
        # .send {
          # config:
            # packageName: 'package name'
            # version: '0.0.3'
        # }
        # .expect 200

      # resp.body.should.have.properties {
        # name: 'applet name',
        # owner: loginUser._id.toString()
        # imageUrl: 'http://www.nodeswork.com/favicon.ico'
        # permission: 'PRIVATE'
      # }
      # resp.body.configHistories.should.have.length 1
      # resp.body.configHistories[0].should.have.properties {
        # packageName: 'package name'
        # version: '0.0.1'
        # na: 'npm'
        # naVersion: '8.3.0'
        # workers: []
      # }
      # resp.body.tokens.should.have.properties [ 'devToken', 'prodToken' ]
      # resp.body.config.should.have.properties {
        # packageName: 'package name'
        # version: '0.0.3'
        # na: 'npm'
        # naVersion: '8.3.0'
        # workers: []
      # }
