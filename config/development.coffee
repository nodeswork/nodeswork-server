# Development configuration.

module.exports = {

  env:   'development'

  db:    process.env.DB_URI ? 'localhost:27017/nodeswork-dev'

  port:  process.env.PORT ? 3000

}
