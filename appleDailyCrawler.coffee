http = require 'http'
_ = require 'underscore'
sys = require 'sys'
async = require 'async'
url = require 'url'
cheerio = require 'cheerio'
logger = (require './logconfig')
twPeople = require './twPeople'
Q = require 'q'
moment = require 'moment'


AppleDailyCrawler = ->
  if not (this instanceof AppleDailyCrawler)
    return new AppleDailyCrawler()

  hostname = "www.appledaily.com.tw"

  date = null

  # returns a promise
  # resolve to an array of url which point to the articles for the given date
  # reject if there is an IO error from the http.get
  getLinksForDate = (_date, cb) ->
    def = Q.defer()
    date = _date
    options =
      hostname: hostname
      path: "/appledaily/archive/#{_date}"

    # chainedCb = ->
    #   res = getLinksFromHtml.apply(this, arguments)
    #   cb(res)
    # executeGet(options, chainedCb)
    tocDef = executeGet(options)
    tocDef.then(({body}) ->
      return getLinksFromHtml(body)
    ).then (links) -> def.resolve(links)
    tocDef.fail (err) -> def.reject(err)
    return def.promise

  # returns a promise
  # resolve to
  #   headers: the received headers
  #   body: the complete body of the response
  # reject if the error code is not 200
  # if there is a network error, will retry 2 more times before giving up
  executeGet = (options) ->
    def = Q.defer()
    executeWithRetry = (retry = 0) ->
      req = http.get options, (res) ->
        body = ""
        res.setEncoding 'utf8'
        res.on 'data', (chunk) -> return body += chunk
        res.on 'end', ->
          return def.resolve {headers: res.headers, body: body}
      req.on 'error', (err) ->
        if retry < 3
          retry++
          logger.warn "got an error with #{JSON.stringify(options)}: #{sys.inspect err}\n
          retrying (#{retry}/3 attempts)"
          return executeWithRetry(retry)
        else
          logger.error "got error when executeGet with options:
            #{JSON.stringify(options)}, #{sys.inspect err}"
          return def.reject(err)
    executeWithRetry(0)
    return def.promise



  # parse the body and returns an array of links to archives
  getLinksFromHtml = (raw) ->
    $ = cheerio.load(raw)
    links = []
    $('a').each ->
      href = $(this).attr 'href'
      links.push href if href

    processLinks links

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
      
  # returns a promise
  # resolve to the html of the article for a given link
  getContentFromLink = (link) ->
    parsed = url.parse(link)
    options =
      hostname: parsed.hostname
      path: parsed.path
    
    getContent = (body) ->
      $ = cheerio.load(body)
      content = ''
      $('.articulum').find('p,span,h2').each ->
        content += $(this).text()
      return content
      
    # chainedCb = (raw) ->
    #   res = getContent(raw)
    #   cb(res) if cb?
    # executeGet options, chainedCb

    contentDef = Q.defer()
    archivePage = executeGet(options)
    archivePage.then ({body}) ->
      content = getContent body
      contentDef.resolve(content)
    archivePage.fail (err) -> contentDef.reject(err)
    return contentDef.promise

  # returns a promise
  # It first fetch the list of articles for the given date
  # and then get all of them (5 in parallel)
  #
  # resolve to an array of article for the given date
  # reject if any http.get error in the process
  getArticlesForDate = (date) ->
    logger.info "getting articles for the date: ", date
    articlesDef = Q.defer()
    linksPromise = getLinksForDate(date)
    linksPromise.then (links) ->
      logger.debug "got #{links.length} links for #{date}"
      articles = []
      async.eachLimit(links, 5, (link, cb) ->
        archive = Q.defer()
        getContentFromLink(link).then( (content) ->
          articles.push(content)
          cb()
        , cb)
      , (err) ->
        if err
          articlesDef.reject(err)
        else
          articlesDef.resolve(articles)
      )
    linksPromise.fail (err) -> articlesDef.reject(err)

    return articlesDef.promise


  return {
    getLinksForDate: getLinksForDate
    getContentFromLink: getContentFromLink
    getArticlesForDate: getArticlesForDate
    hostname: hostname
  }

module.exports = exports = AppleDailyCrawler
