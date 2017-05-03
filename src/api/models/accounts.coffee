mongoose                = require 'mongoose'

{TimestampModelPlugin}  = require './utils'


exports.AccountSchema = AccountSchema = mongoose.Schema {

  user:
    type:     mongoose.Schema.ObjectId
    ref:      'User'
    require:  true

}, collection: 'accounts', discriminatorKey: 'accountType'

  .plugin TimestampModelPlugin


exports.FifaFutAccountSchema = FifaFutAccountSchema = AccountSchema.extend {

  cookieJar:    String
}
