mongoose  = require 'mongoose'

{
  TimestampModelPlugin
  KoaMiddlewares
}                       = require './utils'


exports.MessageSchema = MessageSchema = mongoose.Schema {

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

  # redundant: 0, normal: 1, high priority: 2
  priority:
    type:       Number
    default:    1

}, collection: 'messages', discriminatorKey: 'messageType'

  .plugin TimestampModelPlugin
  .plugin KoaMiddlewares


exports.AppletMessageSchema = AppletMessageSchema = MessageSchema.extend {

  sender:
    type:       mongoose.Schema.ObjectId
    ref:        'Applet'
    required:   true
    index:      true

}
