logger = require './logconfig'
sys = require 'sys'
Q = require 'q'
AppleDailyCrawler = require './appleDailyCrawler'
Dao = require './dao'
moment = require 'moment'
async = require 'async'
_ = require 'underscore'

dao = new Dao()
getPeople = ->
  peopleDef = Q.defer()
  collection = dao.getDb().collection('people').find().toArray (err, people) ->
    if err then peopleDef.reject(err) else peopleDef.resolve(people)
  return peopleDef.promise

# returns an array of object representing the people present in the articles
# each object has the following keys:
#  name
#  english
#  field
#  count: the number of article with this person
# @params people: an array of people to look for in
# @params articles: the articles
huntForPeople = (people, articles) ->
  occ = []
  people.forEach (person) ->
    r = new RegExp(person.name, 'gi')
    count = 0
    articles.forEach (article) ->
      count++ if r.test(article)
    if count
      tmp = _.clone person # shallow copy ! (enough here)
      tmp.count = count
      occ.push tmp
    return
  return occ



dao.connect().then(dao.syncDb).then(getPeople).then (people) ->
  startTime = Date.now()
  start = moment()
  end = moment('20030502', 'YYYYMMDD')

  console.log 'end: ', end.format('YYYYMMDD')
  current = moment(start)
  dates = []
  while current.isAfter(end) or current.isSame(end)
    current.subtract('d',1)
    dates.push current.format('YYYYMMDD')

  async.eachLimit(dates, 1, (date, cb) ->
    crawler = new AppleDailyCrawler()
    startCrawl = new Date().getTime()
    archives = crawler.getArticlesForDate(date)
    archives.fail -> logger.error arguments
    archives.then (articles) ->
      timeCrawl = (new Date().getTime())-startCrawl
      logger.info "got #{articles.length} articles for #{date} in #{timeCrawl} ms"
      parsed = huntForPeople(people, articles)
      logger.debug "got #{parsed.length} interesting articles"
      toSave = parsed.map (el) ->
        o =
          host: crawler.hostname
          date: date
          personId: el._id
          count: el.count
        return o
      collection = dao.getDb().collection('parsedArticle')
      saved = toSave.map (el) ->
        elDef = Q.defer()
        collection.update({date: el.date, personId: el.personId}
        , {$set: el}, {w:1, upsert: true}, (err) ->
          if err then elDef.reject(err) else elDef.resolve()
        )
        return elDef.promise
      Q.all(saved).then((-> return cb()),(-> console.log 'some errors...'; return cb(1)))

      
  , (err) ->
    if err
      logger.error err
    else
      totalTime = Date.now() - startTime
      logger.info "scrapping completed in #{totalTime} ms"
      process.exit(0)
  )

