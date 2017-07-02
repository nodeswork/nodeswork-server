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
