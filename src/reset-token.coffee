_                = require 'lodash'
http             = require 'http'
RootTokenManager = require 'meshblu-core-manager-root-token'

class ResetToken
  constructor: ({ datastore, uuidAliasResolver }) ->
    throw new Error "Missing mandatory @datastore option" unless datastore?
    @rootTokenManager = new RootTokenManager { datastore, uuidAliasResolver }

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
    @rootTokenManager.generateAndStoreToken { uuid }, (error, token) =>
      return callback error if error?
      @_doCallback request, 200, { uuid, token }, callback

module.exports = ResetToken
