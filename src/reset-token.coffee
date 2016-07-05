_             = require 'lodash'
http          = require 'http'
TokenManager  = require 'meshblu-core-manager-token'

class ResetToken
  constructor: ({@datastore,@cache,@pepper,uuidAliasResolver}) ->
    throw new Error "Missing mandatory @cache option" unless @cache?
    throw new Error "Missing mandatory @datastore option" unless @datastore?
    throw new Error "Missing mandatory @pepper option" unless @pepper?
    @tokenManager = new TokenManager {@datastore,@cache,@pepper,uuidAliasResolver}

  _doCallback: (request, code, device, callback) =>
    response =
      metadata:
        responseId: request.metadata.responseId
        code: code
        status: http.STATUS_CODES[code]
      data: device
    callback null, response

  do: (request, callback) =>
    {metadata} = request
    uuid = metadata.toUuid ? metadata.auth?.uuid
    @tokenManager.generateAndStoreRootToken {uuid}, (error, token) =>
      return callback error if error?
      @_doCallback request, 200, { uuid, token }, callback

module.exports = ResetToken
