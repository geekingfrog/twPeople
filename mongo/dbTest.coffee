mongo = require 'mongodb'
MongoClient = mongo.MongoClient
BSON = mongo.BSONPure
Dao = require './dao'
logger = require '../logConfig'
moment = require 'moment'
async = require 'async'

dao = new Dao()

format = 'YYYYMMDD'
start = moment '20130309', format
end = moment '20030502', format
dao.connect (err, db) ->
  if err
    logger.error err
    return
  articles = db.collection('parsedArticle')

  current = moment(start)
  dates = []
  while(current.isAfter(end) or current.isSame(end))
    dates.push current.format(format)
    current.subtract('d',1)
  logger.debug "#{dates.length} dates"


  missing = []
  async.eachLimit dates, 50, (d, next) ->
    articles.findOne({date: d}, (errFind, item) ->
      if (not item) and (not errFind)
        logger.warn "missing date: #{d}"
        missing.push d
      next(errFind)
    )
  , (err, res) ->
    if err
      logger.error err
    else
      logger.info "missing #{missing.length} dates: ", missing
    return
  

  return
  missing = []
  lookupDate = (d, next) ->
    logger.debug "looking for date=#{d}"
    articles.findOne({date: d}, (errFind, item) ->
      if errFind
        logger.error errFind
        next(errFind)
      else if item
        next(null)
      else
        logger.warn "missing date #{d}"
        missing.push d
        next(null)
    )
        
  done = -> logger.info "missing dates(#{missing.length}): ",missing

  i = 0
  iterator = (err) ->
    return logger.error err if err
    if i is dates.length-1
      return done()
    else
      lookupDate(dates[i++], iterator)

  lookupDate(dates[i], iterator)
    

  
