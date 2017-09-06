{ clearDB, AgentSession } = require '../../resource-helper'

{ Token }                 = require '../../../dist/api/models/models'

describe 'endpoints - user auth', ->

  beforeEach ->
    await clearDB()

  session = new AgentSession()

  user = {
    email:     'andy+nodeswork+test@nodeswork.com'
    password:  '123456'
  }
  activeUser = {
    email:     'andy+nodeswork+test@nodeswork.com'
    password:  '123456'
    status:    'ACTIVE'
  }

  describe 'register', ->

    it 'failes without email or password', ->
      await session.agent
        .post '/v1/u/user/register'
        .expect 422, {
          message:       'invalid value'
          responseCode:  422
          errors:
            email:
              kind: 'required'
              path: 'email'
            password:
              kind: 'required'
              path: 'password'
        }

    it 'failes with invalid email', ->
      await session.agent
        .post '/v1/u/user/register'
        .send {
          email:     'notalivademail'
          password:  'pp'
        }
        .expect 422, {
          message:       'invalid value'
          responseCode:  422
          errors:
            email:
              kind: 'invalid email address'
              path: 'email'
        }

    it 'failes with invalid password', ->
      await session.agent
        .post '/v1/u/user/register'
        .send {
          email:     'valid@email.com'
          password:  'pp'
        }
        .expect 422, {
          message:       'invalid value'
          responseCode:  422
          errors:
            password:
              kind: 'password should contain at least 6 characters'
              path: 'password'
        }

    it 'succeeds with valid email and password', ->
      await session.agent
        .post '/v1/u/user/register'
        .send {
          email:     'andy+nodeswork+test@nodeswork.com'
          password:  '123456'
        }
        .expect 200, {
          message: 'A verification email has been sent to your registered email address'
          status: 'ok'
        }

    it 'fails with duplicate email', ->
      await session.agent
        .post '/v1/u/user/register'
        .send {
          email:     'andy+nodeswork+test@nodeswork.com'
          password:  '123456'
        }
        .expect 200, {
          message: 'A verification email has been sent to your registered email address'
          status: 'ok'
        }

      await session.agent
        .post '/v1/u/user/register'
        .send {
          email:     'andy+nodeswork+test@nodeswork.com'
          password:  '123456'
        }
        .expect 422, {
          message: 'duplicate record'
          responseCode:  422
        }

  describe 'verifyEmailAddress', ->

    it 'verified email address successfully', ->
      await session.agent
        .post '/v1/u/user/register'
        .send {
          email:     'andy+nodeswork+test@nodeswork.com'
          password:  '123456'
        }
        .expect 200, {
          message: 'A verification email has been sent to your registered email address'
          status: 'ok'
        }
      { token } = await Token.findOne({})
      await session.agent
        .post "/v1/u/user/verifyUserEmail"
        .send { token }
        .expect 204, {}

  describe 'login', ->

    it 'returns error when user not login', ->
      await session.agent
        .get '/v1/u/user'
        .expect 401, {
          responseCode: 401
          message: 'require login'
        }

    it 'login failed when user is not active', ->
      await session.createUser(user)
      await session.agent
        .post '/v1/u/user/login'
        .send user
        .expect 422, {
          responseCode: 422
          message: 'user is not active'
        }

    it 'login successully when user is active', ->
      await session.createUser(activeUser)

      resp = await session.agent
        .post '/v1/u/user/login'
        .send user
        .expect 200

      resp.body.should.have.properties ['_id', 'createdAt', 'lastUpdateTime']
      resp.body.should.have.properties { email: user.email }
      resp.body.should.not.have.properties ['password']

      resp = await session.agent
        .get '/v1/u/user'
        .expect 200

      resp.body.should.have.properties ['_id', 'createdAt', 'lastUpdateTime']
      resp.body.should.have.properties { email: user.email }
      resp.body.should.not.have.properties ['password']

  describe 'logout', ->

    it 'allow user logout', ->
      await session.createUser(activeUser)

      await session.agent
        .post '/v1/u/user/login'
        .send user
        .expect 200

      await session.agent
        .get '/v1/u/user'
        .expect 200

      await session.agent
        .get '/v1/u/user/logout'
        .expect 200

      await session.agent
        .get '/v1/u/user'
        .expect 401

  describe '#sendVerifyEmail', ->

    it 'require user to login', ->
      await session.createUser(user)

      await session.agent
        .post '/v1/u/user/sendVerifyEmail'
        .expect 401, {
          responseCode: 401
          message: 'require login'
        }

    it 'sends verify email', ->
      await session.createUserAndLogin(user)

      await session.agent
        .get '/v1/u/user'
        .expect 401, {
          responseCode: 401
          message: 'require login'
        }

      await session.agent
        .post '/v1/u/user/sendVerifyEmail'
        .expect 200, {
          message: 'A verification email has been sent to your registered email address'
          status: 'ok'
        }
