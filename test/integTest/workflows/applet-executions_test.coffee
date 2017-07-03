_               = require 'underscore'

{ AgentSession
  clearDB }     = require '../resource-helper'


describe 'Device applet execution flow', ->

  userSession       = null
  developerSession  = null

  user              = null
  account           = null
  categories        = null
  twitterCategory   = null
  developer         = null
  device            = null
  agent             = null
  applet            = null
  userApplet        = null

  before ->
    await clearDB()
    userSession       = new AgentSession
    developerSession  = new AgentSession

  describe '#prepare', ->

    it 'creates user and logins the user', ->
      user = await userSession.createUser suffix: '100'
      user = await userSession.loginUser user

    it 'creates developer and logins the developer', ->
      developer = await developerSession.createUser developer: true
      developer = await developerSession.loginUser developer

    it 'lets developer create an applet', ->
      applet = await developerSession.createApplet permission: 'PUBLIC'

    it 'lets user create a device', ->
      device = await userSession.createDevice {}
      device.deviceToken.should.be.ok()

    it 'lets user to fetch all categories', ->
      categories       = await userSession.getAccountCategories()
      twitterCategory  = _.find categories, (x) -> x.name == 'Twitter'
      twitterCategory.should.be.ok()

    it 'lets user create an account', ->
      account = await userSession.createAccount {
        accountType:  'TwitterAccount'
        category:     twitterCategory._id
        name:         'My Twitter Account'
      }
      account.should.be.ok()

    it 'lets user install the applet', ->
      userApplet = await userSession.createUserApplet(
        user, applet, device, [account]
      )
      userApplet.should.be.ok()


  deviceSession = null
  execution     = null
  action        = null

  describe '#execute', ->

    before ->
      deviceSession = new AgentSession {
        headers:
          'device-token': device.deviceToken
      }

    it 'lets device to create an execution', ->
      execution = await deviceSession.executeUserApplet userApplet

      execution.should.be.ok()
      execution.userApplet._id.should.be.deepEqual userApplet._id

      execution.userApplet.accounts.should.have.length 1
      execution.userApplet.accounts[0]._id.should.be.ok()

    it 'lets device to create an action', ->
      action = await deviceSession.createUserAppletExecuteAction(
        execution, account, action: 'tweet', params: { oldParam: true }
      )
      action.should.be.ok()
      action.params.should.have.properties oldParam: true

    it 'lets device to update action status', ->
      action = await deviceSession.updateUserAppletExecutionAction(
        action,
        status:    'SUCCESS',
        params:    { newParam:  true }
        result:    { status:    'ok' }
        duration:  100
      )
      action.should.be.ok()
      action.status.should.be.equal 'SUCCESS'
      action.params.should.be.deepEqual oldParam: true
      action.duration.should.be.equal 100

    it 'lets device to update execution status', ->
