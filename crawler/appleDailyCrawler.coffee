http = require 'http'
_ = require 'underscore'
sys = require 'sys'
async = require 'async'
url = require 'url'
cheerio = require 'cheerio'
logger = (require '../logConfig')
moment = require 'moment'


AppleDailyCrawler = ->
  if not (this instanceof AppleDailyCrawler)
    return new AppleDailyCrawler()

  hostname = "www.appledaily.com.tw"

  date = null

  # return an array of url which point to the articles for the given date
  getLinksForDate = (_date, cb) ->
    date = _date
    options =
      hostname: hostname
      path: "/appledaily/archive/#{_date}"
    executeGet(options, (err, {headers, body}) ->
      if err
        return cb(err)
      links = getLinksFromHtml(body)
      cb(err, links)
    )

  # returns an object:
  #   headers: the received headers
  #   body: the complete body of the response
  # error if the response code is not 200
  # if there is a network error, will retry 2 more times before giving up
  executeGet = (options, cb = ->) ->
    executeWithRetry = (retry) ->
      req = http.get options, (res) ->
        body = ""
        res.setEncoding 'utf8'
        res.on 'data', (chunk) -> return body += chunk
        res.on 'end', ->
          return cb(null, {headers: res.headers, body: body})
      req.on 'error', (err) ->
        if retry < 3
          retry++
          logger.warn "got an error with #{JSON.stringify(options)}: #{sys.inspect err}\n
          retrying (#{retry}/3 attempts)"
          return executeWithRetry(retry)
        else
          logger.error "got error when executeGet with options:
            #{JSON.stringify(options)}, #{sys.inspect err}"
          return cb(err)
    executeWithRetry(0)
    return



  # parse the body and returns an array of links to archives
  getLinksFromHtml = (body) ->
    $ = cheerio.load(body)
    links = []
    $('a').each ->
      href = $(this).attr 'href'
      links.push href if href
    processed = processLinks links
    return processed

  # transform relative links into full url
  # eg:
  #  ./article.html -> http://www.appledaily.com.tw/article.html
  # also remove links which do not point to an archive
  processLinks = (links) ->
    filtered = _.filter links, (l) -> l? and l.indexOf(date)>-1
    properLinks = filtered.map (el) ->
      return el if el.slice(0,4) is 'http'
      return 'http://'+hostname+el
    return _.uniq(properLinks)
      
  # returns the html of the article for a given link
  getContentFromLink = (link, cb = ->) ->
    parsed = url.parse(link)
    options =
      hostname: parsed.hostname
      path: parsed.path
    
    getContent = (body) ->
      $ = cheerio.load(body)
      content = ''
      $('.articulum').find('p,span,h2').each -> content += $(this).text()
      return content
      
    executeGet(options, (err, {headers, body}) ->
      if err
        return cb(err)
      content = getContent(body)
      cb(null, content)
    )
    return

  # It first fetch the list of articles for the given date
  # and then get all of them (5 in parallel)
  #
  # returns an array of article for the given date
  # reject if any http.get error in the process
  getArticlesForDate = (date, next = ->) ->
    logger.info "getting articles for the date: ", date
    getLinksForDate(date, (err, links) ->
      logger.debug "got #{links.length} links for #{date}"
      articles = []
      async.eachLimit(links, 10, (link, cb) ->
        getContentFromLink(link, (err, content) ->
          return cb(err) if err
          articles.push(content)
          cb()
        )
      , (err) ->
        if err then next(err) else next(null, articles)
      )
    )
    return


  return {
    getLinksForDate: getLinksForDate
    getContentFromLink: getContentFromLink
    getArticlesForDate: getArticlesForDate
    hostname: hostname
  }

module.exports = exports = AppleDailyCrawler
