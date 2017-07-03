# Development configuration.

module.exports = {

  env:   'development'

  db:    process.env.DB_URI ? 'mongodb://localhost:27017/nodeswork-dev'

  port:  process.env.PORT ? 3000

}
