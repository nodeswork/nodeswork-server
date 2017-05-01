mongoose         = require 'mongoose'
{registerModels} = require '../../../src/api/models'


dbURI = 'localhost:27017/nodeswork-unittest'

exports.dbIsReady = () ->
  mongoose.Promise = global.Promise

  unless mongoose.connection.db
    await mongoose.connect dbURI
    registerModels mongoose

  mongoose.connection.db
