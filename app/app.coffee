express = require "express"
dao = new (require "../mongo/dao")()
logger = require "../logConfig"
sys = require "sys"
async = require 'async'
xtend = require 'xtend'

dao.connect (err, _db) ->
  if err
    return logger.error "couldn't connect to the DB #{err}"



app = express()
# app.use express.logger
# app.use express.compress

app.use (req, res, next)->
  logger.debug "#{new Date()} \t #{req.method} #{req.url}"
  return next()

sendServerError = (res, err) ->
  res.send 500, "Something blew up -_-' \n #{err}"

# app.use express.directory('js')
# app.use("/js",  express.directory(__dirname+'/js'))
app.use("/js",  express.static(__dirname+'/js'))
app.use("/css",  express.static(__dirname+'/css'))

app.get "/", (req, res) ->
  console.log 'sending file ?'
  res.sendfile "#{__dirname}/index.html", (err) ->
    if err
      console.log "error: ", err
    else
      console.log "got file"
  return

app.get "/stats/person/", (req, res) ->
  dao.findPeople (err, people) ->
    if err
      return sendServerError(err)
    else
      async.map(people, (person, cb) ->
        dao.countArticle(person._id.toString(), (err, count) ->
          return cb err, xtend(person, {count: count})
        )
      , (err, peopleCount) ->
        return sendServerError(res, err) if err
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



app.get "/stats/person/:id/month", (req, res) ->
  id = req.params.id
  logger.debug "looking for article with person id = #{id}"
  stream = dao.findArticlesForPerson(id)
  dict = {}
  i = 0
  stream.on 'data', (item) ->
    # logger.debug sys.inspect item
    yyyymm = item.date.slice(0, -2)
    tmp = dict[yyyymm]
    dict[yyyymm] = if tmp then tmp+item.count else item.count

  stream.on 'end', ->
    logger.debug "no more records"
    tab = for date, count of dict
      {date: date, count: count}
    tab.sort (a,b) -> +a.date - +b.date
      
    res.send tab





app.listen 4444
logger.info "listening on port 4444"

