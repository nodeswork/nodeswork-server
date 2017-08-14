mongoose                     = require 'mongoose'

{ KoaMiddlewares
  NodesworkMongooseSchema
  AUTOGEN }                  = require '@nodeswork/mongoose'

{ DataLevel }                = require '../plugins/data-levels'


# Account model schema, which holds third-parties' accounts for the user.
class AccountSchema extends NodesworkMongooseSchema

  @Config {
    collection:        'accounts'
    discriminatorKey:  'accountType'
  }

  @Schema {
    user:
      type:       mongoose.Schema.ObjectId
      ref:        'User'
      required:   true
      index:      true

    name:
      type:       String
      required:   true
      max:        [ 140, 'Max length of the name is 140 charactors.' ]
      min:        [   2, 'Min length of the name is 2 charactors.'   ]

    category:
      type:       mongoose.Schema.ObjectId
      ref:        'AccountCategory'
      required:   true

    status:
      enum:       [ 'ACTIVE', 'ERROR', 'INACTIVE', 'UNVERIFIED' ]
      type:       String
      default:    'UNVERIFIED'
      api:        AUTOGEN
  }

  @Plugin DataLevel, levels: [ 'DETAIL', 'TOKEN' ]
  @Plugin KoaMiddlewares


module.exports = {
  AccountSchema
}
