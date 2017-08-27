_          = require 'underscore'

{ app }    = require '../dist/server'


before ->
  await app.isReady()

module.exports = {
}
