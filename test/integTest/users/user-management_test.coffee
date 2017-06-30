request = require 'supertest'
{ app } = require '../../../src/server'


describe 'users', () ->

  agent = null

  before ->
    await app.isReady()
    agent = request.agent app.server

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
