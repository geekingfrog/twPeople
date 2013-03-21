express = require "express"
dao = new (require "../mongo/dao")()
logger = require "../logConfig"
sys = require "sys"
async = require 'async'
xtend = require 'xtend'

port = process.env.VCAP_APP_PORT or 4444

dao.connect (err, _db) ->
  if err
    return logger.error "couldn't connect to the DB #{err}"
  dao.syncDb (err) ->
    return logger.error "Error while syncing the db : #{sys.inspect err}" if err
    logger.info "DB successfully synced"



app = express()
# app.use express.logger
# app.use express.compress

app.use (req, res, next)->
  logger.debug "#{new Date()} \t #{req.method} #{req.url}"
  return next()
app.use(express.compress())

sendServerError = (res, err) ->
  logger.debug sys.inspect err
  res.send 500, "Something blew up -_-' \n #{err}"

# app.use express.directory('js')
# app.use("/js",  express.directory(__dirname+'/js'))
app.use("/js",  express.static(__dirname+'/js'))
app.use("/css",  express.static(__dirname+'/css'))
app.use("/", express.static(__dirname))

# app.get "/", (req, res) ->
#   res.sendfile "#{__dirname}/index.html", (err) ->
#     if err
#       console.log "error: ", err
#     else
#       console.log "got file"
#   return

app.get "/test", (req,res) ->
  return res.send "pong #{port}"


app.get "/stats/person/", (req, res) ->
  dao.findPeople (err, people) ->
    if err
      return sendServerError(res, err)
    else
      start = Date.now()
      async.map(people, (person, cb) ->
        dao.countArticle(person._id.toString(), (err, count) ->
          return cb err, xtend(person, {count: count})
        )
      , (err, peopleCount) ->
        return sendServerError(res, err) if err
        logger.debug "counted all people articles in #{Date.now() - start} ms"
        return res.send(peopleCount)
      )

app.get "/stats/person/:id", (req, res) ->
  id = req.params.id
  stream = dao.findArticlesForPerson(id)
  data = []
  stream.on 'data', (item) ->
    data.push {date: item.date, count: item.count}
  stream.on 'end', ->
    data.sort (a,b) -> +a.date - +b.date
    res.send(data)



# super basic cache, never expire. Change that later if it start consuming
# too much memory
basicCache = {}

app.get "/stats/person/:id/month", (req, res) ->
  id = req.params.id

  if basicCache[id]
    logger.debug "cache hit, returning data"
    return res.send basicCache[id].data

  logger.debug "cache miss looking for article with person id = #{id}"
  stream = dao.findArticlesForPerson(id)
  dict = {}
  start = Date.now()
  stream.on 'data', (item) ->
    # logger.debug sys.inspect item
    yyyymm = item.date.slice(0, -2)
    tmp = dict[yyyymm]
    dict[yyyymm] = if tmp then tmp+item.count else item.count

  stream.on 'end', ->
    logger.debug "Got data after #{Date.now() - start} ms"
    logger.debug "no more records"
    tab = for date, count of dict
      {date: date, count: count}
    tab.sort (a,b) -> +a.date - +b.date
    basicCache[id] = {data: tab, t: Date.now()}
    res.send tab





app.listen port
logger.info "listening on port port"

