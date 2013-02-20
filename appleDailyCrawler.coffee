http = require 'http'
_ = require 'underscore'
sys = require 'sys'
async = require 'async'
url = require 'url'
cheerio = require 'cheerio'
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
    req.on 'error', (err) -> console.log "got error: ", err

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
    console.log 'get content for: ', link
    parsed = url.parse(link)
    options =
      hostname: parsed.hostname
      path: parsed.path
    
    getContent = (body) ->
      $ = cheerio.load(body)
      content = ''
      $('.articulum p,span,h2').each ->
        content += $(this).text()
      
    chainedCb = ->
      res = getContent.call(this,arguments)
      cb(res) if cb?
    executeGet options, chainedCb


  ######################################################################  
  # find all links on the given node and its descendants
  # return an array of links' data (empty array if no links are found)
  ######################################################################  
  findLinks = (o) ->
    return [] if !o or _.isEmpty(o)
    link = []
    if o.type is 'tag' and o.name is 'a'
      link = [o.data]
    childrenLinks = []
    children = o.children or []
    # if o.children
    childrenLinks = _.flatten(children.map (child) -> findLinks(child))
    return link.concat childrenLinks

  return {
    collectLinks: collectLinks
    getContentFromLink: getContentFromLink
  }

testDate = '20130220'
crawl = new appleDailyCrawler()
crawl.collectLinks(testDate, (links) ->
  fullContent = ''
  start = new Date().getTime()
  async.eachLimit links, 5, (item, cb) ->
    errCb = (res) ->
      if res then cb() else cb(res)
    crawl.getContentFromLink(item, errCb)
  , (err) ->
    end = new Date().getTime()
    console.log "complete all the fetching for #{testDate} in #{end-start}"
)
