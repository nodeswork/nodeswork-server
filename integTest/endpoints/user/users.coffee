request         = require 'supertest'

{ clearDB, AgentSession } = require '../../resource-helper'

{ User, Token } = require '../../../dist/api/models/models'

describe 'user auth', ->

  beforeEach ->
    await clearDB()

  session = new AgentSession()

  agent = request.agent 'http://localhost:3001'

  describe 'register', ->

    it 'failes without email or password', ->
      await agent
        .post '/v1/u/user/register'
        .expect 422
        .expect {
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
      await agent
        .post '/v1/u/user/register'
        .send {
          email:     'notalivademail'
          password:  'pp'
        }
        .expect 422
        .expect {
          message:       'invalid value'
          responseCode:  422
          errors:
            email:
              kind: 'invalid email address'
              path: 'email'
        }

    it 'failes with invalid password', ->
      await agent
        .post '/v1/u/user/register'
        .send {
          email:     'valid@email.com'
          password:  'pp'
        }
        .expect 422
        .expect {
          message:       'invalid value'
          responseCode:  422
          errors:
            password:
              kind: 'password should contain at least 6 characters'
              path: 'password'
        }

    it 'succeeds with valid email and password', ->
      await agent
        .post '/v1/u/user/register'
        .send {
          email:     'andy+nodeswork+test@nodeswork.com'
          password:  '123456'
        }
        .expect 200
        .expect {
          message: 'A verification email has been sent to your registered email address'
          status: 'ok'
        }

    it 'fails with duplicate email', ->
      await agent
        .post '/v1/u/user/register'
        .send {
          email:     'andy+nodeswork+test@nodeswork.com'
          password:  '123456'
        }
        .expect 200
        .expect {
          message: 'A verification email has been sent to your registered email address'
          status: 'ok'
        }

      await agent
        .post '/v1/u/user/register'
        .send {
          email:     'andy+nodeswork+test@nodeswork.com'
          password:  '123456'
        }
        .expect 422
        .expect {
          message: 'duplicate record'
          responseCode:  422
        }

  describe 'verifyEmailAddress', ->

    it 'verified email address successfully', ->
      await agent
        .post '/v1/u/user/register'
        .send {
          email:     'andy+nodeswork+test@nodeswork.com'
          password:  '123456'
        }
        .expect 200
        .expect {
          message: 'A verification email has been sent to your registered email address'
          status: 'ok'
        }
      { token } = await Token.findOne({})
      await agent
        .get "/v1/u/user/verifyUserEmail?token=#{token}"
        .expect 204
        .expect {}

  describe 'login', ->

    it 'returns error when user not login', ->
      await session.agent
        .get '/v1/u/user'
        .expect 401, {
          responseCode: 401
          message: 'require login'
        }

    it 'login failed when user is not active', ->
      unverifiedUser = await session.createUser(
        'andy+nodeswork+test@nodeswork.com', '123456'
      )

      await session.agent
        .post '/v1/u/user/login'
        .send {
          email: 'andy+nodeswork+test@nodeswork.com'
          password: '123456'
        }
        .expect 422, {
          responseCode: 422
          message: 'user is not active'
        }

    it 'login successully when user is active', ->
      await session.createUser(
        'andy+nodeswork+test@nodeswork.com', '123456', 'ACTIVE'
      )

      resp = await session.agent
        .post '/v1/u/user/login'
        .send {
          email: 'andy+nodeswork+test@nodeswork.com'
          password: '123456'
        }
        .expect 200

      resp.body.should.have.properties ['_id', 'createdAt', 'lastUpdateTime']
      resp.body.should.have.properties {
        email: 'andy+nodeswork+test@nodeswork.com'
      }
      resp.body.should.not.have.properties ['password']

      resp = await session.agent
        .get '/v1/u/user'
        .expect 200

      resp.body.should.have.properties ['_id', 'createdAt', 'lastUpdateTime']
      resp.body.should.have.properties {
        email: 'andy+nodeswork+test@nodeswork.com'
      }
      resp.body.should.not.have.properties ['password']

  describe 'logout', ->

    it 'allow user logout', ->
      await session.createUser(
        'andy+nodeswork+test@nodeswork.com', '123456', 'ACTIVE'
      )

      await session.agent
        .post '/v1/u/user/login'
        .send {
          email: 'andy+nodeswork+test@nodeswork.com'
          password: '123456'
        }
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
