_                       = require 'underscore'
mongoose                = require 'mongoose'

{
  TimestampModelPlugin
  ExcludeFieldsToJSON
}                       = require './utils'
{KoaMiddlewares}        = require './plugins/koa-middlewares'

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

  imageUrl:    String

  oAuth:
    isOAuth:              Boolean
    requestTokenUrl:      String
    authorizeUrl:         String
    accessTokenUrl:       String
    verifyCredentialUrl:  String
    callbackUrl:          String
    consumerKey:          String
    consumerSecret:       String

}, collection: 'account_categories'

  .plugin TimestampModelPlugin
  .plugin KoaMiddlewares
  # TODO: Explore why it's not working when retrieving accounts.
  .plugin ExcludeFieldsToJSON, fields: ['oAuth']
