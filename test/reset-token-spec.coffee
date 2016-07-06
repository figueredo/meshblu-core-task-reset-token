_                = require 'lodash'
mongojs          = require 'mongojs'
Datastore        = require 'meshblu-core-datastore'
RootTokenManager = require 'meshblu-core-manager-root-token'
ResetToken       = require '../'

describe 'ResetToken', ->
  beforeEach (done) ->
    database = mongojs 'reset-token-manager-test', ['tokens']
    @datastore = new Datastore
      database: database
      collection: 'tokens'

    database.tokens.remove done

  beforeEach ->
    uuidAliasResolver = resolve: (uuid, callback) => callback null, uuid
    @rootTokenManager = new RootTokenManager {@datastore, uuidAliasResolver}
    @sut = new ResetToken {@datastore, uuidAliasResolver}

  describe '->do', ->
    beforeEach (done) ->
      @datastore.insert { uuid: 'electric-eels', token: 'old-token' }, done

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
          expect(record.token).to.not.equal 'old-token'
          done()

      it 'should have a valid token', (done) ->
        @rootTokenManager.verifyToken { uuid: 'electric-eels', token: @response.data.token }, (error, valid) =>
          return callback error if error?
          expect(valid).to.be.true
          done()

      it 'should return a 200', ->
        expectedResponseMetadata =
          responseId: 'its-electric'
          code: 200
          status: 'OK'

        expect(@response.metadata).to.deep.equal expectedResponseMetadata
