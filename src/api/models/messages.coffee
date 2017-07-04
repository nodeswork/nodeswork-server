mongoose                      = require 'mongoose'
{ NodesworkMongooseSchema
  KoaMiddlewares }            = require 'nodeswork-mongoose'


class MessageSchema extends NodesworkMongooseSchema

  @Config {
    collection: 'messages'
    discriminatorKey: 'messageType'
  }

  @Schema {
    receiver:
      type:       mongoose.Schema.ObjectId
      ref:        'User'
      required:   true
      index:      true

    views:
      type:       Number
      default:    0

    message:
      type:       String
      required:   true
      min:        [1, 'Message could not be empty.']
      max:        [1400, 'Message could not be larger than 1400 chars.']

    # redundant: 0, normal: 1, high priority: 2
    priority:
      type:       Number
      default:    1
      min:        0
      max:        2

  }

  @Plugin KoaMiddlewares


class AppletMessageSchema extends MessageSchema

  @Schema {
    sender:
      type:       mongoose.Schema.ObjectId
      ref:        'Applet'
      required:   true
      index:      true

    via:
      type:       mongoose.Schema.ObjectId
      ref:        'UserApplet'
  }


module.exports = {
  MessageSchema
  AppletMessageSchema
}
