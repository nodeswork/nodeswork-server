{ clearDB, AgentSession } = require '../../resource-helper'

describe 'endpoints - user devices', ->

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
      .post '/v1/u/devices'
      .send {}
      .expect 401


  describe 'create device', ->

    loginUser = null

    beforeEach ->
      loginUser = await session.createUserAndLogin(user)

    it 'misses device type: 422', ->
      await session.agent
        .post '/v1/u/devices'
        .send {}
        .expect 422, {
          message:       'required field is missing'
          path:          'deviceType'
          responseCode:  422
        }

    it 'sends wrong device type: 422', ->
      await session.agent
        .post '/v1/u/devices'
        .send {
          deviceType: 'unkown'
        }
        .expect 422, {
          message:       'invalid value'
          path:          'deviceType'
          responseCode:  422
        }

    it 'misses required fields: 422', ->
      await session.agent
        .post '/v1/u/devices'
        .send {
          deviceType: 'UserDevice'
        }
        .expect 422, {
           errors: {
             containerVersion: {
               kind: 'required'
               path: 'containerVersion'
             }
             deviceIdentifier: {
               kind: 'required'
               path: 'deviceIdentifier'
             }
             os: {
               kind: 'required'
               path: 'os'
             }
             osVersion: {
               kind: 'required'
               path: 'osVersion'
             }
           }
          message:       'invalid value'
          responseCode:  422
        }

    it 'creates device: 200', ->
      resp = await session.agent
        .post '/v1/u/devices'
        .send {
          deviceType:        'UserDevice'
          containerVersion:  '1234'
          deviceIdentifier:  '1234'
          os:                'MacOS'
          osVersion:         '12345'
          token:             '1234'
        }
        .expect 200

      resp.body.should.have.properties {
        deviceType:        'UserDevice',
        containerVersion:  '1234',
        deviceIdentifier:  '1234',
        os:                'MacOS',
        osVersion:         '12345',
        user:              loginUser._id.toString(),
        dev:               false,
        name:              'My Device',
      }

      resp.body.token.should.not.be.equal '1234'

    it 'updates existing device: 200', ->
      resp = await session.agent
        .post '/v1/u/devices'
        .send {
          deviceType:        'UserDevice'
          containerVersion:  '1234'
          deviceIdentifier:  '1234'
          os:                'MacOS'
          osVersion:         '12345'
          token:             '1234'
        }
        .expect 200

      resp2 = await session.agent
        .post '/v1/u/devices'
        .send {
          deviceType:        'UserDevice'
          containerVersion:  '1235'
          deviceIdentifier:  '1234'
          os:                'MacOS'
          osVersion:         '12345'
          token:             '1234'
        }
        .expect 200

      resp2.body._id.should.be.equal resp.body._id
      resp2.body.containerVersion.should.be.equal '1235'
