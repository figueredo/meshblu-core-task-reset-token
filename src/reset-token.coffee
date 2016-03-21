_             = require 'lodash'
http          = require 'http'
DeviceManager = require 'meshblu-core-manager-device'

class ResetToken
  constructor: ({@cache,uuidAliasResolver,@datastore}) ->
    throw new Error "Missing mandatory @cache option" unless @cache?
    throw new Error "Missing mandatory @datastore option" unless @datastore?
    @deviceManager = new DeviceManager {@cache, @datastore, uuidAliasResolver}

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
    @deviceManager.resetRootToken {uuid}, (error, device) =>
      return callback error if error?
      return @_doCallback request, 200, device, callback

module.exports = ResetToken
