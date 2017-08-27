require('source-map-support').install()

mongoose = require 'mongoose'

mongoose.Promise = global.Promise
mongoose.connect 'mongodb://localhost:27017/nodeswork-test', {
  useMongoClient: true
}
