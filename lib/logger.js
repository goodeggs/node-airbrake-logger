var airbrake, ensureErrorObject, logErrorLocally, logger, maybeLogErrorRemotely;

airbrake = require('airbrake');

maybeLogErrorRemotely = function(e) {
  if (!logger.remote) return;
  return logger.client.notify(e, function(error, url) {
    if (error != null) return logger.console.error(error);
  });
};

logErrorLocally = function(e) {
  var msg, _ref;
  msg = "";
  if ((_ref = e.params) != null ? _ref.context : void 0) {
    msg += "" + e.params.context + "\n";
  }
  msg += e.stack;
  return logger.console.error(msg);
};

ensureErrorObject = function(e) {
  if (typeof e === 'object') return e;
  try {
    throw new Error(e.toString());
  } catch (eNew) {
    return eNew;
  }
};

logger = module.exports = {
  console: null,
  remote: null,
  client: null,
  configure: function(opts) {
    var _ref, _ref2;
    logger.console = (_ref = opts.console) != null ? _ref : console;
    logger.remote = (_ref2 = opts.remote) != null ? _ref2 : true;
    logger.client = airbrake.createClient(opts.airbrakeKey);
    return logger.client.cgiDataVars = function() {
      var key, value, vars;
      vars = this.constructor.prototype.cgiDataVars.apply(this, arguments);
      for (key in vars) {
        value = vars[key];
        if (key.toLowerCase().indexOf('password') >= 0) vars[key] = '[HIDDEN]';
      }
      return vars;
    };
  },
  error: function(context, err) {
    var _ref;
    if (typeof err === 'undefined') {
      err = ensureErrorObject(context);
    } else {
      err = ensureErrorObject(err);
      if ((_ref = err.params) == null) err.params = {};
      err.params.context = context;
    }
    maybeLogErrorRemotely(err);
    return logErrorLocally(err);
  },
  debug: function() {
    return logger.console.log.apply(logger.console, arguments);
  },
  handleUncaughtExceptions: function() {
    return process.on('uncaughtException', function(err) {
      return logger.error('Uncaught exception', err);
    });
  },
  middleware: function(err, req, res, next) {
    err.url = req.url;
    err.params = req.params;
    logger.error('uncaught express exception', err);
    return next();
  }
};
