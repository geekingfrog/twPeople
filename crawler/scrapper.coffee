logger = require '../logConfig'
sys = require 'sys'
AppleDailyCrawler = require './appleDailyCrawler'
Dao = require '../mongo/dao'
moment = require 'moment'
async = require 'async'
_ = require 'underscore'
argv = require('optimist').argv

dao = new Dao()

if argv.h
  console.log "supply start date and end date with --start and --end, the format is YYYYMMDD"
  return

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

async.series([dao.connect, dao.syncDb, dao.findPeople], (err, results) ->
  [db, __, people] = results
  startTime = Date.now()
  start = moment(''+argv.start,'YYYYMMDD')
  end = moment(''+argv.end, 'YYYYMMDD')
  # end = start.clone().subtract('d', 5)
  # end = moment('20030502', 'YYYYMMDD')

  current = moment(start)
  dates = []
  while current.isAfter(end) or current.isSame(end)
    dates.push current.format('YYYYMMDD')
    current.subtract('d',1)

  format = 'YYYYMMDD'
  logger.info "going after #{dates.length} dates
  from #{start.format(format)} to #{end.format(format)}"
  totalPeople = 0
  async.eachLimit(dates, 1, (date, cb) ->
    crawler = new AppleDailyCrawler()
    startCrawl = new Date().getTime()
    crawler.getArticlesForDate(date, (err, articles) ->
      if err
        logger.error "error for date #{date}, #{err}"
        return cb()
      timeCrawl = (new Date().getTime())-startCrawl
      logger.info "got #{articles.length} articles for #{date} in #{timeCrawl} ms"
      parsed = huntForPeople(people, articles)
      logger.debug "got #{parsed.length} people for this date"
      toSave = parsed.map (el) ->
        o =
          host: crawler.hostname
          date: date
          personId: el._id
          count: el.count
        return o
      totalPeople += toSave.length
      collection = dao.getDb().collection('parsedArticle')
      dao.upsertResults(toSave, cb)
    )
  , (err) ->
    if err
      logger.error err
    else
      totalTime = Date.now() - startTime
      logger.info "scrapping completed in #{totalTime} ms, got #{totalPeople} people"
      process.exit(0)
  )
)

