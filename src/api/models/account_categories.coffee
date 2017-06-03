_                       = require 'underscore'
mongoose                = require 'mongoose'

{
  TimestampModelPlugin
  ExcludeFieldsToJSON
  KoaMiddlewares
}                       = require './utils'

exports.AccountCategorySchema = AccountCategorySchema = mongoose.Schema {

  name:
    type:      String
    unique:    true

  description:
    type:      String

  isVirtual:
    type:      Boolean
    default:   false

  deprecated:
    type:      Boolean
    default:   false

  implements:  [
    type:      mongoose.Schema.ObjectId
    ref:       'AccountCategory'
  ]

}, collection: 'account_categories'

  .plugin TimestampModelPlugin
  .plugin KoaMiddlewares
