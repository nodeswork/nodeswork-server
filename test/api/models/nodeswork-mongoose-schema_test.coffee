mongoose  = require 'mongoose'
should    = require 'should'

{ NodesworkMongooseSchema } = require '../../../src/api/models/nodeswork-mongoose-schema'


describe 'NodesworkMongooseSchema', ->

  before (next) ->
    do ->
      # mongoose.set 'debug', true
      mongoose.Promise = global.Promise
      await mongoose.connect 'mongodb://localhost:27017/test'
      mongoose.connection.db.dropDatabase next
    return

  class BaseSchema extends NodesworkMongooseSchema

    @Config {
      discriminatorKey: 'key'
      collection:       'tests'
    }

    @Schema {
      baseValue:
        type:     Boolean
        default:  false
      # baseUniqueValue:
        # type:     String
        # unique:   true
    }

  class ExtendSchema extends BaseSchema

    @Schema {
      extendValue:
        type:       Boolean
        default:    true
      uniqueValue:
        type:       String
        unique:     true
    }

  Base   = null
  Extend = null

  before ->
    Base   = mongoose.model 'Base', BaseSchema.MongooseSchema()
    Extend = mongoose.model 'Extend', ExtendSchema.MongooseSchema()

  beforeEach ->
    await Base.remove {}

  describe '#ExtendedKey', ->

    it 'should return correctly', ->

      should(BaseSchema.ExtendedKey()).not.be.ok

      ExtendSchema.ExtendedKey().should.be.equal 'key'

  describe '#MongooseSchema', ->

    it 'should create right instance', ->

      base = await Base.create {}

      base.should.have.properties ['_id', 'baseValue']
      base.should.not.have.properties ['extendValue']

      extend = await Extend.create {}
      extend.should.have.properties ['_id', 'baseValue', 'extendValue']

      (base instanceof Base).should.be.true()
      (base instanceof Extend).should.be.false()
      (extend instanceof Base).should.be.false()
      (extend instanceof Extend).should.be.true()

    it 'should retrieve right instance', ->

      b1 = await Base.create {}
      e1 = await Extend.create {}

      b2 = await Base.findOne baseValue: false
      e2 = await Extend.findOne baseValue: false

      b1._id.should.be.deepEqual b2._id
      e1._id.should.be.deepEqual e2._id
      b1._id.should.not.be.deepEqual e1._id
      b2._id.should.not.be.deepEqual e2._id

    it 'should deal with unique', ->

      b1 = await Base.create {}
      b2 = await Base.create {}

      e1 = await Extend.create {}
      try
        e2 = await Extend.create {}
        should.fail()
      catch
