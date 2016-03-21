_              = require 'lodash'
mongojs        = require 'mongojs'
Datastore      = require 'meshblu-core-datastore'
Cache          = require 'meshblu-core-cache'
redis          = require 'fakeredis'
uuid           = require 'uuid'
ResetToken = require '../'

describe 'ResetToken', ->
  beforeEach (done) ->
    @uuidAliasResolver = resolve: (uuid, callback) => callback null, uuid
    @datastore = new Datastore
      database: mongojs 'reset-token-manager-test'
      collection: 'devices'

    @datastore.remove done

  beforeEach ->
    @cache = new Cache client: redis.createClient uuid.v1()
    @sut = new ResetToken {@datastore, @cache, @uuidAliasResolver}

  describe '->do', ->
    describe 'when given a valid request', ->
      beforeEach (done) ->
        @datastore.insert uuid: 'electric-eels', done

      beforeEach (done) ->
        request =
          metadata:
            responseId: 'its-electric'
            toUuid: 'electric-eels'
            messageType: 'received'
            options: {}
          rawData: '{}'

        @sut.do request, (error, @response) => done error

      it 'should return you a device with the uuid and token', ->
        expect(@response.data.uuid).to.exist
        expect(@response.data.token).to.exist

      it 'should have a device and all of the base properties', (done) ->
        @datastore.findOne {uuid: @response.data.uuid}, (error, device) =>
          return done error if error?
          expect(device.uuid).to.exist
          expect(device.token).to.exist
          done()

      it 'should create the token in the cache', (done) ->
        @datastore.findOne {uuid: @response.data.uuid}, (error, device) =>
          return done error if error?
          @cache.exists "meshblu-token-cache:#{device.uuid}:#{device.token}", (error, result) =>
            return done error if error?
            expect(result).to.be.true
            done()

      it 'should return a 200', ->
        expectedResponseMetadata =
          responseId: 'its-electric'
          code: 200
          status: 'OK'

        expect(@response.metadata).to.deep.equal expectedResponseMetadata
