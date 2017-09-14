_               = require 'underscore'
request         = require 'supertest'

{
  User,
  Device,
  Token,
  Applet,
  UserApplet,
}               = require '../dist/api/models'


clearDB = () ->
  await User.remove {}
  await Device.remove {}
  await Token.remove {}
  await Applet.remove {}
  await UserApplet.remove {}


class AgentSession

  constructor: (options={}) ->
    @agent    = request.agent 'http://localhost:3001'
    @headers  = options.headers ? {}

  createUser: ({email, password, status='UNVERIFIED'}) ->
    User.create({ email, password, status })

  createUserAndLogin: ({email, password, status='UNVERIFIED'}) ->
    user = await @createUser({email, password, status})
    resp = await @agent.post('/v1/u/user/login').send({
      email, password
    })
    resp.body

  createDevice: (doc={
    deviceType:        'UserDevice'
    containerVersion:  '1234'
    deviceIdentifier:  '1234'
    os:                'MacOS'
    osVersion:         '12345'
    token:             '1234'
  }) ->
    res = await @agent.post('/v1/u/devices').send(doc)
    res.body

  createApplet: (doc={
    name: 'applet name'
    config:
      packageName: 'package name'
      version: 'version'
  }) ->
    res = await @agent.post('/v1/u/applets').send(doc)
    res.body

  # createUserApplet: (user, applet, device, accounts) ->
    # res = await @agent
      # .post '/api/v1/my-applets'
      # .send {
        # applet: applet._id
        # device: device._id
        # accounts: _.map accounts, (act) -> act._id
      # }
      # .expect 200
    # res.body

  # createAccount: (doc={}) ->
    # res = await @agent
      # .post '/api/v1/accounts'
      # .send _.extend {
        # accountType: 'TwitterAccount'
      # }, doc
      # .expect 200
    # account = res.body
    # # Bypass the account validation.
    # { Account }    = require '../../src/api/models'
    # account        = await Account.findById account._id
    # account.status = 'ACTIVE'
    # account        = await account.save()
    # account

  # getAccountCategories: () ->
    # res = await @agent
      # .get '/api/v1/resources/account-categories'
      # .expect 200
    # res.body

  # executeUserApplet: (userApplet, doc) ->
    # res = await @agent
      # .post "/api/v1/device-api/userApplets/#{userApplet._id}/execute"
      # .set  @headers
      # .send doc
      # .expect 200
    # res.body

  # createUserAppletExecuteAction: (execution, account, doc) ->
    # res = await @agent
      # .post "/api/v1/device-api/executions/#{execution._id}/accounts/#{account._id}/actions"
      # .set  @headers
      # .send doc
      # .expect 200
    # res.body

  # updateUserAppletExecutionAction: (action, doc) ->
    # res = await @agent
      # .post "/api/v1/device-api/executions/#{action.execution}/accounts/#{action.account._id}/actions/#{action._id}"
      # .set  @headers
      # .send doc
      # .expect 200
    # res.body

  # updateExecuteUserApplet: (execution, doc) ->
    # res = await @agent
      # .post "/api/v1/device-api/executions/#{execution._id}"
      # .set  @headers
      # .send doc
      # .expect 200
    # res.body

  # getCurrentDevice: () ->
    # res = await @agent
      # .get  "/api/v1/device-api/current"
      # .set  @headers
      # .expect 200
    # res.body


module.exports = {
  clearDB
  AgentSession
}
