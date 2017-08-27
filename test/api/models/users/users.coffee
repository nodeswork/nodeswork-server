{ User, Token } = require '../../../../dist/api/models/models'

describe 'UserModel', ->

  beforeEach ->
    await User.remove({})
    await Token.remove({})

  describe 'create', ->

    it 'creates with valid email address', ->
      user = await User.create({
        email:     'test1@gmail.com'
        password:  '1234'
      })
      user.should.have.properties {
        email: 'test1@gmail.com'
        status: 'UNVERIFIED'
      }
      user.password.should.not.equal '1234'

  describe '#sendVerifyEmail', ->

    it 'send email to registered email', ->
      user = await User.create({
        email:     'andy+nodeswork+unittest@nodeswork.com'
        password:  '1234'
      })
      user.should.be.ok()
      await user.sendVerifyEmail()
      token = await Token.findOne()
      await user.verifyUserEmail(token.token)
      user = await User.findById(user._id)
      user.status.should.be.equal 'ACTIVE'
