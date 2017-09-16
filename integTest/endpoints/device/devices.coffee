{ clearDB, AgentSession } = require '../../resource-helper'

describe 'endpoints - device devices', ->

  session   = new AgentSession()
  user      = {
    email:     'andy+nodeswork+test@nodeswork.com'
    password:  '123456'
    status:    'ACTIVE'
  }
  loginUser = null
  device    = null

  beforeEach ->
    await clearDB()
    loginUser = await session.createUserAndLogin(user)
    device    = await session.createDevice()

  it 'requires device token: 401', ->
    await session.agent
      .post '/v1/d/devices'
      .send {}
      .expect 401, {
        message: 'require device token'
        responseCode: 401
      }
    await session.agent
      .post '/v1/d/devices'
      .set 'device-token', 'wrong'
      .send {}
      .expect 401, {
        message: 'invalid device token'
        responseCode: 401
      }

  describe 'update device', ->

    it 'updates successfully through token: 200', ->
      resp = await session.agent
        .post '/v1/d/devices'
        .set 'device-token', device.token
        .send {
          installedApplets: [
            packageName: 'package'
            version: 'version'
          ]
        }
        .expect 200
      resp.body.installedApplets.should.have.length 1
      resp.body.installedApplets[0].should.have.properties {
        naType: 'npm'
        naVersion: '8.3.0'
        packageName: 'package'
        version: 'version'
      }
