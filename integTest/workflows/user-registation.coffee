request         = require 'supertest'

describe 'user registration', ->

  agent = request.agent 'http://localhost:3001'

  describe 'register', ->

    it 'failes without email or password', ->
      await agent
        .post '/api/v1/u/user/register'
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
        .post '/api/v1/u/user/register'
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
        .post '/api/v1/u/user/register'
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
