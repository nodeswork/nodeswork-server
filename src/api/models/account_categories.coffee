_                            = require 'underscore'
mongoose                     = require 'mongoose'
{ NodesworkMongooseSchema
  KoaMiddlewares }           = require 'nodeswork-mongoose'

{ ExcludeFieldsToJSON }      = require './plugins/exclude-fields'


# Account Categories Schama.
class AccountCategorySchema extends NodesworkMongooseSchema

  @Config {
    collection: 'account_categories'
  }

  @Schema {
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
  }

  @Plugin KoaMiddlewares
  # TODO: Explore why it's not working when retrieving accounts.
  @Plugin ExcludeFieldsToJSON, fields: ['oAuth']


module.exports = {
  AccountCategorySchema
}
