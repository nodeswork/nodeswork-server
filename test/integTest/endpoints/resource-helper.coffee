

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
  res.body


module.exports = {
  clearDB
  createUser
}
