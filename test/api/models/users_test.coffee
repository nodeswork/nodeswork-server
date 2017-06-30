# _           = require 'underscore'
# should      = require 'should'

# models      = require '../../../src/api/models'
# {dbIsReady} = require './model_helper'

# describe 'EmailUser', ->

  # EMAIL1           = 'test1@gmail.com'
  # EMAIL2           = 'test2@gmail.com'
  # EMAIL3           = 'test3@gmail.com'
  # EMAIL4           = 'test4@gmail.com'
  # EMAIL_SAME       = 'test-same@gmail.com'
  # PASSWORD1        = '12345'
  # PASSWORD2        = '123444'

  # DUPLICATE_ERROR  = code: 11000
  # EMAIL_VALIDATION = message: 'EmailUser validation failed'
  # REQUIRED         = 'required'

  # before ->
    # await dbIsReady()
    # await models.User.remove {}

  # describe '#register()', ->
    # it 'should register user successfully with email and password', ->
      # user = await models.EmailUser.register {
        # email: EMAIL1, password: PASSWORD1
      # }
      # user._id.should.not.be.empty

    # it 'should not allow to create multiple same email account', ->
      # user = await models.EmailUser.register {
        # email: EMAIL_SAME, password: PASSWORD1
      # }
      # user._id.should.not.be.empty

      # (models.EmailUser.register {
        # email: EMAIL_SAME, password: PASSWORD1
      # }).should.be.rejectedWith DUPLICATE_ERROR

    # it 'should not allow to create without email', ->
      # (models.EmailUser.register {
        # password: PASSWORD1
      # }).should.be.rejectedWith EMAIL_VALIDATION

    # it 'should not allow to create without password', ->
      # (models.EmailUser.register {
        # email: EMAIL2
      # }).should.be.rejectedWith errors: (errors) ->
        # errors.password.properties.type.should.equal REQUIRED

  # describe '#comparePassword()', ->
    # it 'should save hashed password', ->
      # user = await models.EmailUser.register {
        # email: EMAIL3, password: PASSWORD1
      # }
      # user.password.should.not.equal PASSWORD1

    # it 'should compare password', ->
      # user = await models.EmailUser.register {
        # email: EMAIL4, password: PASSWORD1
      # }
      # (await user.comparePassword PASSWORD1).should.be.true()
      # (await user.comparePassword PASSWORD2).should.be.false()
