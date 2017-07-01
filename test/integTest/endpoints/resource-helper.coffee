{ USER_STATUS } = require '../../../src/api/constants'

PASSWORD = '12345'


clearDB = () ->
  { User } = require '../../../src/api/models'
  User.remove userType: 'EmailUser'


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
  # u.attributes = developer: developer
  console.log u
  u = await u.save()
  console.log u
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
    .send {}
    .expect 500, {}
  res.body


module.exports = {
  activeUser
  clearDB
  createUser
  loginUser
  createApplet
}
