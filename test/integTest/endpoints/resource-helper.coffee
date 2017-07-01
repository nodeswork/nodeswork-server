{ USER_STATUS } = require '../../../src/api/constants'

PASSWORD = '12345'


clearDB = () ->
  { User
    Applet } = require '../../../src/api/models'
  await User.remove userType: 'EmailUser'
  await Applet.remove appletType: 'NpmApplet'


createUser = (agent, options={}) ->
  { suffix    = '1'
    developer = false
    status    = 'ACTIVE' } = options
  email = "test-user+#{suffix}@gmail.com"
  res = await agent
    .post '/api/v1/users/new'
    .send {
      userType: 'EmailUser'
      email:    email
      password: PASSWORD
    }
    .expect 200

  { EmailUser } = require '../../../src/api/models'
  u = await EmailUser.findOne email: email
  u.status                = status
  u.attributes.developer  = developer
  u = await u.save()
  res.body.status = status

  res.body


loginUser = (agent, user) ->
  res = await agent
    .post '/api/v1/users/login'
    .send {
      userType: 'EmailUser'
      email:    user.email
      password: PASSWORD
    }
    .expect 200
  res.body


activeUser = (user) ->
  { EmailUser } = require '../../../src/api/models'

  u = await EmailUser.findOne email: user.email
  u.status = USER_STATUS.ACTIVE
  await u.save()
  u


createApplet = (agent, options={}) ->
  res = await agent
    .post '/api/v1/dev/applets'
    .send {
      appletType:   'NpmApplet'
      name:         'Applet'
      version:      '0.0'
      packageName:  'package'
    }
    .expect 200
  res.body


createUserApplet = (agent, user, applet, device) ->
  res = await agent
    .post '/api/v1/my-applets'
    .send {
      applet: applet._id
      device: device._id
    }
    .expect {}
    .expect 500
  res.body


module.exports = {
  activeUser
  clearDB
  createUser
  loginUser
  createApplet
  createUserApplet
}
