{ app }    = require '../src/server'

before ->
  await app.isReady()

module.exports = {
}
