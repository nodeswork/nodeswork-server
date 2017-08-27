{ User } = require '../../../../dist/api/models/models'

describe 'UserModel', ->

  beforeEach ->
    await User.remove({})

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
