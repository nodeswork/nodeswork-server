request = require 'supertest'

{ app } = require '../../src/server'


describe 'server', () ->

  before ->
    await app.isReady()

  it 'should start', () ->

    await request(app.server)
      .get '/'
      .expect 200, {}
