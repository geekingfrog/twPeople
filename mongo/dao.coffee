mongo = require 'mongodb'
MongoClient = mongo.MongoClient
BSON = mongo.BSONPure
config = require './mongoConfig'
logger = require '../logConfig'
async = require 'async'
twPeople = require './twPeople'
sys = require 'sys'
async = require 'async'


Dao = ->
  if not (this instanceof Dao)
    return new Dao()


  db = null
  lastError = null
  peopleColl = null
  articleColl = null

  error=
    notConnected: new Error "not connected"

  isConnected = -> return db isnt null

  connect = (next = ->) ->
    config = config or {}
    host = config.dbHost or "localhost"
    port = config.dbPort or 27017
    unless config.dbName
      lastError = new Error("No db name provided")
      return next(lastError)
    connectURI = "mongodb://#{host}:#{port}/#{config.dbName}"
    MongoClient.connect(connectURI, {w:1}, (err, _db) ->
      if err
        lastError = err
        db = null
        logger.error "cannot connect to #{connectURI} -- #{sys.inspect err}"
        return next(err)
      logger.debug "successfully connected to the database"
      db = _db
      peopleColl = db.collection 'people'
      articleColl = db.collection 'parsedArticle'
      return next(null, db)
    )

  close = ->
    db.close() if db isnt null
    return
  

  # get the list of people from the file twPeople.coffee
  # and make sure the collection 'people' has the same content (or more)
  # And because count() is super slow, update a collection which keep track
  # of the total of article for a given person and a given hostname
  # doesn't return anything
  
  syncPeople = (cb) ->
    dbPeople = db.collection 'people'
    insertMissing = (missing, insertCb) ->
      dbPeople.insert(missing, {w:1}, (err, res) ->
        if err
          logger.error err
          lastError = err
          return insertCb(err)
        return insertCb(null)

      )

    async.map(twPeople, (person, next) ->
      dbPeople.findOne({name: person.name}, (dberr, p) ->
        if dberr
          next(dberr)
        else if p
          return next(null, null)
        else
          return next(null, person)
      )
    , (err, res) ->
      filtered = res.filter (el) -> el isnt null
      if filtered.length is 0
        logger.info "db people already up to date"
        return cb()
      insertMissing(filtered, (err) ->
        if err
          logger.error err
        else
          logger.info "successfully inserted #{filtered.length} people"
        cb(err)
      )
    )
  #end syncPeople
  
  syncCount = (cb) ->
    db.collection('people').find().toArray (err, people) ->
      articles = db.collection "parsedArticle"
      articleCount = db.collection 'articleCount'
      async.each(people, (p, next) ->
        articles.find({personId: p._id}).count (err, c) ->
          el = {personId: p._id, hostname: "www.appledaily.com.tw", count: c}
          articleCount.update({personId: el.personId, hostname: el.hostname }
          , {$set: el}, {w:1, upsert: true}, next)
      , (err) -> cb(err))


  syncDb = (cb = ->) ->
    logger.info "syncing db"
    async.series [syncPeople, syncCount], (err) ->
      if err
        logger.error "Error while syncing: #{sys.inspect err}"
      return cb(err)
    return
  #end syncDb


  ################################################################################  
  # returns an array containg all the people in the db (shouldn't be more than
  # a few hundred small object, no memory issue here)
  ################################################################################  
  findPeople = (cb = ->) ->
    peopleColl.find().toArray cb

  
  ################################################################################  
  # returns a stream of item with the given name
  ################################################################################  
  findArticlesForPerson = (personId, cb = ->) ->
    # logger.debug "objectId: #{BSON.ObjectID
    articleColl.find({personId: new BSON.ObjectID(personId)}).stream()

  countArticle = (personId, cb = ->) ->
    articleCount = db.collection 'articleCount'
    if typeof personId is BSON.ObjectID
      id = personId
    else
      id = BSON.ObjectID(personId)
    articleCount.findOne({personId: id}, (err, {count}) -> cb(err,count))

      

  upsertResults = (toSave, cb=->) ->
    collection = db.collection('parsedArticle')
    async.map(toSave, (el, next)->
      collection.update({date: el.date, personId: el.personId}
      , {$set: el}, {w:1, upsert: true}, next)
    , cb)
    return
    


  return {
    connect: connect
    getDb: -> db
    getLastError: -> lastError
    close: close
    findPeople: findPeople
    upsertResults: upsertResults
    syncDb: syncDb
    findArticlesForPerson: findArticlesForPerson
    countArticle: countArticle
  }


module.exports = exports = Dao

