{ User, Token } = require '../../../../dist/api/models/models'

describe 'UserModel', ->

  beforeEach ->
    await User.remove({})
    await Token.remove({})

  describe 'create', ->

    it 'creates with valid email address', ->
      user = await User.create({
        email:     'test1@gmail.com'
        password:  '123456'
      })
      user.should.have.properties {
        email: 'test1@gmail.com'
        status: 'UNVERIFIED'
      }
      user.password.should.not.equal '123456'

  describe '#sendVerifyEmail', ->

    it 'send email to registered email', ->
      user = await User.create({
        email:     'andy+nodeswork+unittest@nodeswork.com'
        password:  '123456'
      })
      user.should.be.ok()
      { token } = await user.sendVerifyEmail()
      await user.verifyUserEmail(token)
      user = await User.findById(user._id)
      user.status.should.be.equal 'ACTIVE'
