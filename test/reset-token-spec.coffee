_              = require 'lodash'
mongojs        = require 'mongojs'
Datastore      = require 'meshblu-core-datastore'
Cache          = require 'meshblu-core-cache'
TokenManager   = require 'meshblu-core-manager-token'
redis          = require 'fakeredis'
uuid           = require 'uuid'
ResetToken = require '../'

describe 'ResetToken', ->
  beforeEach (done) ->
    database = mongojs 'reset-token-manager-test', ['tokens']
    @datastore = new Datastore
      database: database
      collection: 'tokens'

    database.tokens.remove done

  beforeEach ->
    @cache = new Cache client: redis.createClient uuid.v1()
    pepper = 'cheeseburger'
    uuidAliasResolver = resolve: (uuid, callback) => callback null, uuid
    @tokenManager = new TokenManager {@datastore, @cache, pepper, uuidAliasResolver}
    @sut = new ResetToken {@datastore, @cache, pepper, uuidAliasResolver}

  describe '->do', ->
    describe 'when given a valid request', ->
      beforeEach (done) ->
        request =
          metadata:
            responseId: 'its-electric'
            toUuid: 'electric-eels'
            options: {}
          rawData: '{}'

        @sut.do request, (error, @response) => done error

      it 'should return you a record with the uuid and token', ->
        expect(@response.data.uuid).to.equal 'electric-eels'
        expect(@response.data.token).to.exist

      it 'should have a device and all of the base properties', (done) ->
        @datastore.findOne {uuid: 'electric-eels'}, (error, record) =>
          return done error if error?
          expect(record.uuid).to.equal 'electric-eels'
          expect(record.hashedRootToken).to.exist
          done()

      it 'should have a valid hashedRootToken', (done) ->
        @datastore.findOne {uuid: 'electric-eels'}, (error, record) =>
          return done error if error?
          { token } = @response.data
          @tokenManager.verifyToken { uuid: 'electric-eels', token }, (error, valid) =>
            return callback error if error?
            expect(valid).to.be.true
            done()

      it 'should create the token in the cache', (done) ->
        @datastore.findOne {uuid: 'electric-eels'}, (error, record) =>
          return done error if error?
          @cache.exists "#{record.uuid}:#{record.hashedToken}", (error, result) =>
            return done error if error?
            expect(result).to.be.true
            done()

      it 'should return a 200', ->
        expectedResponseMetadata =
          responseId: 'its-electric'
          code: 200
          status: 'OK'

        expect(@response.metadata).to.deep.equal expectedResponseMetadata
