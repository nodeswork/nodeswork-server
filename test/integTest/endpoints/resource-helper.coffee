{ USER_STATUS } = require '../../../src/api/constants'

clearDB = () ->
  { User } = require '../../../src/api/models'
  User.remove userType: 'EmailUser'


createUser = (agent, options={}) ->
  { suffix = '1'
    status = 'ACTIVE' } = options
  res = await agent
    .post '/api/v1/users/new'
    .send {
      userType: 'EmailUser'
      email:    "test-user+#{suffix}@gmail.com"
      password: '12345'
    }
    .expect 200

  { EmailUser } = require '../../../src/api/models'
  u = await EmailUser.findOne email: user.email
  u.status = status
  await u.save()
  res.body.status = status

  res.body


activeUser = (user) ->
  { EmailUser } = require '../../../src/api/models'

  u = await EmailUser.findOne email: user.email
  u.status = USER_STATUS.ACTIVE
  await u.save()
  u


module.exports = {
  activeUser
  clearDB
  createUser
}
