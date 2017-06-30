# Test configuration.

module.exports = {

  env:   'production'

  db:    process.env.DB_URI ? 'localhost:27017/nodeswork-test'

  port:  process.env.PORT ? 28799

}
