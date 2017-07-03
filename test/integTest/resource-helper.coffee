_               = require 'underscore'
request         = require 'supertest'

{ USER_STATUS } = require '../../src/api/constants'
{ app }         = require '../../src/server'

PASSWORD = '12345'


clearDB = () ->
  { User
    Account
    Device
    UserApplet
    Execution
    ExecutionAction
    Applet } = require '../../src/api/models'
  await Account.remove {}
  await Device.remove {}
  await User.remove userType: 'EmailUser'
  await Applet.remove appletType: 'NpmApplet'
  await UserApplet.remove {}
  await Execution.remove {}
  await ExecutionAction.remove {}


class AgentSession

  constructor: (options={}) ->
    @agent    = request.agent app.server
    @headers  = options.headers ? {}

  createUser: (options={}) ->
    { suffix    = '1'
      developer = false
      status    = 'ACTIVE' } = options
    email = "test-user+#{suffix}@gmail.com"
    res = await @agent
      .post '/api/v1/users/new'
      .send {
        userType: 'EmailUser'
        email:    email
        password: PASSWORD
      }
      .expect 200

    # Bypass the user email validation and developer setup.
    { EmailUser } = require '../../src/api/models'
    u = await EmailUser.findOne email: email
    u.status                = status
    u.attributes.developer  = developer
    u = await u.save()
    res.body.status = status

    res.body

  loginUser: (user) ->
    res = await @agent
      .post '/api/v1/users/login'
      .send {
        userType: 'EmailUser'
        email:    user.email
        password: PASSWORD
      }
      .expect 200
    res.body

  createApplet: (doc={}) ->
    res = await @agent
      .post '/api/v1/dev/applets'
      .send _.extend {
        appletType:   'NpmApplet'
        name:         'Applet'
        version:      '0.0'
        packageName:  'package'
        containers:
          userDevice: true
      }, doc
      .expect 200
    res.body

  createDevice: (doc={}) ->
    res = await @agent
      .post '/api/v1/my-devices'
      .send _.extend {
        deviceId:   'deviceId'
        osType:     'Mac OS X'
        platform:   'platform'
        release:    'release'
      }, doc
      .expect 200
    res.body

  createUserApplet: (user, applet, device, accounts) ->
    res = await @agent
      .post '/api/v1/my-applets'
      .send {
        applet: applet._id
        device: device._id
        accounts: _.map accounts, (act) -> act._id
      }
      .expect 200
    res.body

  createAccount: (doc={}) ->
    res = await @agent
      .post '/api/v1/accounts'
      .send _.extend {
        accountType: 'TwitterAccount'
      }, doc
      .expect 200
    account = res.body
    # Bypass the account validation.
    { Account }    = require '../../src/api/models'
    account        = await Account.findById account._id
    account.status = 'ACTIVE'
    account        = await account.save()
    account

  getAccountCategories: () ->
    res = await @agent
      .get '/api/v1/resources/account-categories'
      .expect 200
    res.body

  executeUserApplet: (userApplet) ->
    res = await @agent
      .post "/api/v1/device-api/usersApplets/#{userApplet._id}/execute"
      .set  @headers
      .send { }
      .expect 200
    res.body

  createUserAppletExecuteAction: (execution, account, doc) ->
    res = await @agent
      .post "/api/v1/device-api/executions/#{execution._id}/accounts/#{account._id}/actions"
      .set  @headers
      .send doc
      .expect 200
    res.body

  updateUserAppletExecutionAction: (action, doc) ->
    res = await @agent
      .post "/api/v1/device-api/executions/#{action.execution}/accounts/#{action.account._id}/actions/#{action._id}"
      .set  @headers
      .send doc
      .expect 200
    res.body


activeUser = (user) ->
  { EmailUser } = require '../../src/api/models'

  u = await EmailUser.findOne email: user.email
  u.status = USER_STATUS.ACTIVE
  await u.save()
  u


module.exports = {
  activeUser
  clearDB
  AgentSession
}
