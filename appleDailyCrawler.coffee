http = require 'http'
_ = require 'underscore'
sys = require 'sys'
async = require 'async'
url = require 'url'
cheerio = require 'cheerio'
logger = (require './logconfig').logger
mongo = require 'mongodb'
Server = mongo.Server
Db = mongo.Db
BSON = mongo.BSONPure
server = new Server 'localhost', 27017, {auto_reconnect: true}
db = new Db 'articles', server


appleDailyCrawler = ->

  hostname = "www.appledaily.com.tw"

  date = null

  collectLinks = (_date, cb) ->
    date = _date
    options =
      hostname: hostname
      path: "/appledaily/archive/#{_date}"

    chainedCb = ->
      res = getLinksFromHtml.apply(this, arguments)
      cb(res)
    executeGet(options, chainedCb)

  executeGet = (options, cb) ->
    req = http.get options, (res) ->
      body = ""
      res.setEncoding 'utf8'
      res.on 'data', (chunk) -> body += chunk
      res.on 'end', ->
        cb.call(this, body)
        req.on 'error', (err) ->
          logger.error 'got error when executeGet with options: '+JSON.stringify(options), err

  getLinksFromHtml = (raw) ->
    $ = cheerio.load(raw)
    links = []
    $('a').each ->
      href = $(this).attr 'href'
      links.push href if href

    processLinks links

  processLinks = (links) ->
    filtered = _.filter links, (l) -> l? and l.indexOf(date)>-1
    properLinks = filtered.map (el) ->
      return el if el.slice(0,4) is 'http'
      return 'http://'+hostname+el
    return _.uniq(properLinks)
      
  getContentFromLink = (link, cb) ->
    # logger.debug 'get content for: ', link
    parsed = url.parse(link)
    options =
      hostname: parsed.hostname
      path: parsed.path
    
    getContent = (body) ->
      $ = cheerio.load(body)
      content = ''
      $('.articulum p,span,h2').each ->
        content += $(this).text()
      return content
      
    chainedCb = (raw) ->
      res = getContent(raw)
      cb(res) if cb?
    executeGet options, chainedCb


  return {
    collectLinks: collectLinks
    getContentFromLink: getContentFromLink
    hostname: hostname
  }

testDate = '20130220'
crawl = new appleDailyCrawler()
crawl.collectLinks(testDate, (links) ->
  fullContent = ''
  start = new Date().getTime()
  async.eachLimit links.slice(0, 1), 5, (item, cb) ->
    errCb = (res) ->
      logger.debug "res from getContenFromLink: ", item
      console.log crawl.hostname
      # console.log sys.inspect(res)
      if res then cb() else cb(res)
    crawl.getContentFromLink(item, errCb)
  , (err) ->
    end = new Date().getTime()
    logger.info "complete all the fetching for #{testDate} in #{end-start}"
)


