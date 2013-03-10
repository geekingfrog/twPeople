logger = require './logconfig'
# Q = require 'q'
MongoClient = require('mongodb').MongoClient
BSON = require('mongodb').BSONPure
ObjectID = require('mongodb').ObjectID
sys = require 'sys'



class CbDao
  constructor: ->
    @db = null

  connect: (cb = (->))->
    logger.debug 'connecting'
    MongoClient.connect("mongodb://localhost:27017/celebrities"
    , {w:1} , cb )
    return

tester =
  getPeople: (db, cb) ->
    return db.collection('people').find().toArray(cb)

  iterateOver: (a, cb) ->
    a.forEach (el) -> cb.call(this, el)

  countForPerson: (db, person, cb) ->
    id = ObjectID(person._id.toString())
    articles = db.collection('parsedArticle')
    articles.count {personId: id}, cb
    return

class SyncCB
  # callback to be called when all registered callback have been completed
  constructor: (@cb, context = this) ->
    n = 0
    started = false
    args = []
    @addCb = ->
      n++
      started = true
      return
    @done = (res) ->
      return if not started
      n--
      args.push res
      if n is 0 and started
        return cb.apply(context, args)

    @abort = -> console.log "aborting the sync"


cbDao = new CbDao()
cbDao.connect (err, db) ->
  if err
    logger.error err
    return
  printRes = ->
    logger.debug "so far so good"
    logger.debug "printRes args: #{sys.inspect arguments}"

  # db.collection('people').update({name: '麻吉'}, {$set: {english: 'Machi'}}, {w:1}, (err, cb) ->)

  logger.debug 'connected to the database'
  tester.getPeople db, (err, people) ->
    if err
      logger.error err
      return

    logger.debug "got people: #{people.length}"

    printInOrder = (peopleCount...) ->
      indexOfNameIn = (name, array) ->
        for p, i in array
          return i if p.person.name is name
        return -1

      duplicateFree = []
      for p in peopleCount
        if indexOfNameIn(p.person.name, duplicateFree) is -1
          duplicateFree.push p

      duplicateFree.sort (a, b) -> a.count - b.count
      n = duplicateFree.length
      for p, i in duplicateFree
        logger.debug "#{n-i} \t #{p.count}\t#{p.person.name}/#{p.person.english} \t #{p.person.field}"

    sync = new SyncCB(printInOrder)
    people.forEach (person) ->
      sync.addCb()
      tester.countForPerson(db, person, (err, count) ->
        if err
          logger.error err
          sync.abort()
          return
        # logger.debug "got #{count} articles for #{person.name}, #{person.english}"
        sync.done({person: person, count: count})
        return
      )
      return
  


