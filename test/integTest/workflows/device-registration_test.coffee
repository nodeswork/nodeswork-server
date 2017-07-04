_               = require 'underscore'

{ AgentSession
  clearDB }     = require '../resource-helper'


describe 'Device registration flow', ->

  userSession       = null
  user              = null
  device            = null
  deviceSession     = null

  before ->
    await clearDB()
    userSession       = new AgentSession

  describe '#prepare', ->

    it 'creates user and logins the user', ->
      user = await userSession.createUser suffix: '100'
      user = await userSession.loginUser user


  describe '#registor', ->

    it 'lets user create a device', ->
      device = await userSession.createDevice {}
      device.deviceToken.should.be.ok()

    it 'lets device to retrieve device info', ->
      deviceSession = new AgentSession {
        headers:
          'device-token': device.deviceToken
      }

      device = await deviceSession.getCurrentDevice()
      device.should.have.properties [
        'deviceId'
        'osType'
        'platform'
        'release'
        'user'
        'dev'
        'status'
        'name'
      ]
      device.should.not.have.properties [
        'deviceToken'
      ]
