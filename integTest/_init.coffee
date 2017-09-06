require('source-map-support').install()

_          = require 'underscore'

{ app }    = require '../dist/server'


before ->
  await app.isReady()

describe 'app', ->

  it 'should be ready', ->

module.exports = {
}
