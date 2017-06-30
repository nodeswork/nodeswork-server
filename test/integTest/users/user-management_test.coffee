request   = require 'supertest'
should    = require 'should'

{ app }   = require '../../../src/server'
models    = require '../../../src/api/models'


describe 'users', () ->

  agent = null

  before ->
    await app.isReady()
    agent = request.agent app.server
    # TODO: handle this in schema-extend.
    await models.User.remove userType: 'EmailUser'

  it 'should fail to register without parameter', () ->
    await agent
      .post '/api/v1/users/new'
      .expect 500, {
        name:     'NodesworkError'
        message:  'Required parameter is missing'
        meta:
          path:   'userType'
      }

  it 'should fail to register without email and password', () ->
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

  it 'should fail when email format is wrong', () ->
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

  it 'should create email user successfully', () ->
    res = await agent
      .post '/api/v1/users/new'
      .send {
        userType: 'EmailUser'
        email:    'hello@world.com'
        password: '12354'
      }
      .expect 200

    user = res.body

    user.should.have.properties '_id'
    user.should.have.properties {
      userType:     'EmailUser'
      email:        'hello@world.com'
      timezone:     'America/Los_Angeles'
      status:       'UNVERIFIED'
      attributes:
        developer:  false
    }
    user.should.not.have.properties 'password'
