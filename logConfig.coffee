winston = require 'winston'
config=
  transports: [new (winston.transports.Console)({
    level: 'debug'
    colorize: true
    timestamp: true
  })]
  levels:
    debug: 0
    info: 1
    warn: 2
    error: 3
  colors:
    debug: 'blue'
    info: 'green'
    warn: 'yellow'
    error: 'red'

logger = new (winston.Logger)(config)
module.exports = exports = logger
