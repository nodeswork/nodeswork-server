should        = require 'should'

models        = require '../../../dist/api/models'
{ MAX_DATE }  = require '../../../dist/utils/time'

describe 'TokenModel', ->

  beforeEach ->
    await models.Token.remove({})

  describe 'createToken', ->

    it 'creates with empty payload', ->
      token = await models.Token.createToken('test', null)
      token.should.have.properties {
        maxRedeemTimes:  -1
        expireAt:        MAX_DATE
      }

      token.token.should.be.ok()
      token.token.should.have.length 16

      obj = await models.Token.redeemToken(token.token)
      obj.maxRedeemTimes.should.be.equal -2

    it 'creates with one time redeem', ->
      token = await models.Token.createToken('test', null, maxRedeemTimes: 1)
      token.should.have.properties {
        maxRedeemTimes:  1
        expireAt:        MAX_DATE
      }

      token.token.should.be.ok()
      token.token.should.have.length 16

      obj = await models.Token.redeemToken(token.token)
      obj.maxRedeemTimes.should.be.equal 0

      obj = await models.Token.redeemToken(token.token)
      should(obj).be.null()
