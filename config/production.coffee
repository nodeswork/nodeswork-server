# Test configuration.

module.exports = {

  env:   'production'

  db:    process.env.DB_URI ? 'mongodb://localhost:27017/nodeswork-test'

  port:  process.env.PORT ? 28799

}
