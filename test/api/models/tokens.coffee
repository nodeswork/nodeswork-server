should      = require 'should'

models      = require '../../../dist/api/models/models'

describe 'TokenModel', ->

  beforeEach ->
    console.log 'before each', models.Token
    await models.Token.remove({})
    console.log 'before each finished'

  it 'can create with empty payload', ->
    token = await models.Token.createToken(null)
    console.log token
