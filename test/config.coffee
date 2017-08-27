{ config } = require '../dist/config'

describe 'config', ->

  it 'loads the env', ->
    config.app.env.should.be.equal 'test'
