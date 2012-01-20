airbrake = require 'airbrake'

maybeLogErrorRemotely = (e) ->
  return unless logger.remote
  logger.client.notify e, (error, url) ->
    logger.console.error(error) if error?

logErrorLocally = (e) ->
  msg = ""
  msg += "#{e.params.context}\n" if e.params?.context
  msg += e.stack
  logger.console.error(msg)

ensureErrorObject = (e) ->
  return e if typeof e == 'object'
  try
    throw new Error(e.toString())
  catch eNew
    # TODO(bobzoller): consider trimming the stack of our rethrow hack?
    return eNew

logger = module.exports =

  console: null
  remote: null
  client: null

  configure: (opts) ->
    logger.console = opts.console ? console
    logger.remote = opts.remote ? true
    logger.client = airbrake.createClient(opts.airbrakeKey)
    
    logger.client.cgiDataVars = ->
      vars = this.constructor.prototype.cgiDataVars.apply(this, arguments) # Call super
      for key, value of vars
        vars[key] = '[HIDDEN]' if key.toLowerCase().indexOf('password') >= 0
      vars

  error: (context, err) ->
    if typeof err == 'undefined'
      err = ensureErrorObject(context)
    else
      err = ensureErrorObject(err)
      err.params ?= {}
      err.params.context = context
    maybeLogErrorRemotely(err)
    logErrorLocally(err)

  # just an alias for console.log
  debug: ->
    logger.console.log.apply(logger.console, arguments)

  handleUncaughtExceptions: ->
    process.on 'uncaughtException', (err) ->
      logger.error('Uncaught exception', err)
  
  middleware: (err, req, res, next) ->
    err.url = req.url
    err.params = req.params
    logger.error('uncaught express exception', err)
    next()

