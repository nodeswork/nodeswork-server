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
    required:   true
    min:        [1, 'Message could not be empty.']
    max:        [1400, 'Message could not be larger than 1400 chars.']

  # redundant: 0, normal: 1, high priority: 2
  priority:
    type:       Number
    default:    1
    min:        0
    max:        2

}, collection: 'messages', discriminatorKey: 'messageType'

  .plugin TimestampModelPlugin
  .plugin KoaMiddlewares


exports.AppletMessageSchema = AppletMessageSchema = MessageSchema.extend {

  sender:
    type:       mongoose.Schema.ObjectId
    ref:        'Applet'
    required:   true
    index:      true

  via:
    type:       mongoose.Schema.ObjectId
    ref:        'UserApplet'
    required:   true
}
