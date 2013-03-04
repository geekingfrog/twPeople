logger = require './logconfig'
Q = require 'q'
MongoClient = require('mongodb').MongoClient
BSON = require('mongodb').BSONPure
twPeople = require './twPeople'

Dao = ->
  if not (this instanceof Dao)
    return new Dao()


  db = null
  lastError = null

  isConnected = -> return db != null

  # returns a promise which resolve with a reference to the db
  connect = ->
    dbConnect = Q.defer()
    MongoClient.connect("mongodb://localhost:27017/celebrities"
    , {w:1}
    , (err, _db) ->
      if err
        lastError = err
        return dbConnect.reject(err)
      else
        logger.info 'successfully connected to the database'
        db = _db
        return dbConnect.resolve(db)
    )
    return dbConnect.promise

  # close the connection to the db. returns a promise
  close = ->
    closeDef = Q.defer()
    if db == null
      closeDef.resolve()
    MongoClient.close -> closeDef.resolve()
    return closeDef

  # get the list of people from the file twPeople.coffee
  # and make sure the collection 'people' has the same content (or more)
  syncDb = ->
    logger.info "syncing db"
    syncDef = Q.defer()
    if db == null
      throw new Error("Not connected, call connect() first")
    dbPeople = db.collection 'people'
    toInsert = twPeople.map (el) ->
      elDef = Q.defer()
      dbPeople.findOne(el, (err, item) ->
        if err
          lastError = err
          elDef.reject(err)
        else if item
          elDef.resolve(null)
        else
          elDef.resolve(el)
      )
      return elDef.promise

    # if toInsert.length is 0
    #   syncDef.resolve()

    Q.spread(toInsert, (items...) ->
      filtered = (i for i in items when i)
      if filtered.length is 0
        logger.info "collection 'people' up to date \\o/"
        return syncDef.resolve()
      else
        logger.info "inserting #{filtered.length} items"
        dbPeople.insert(filtered, {w:1}, (err, res) ->
          if err
            logger.error err
            lastError = err
            syncDef.reject(err)
          else
            syncDef.resolve()
        )
    , (err) -> lastError = err; syncDef.reject(err))
    return syncDef.promise
  #end syncDb


  return {
    isConnected: isConnected
    connect: connect
    syncDb: syncDb
    close: close
    getDb: -> return db
  }

module.exports = exports = Dao
