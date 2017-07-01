_            = require 'underscore'
request      = require 'supertest'
should       = require 'should'

{ app }      = require '../../../src/server'
models       = require '../../../src/api/models'
{ clearDB }  = require './resource-helper'


describe 'users', ->

  agent = null

  users = {

    user1:
      userType:    'EmailUser'
      email:       'hello1@world.com'
      password:    '12354'

    user2:
      userType:    'EmailUser'
      email:       'hello2@world.com'
      password:    '12354'
  }

  verifyUserInfo = (user) ->
    user._id.should.be.ok
    user.should.have.properties {
      userType:     'EmailUser'
      email:        users.user1.email
      timezone:     'America/Los_Angeles'
      status:       'UNVERIFIED'
      attributes:
        developer:  false
    }
    user.should.not.have.properties 'password'


  before ->
    await clearDB()
    agent = request.agent app.server

  describe '#new', ->

    it 'should fail to register without parameter', ->
      await agent
        .post '/api/v1/users/new'
        .expect 500, {
          name:     'NodesworkError'
          message:  'Required parameter is missing'
          meta:
            path:   'userType'
        }

    it 'should fail to register without email and password', ->
      await agent
        .post '/api/v1/users/new'
        .send {
          userType: 'EmailUser'
        }
        .expect 500, {
          name:     'NodesworkError'
          message:  'Validation error'
          meta:
            errors:
              email:
                kind: 'required'
                message: 'email is required.'
              password:
                kind: 'required'
                message: 'password is required.'
        }

    it 'should fail when email format is wrong', ->
      await agent
        .post '/api/v1/users/new'
        .send {
          userType: 'EmailUser'
          email:    'hello world'
          password: '12354'
        }
        .expect 500, {
          name:     'NodesworkError'
          message:  'Validation error'
          meta:
            errors:
              email:
                kind: "user defined"
                message: "invalid email address"
        }

    it 'should create email user successfully', ->
      res = await agent
        .post '/api/v1/users/new'
        .send users.user1
        .expect 200

      verifyUserInfo res.body

    it 'should failed when create duplicate user', ->
      await agent
        .post '/api/v1/users/new'
        .send users.user2
        .expect 200

      err = await agent
        .post '/api/v1/users/new'
        .send users.user2
        .expect 500

      err.body.should.have.properties {
        name: 'NodesworkError'
        message: 'Duplicate record'
      }

  describe '#login', ->

    it 'should allow user to login', ->
      res = await agent
        .post '/api/v1/users/login'
        .send users.user1
        .expect 200

      verifyUserInfo res.body

    it 'should not allow user to login', ->
      await agent
        .post '/api/v1/users/login'
        .send _.extend {}, users.user1, {
          password: 'wrong password'
        }
        .expect 401, {}

  describe '#logout', ->

    it 'should allow user to logout', ->
      res = await agent
        .post '/api/v1/users/login'
        .send users.user1
        .expect 200

      verifyUserInfo res.body

      res = await agent
        .get '/api/v1/users/current'
        .expect 200

      verifyUserInfo res.body

      await agent
        .get '/api/v1/users/logout'
        .expect 200, status: 'ok'

      res = await agent
        .get '/api/v1/users/current'
        .expect 200, {}
