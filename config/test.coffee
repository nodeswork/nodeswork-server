# Test configuration.

module.exports = {

  env:   'test'

  db:    process.env.DB_URI ? 'localhost:27017/nodeswork-test'

  port:  process.env.PORT ? 3001

}
