root = exports ? this
root.drawer = do ->
  margin =
    top: 20
    right: 20
    bottom: 30
    left: 50

  width = 900 - margin.right - margin.left
  height = 500 - margin.top - margin.bottom

  root.svg = svg = d3.select("#svgPlaceholder").append("svg")
          .attr("width", width + margin.right + margin.left)
          .attr("height", height + margin.top + margin.bottom)
          .append("g")
          .attr("transform", "translate(#{margin.left},#{margin.top})")


  x = d3.time.scale().range([0, width-90])
  y = d3.scale.linear().range([height, 0])

  colorScale = d3.scale.category20b().domain([0,20])
  fieldColor = d3.scale.category10().domain([0,10])
  root.brighterScale = d3.scale.linear().domain([1,10]).range([0,4])
  colorScale = (fieldId, rankInField) ->
    return d3.rgb(fieldColor(fieldId-1)).brighter(brighterScale(rankInField)).toString()

  xAxis = d3.svg.axis().scale(x).orient('bottom')
  yAxis = d3.svg.axis().scale(y).orient('left')
  line = d3.svg.line()
    .x((d) -> x(d.date))
    .y((d) -> y(d.count))




  graphData = []
  addData = ({person, raw, rank, fieldId, rankInField}, format='%Y%m') ->
    parseDate = d3.time.format(format).parse
    graphData = graphData.concat({
      person: person
      raw: raw.map (el) -> {count: +el.count, date: parseDate(el.date)}
      rank: rank
      fieldId: fieldId
      rankInField: rankInField
    })
    drawLines()

  removeData = (id) ->
    console.log "removing data with id: #{id}"
    graphData = graphData.filter (el) ->
      el.person._id isnt id
    drawLines()

  drawLines = ->
    # svg.select("*").remove()

    if graphData.length and !svg.select("text.yLegend")[0][0]
      svg.append("text")
        .attr("class", "yLegend")
        .attr("transform", "rotate(-90)")
        .attr("y", 6)
        .attr("dy", ".7em")
        .style("text-anchor", "end")
        .text("#articles / month")

    if graphData.length
      xRanges = graphData.map((person) -> d3.extent(person.raw, (d) -> d.date))
      x.domain [d3.min(xRanges, (d) -> d[0]), d3.max(xRanges, (d) -> d[1])]
      
      yRanges = graphData.map((person) -> d3.extent(person.raw, (d) -> d.count))
      y.domain [0, d3.max(yRanges, (d) -> d[1])]
    else
      x.domain([0,0])
      y.domain([0,0])


    isXaxis = svg.select("g.x.axis")[0][0] #null if no axis
    if isXaxis
      svg.select("g.x.axis").call(xAxis)
    else
      svg.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0, #{height})")
        .call(xAxis)


    isYaxis = svg.select("g.y.axis")[0][0] #null if no axis
    if isYaxis
      svg.select("g.y.axis")
        .transition()
        .duration(500)
        .call(yAxis)
    else
      svg.append("g").attr("class", "y axis")
        .call(yAxis)


    people = svg.selectAll(".people")
      .data(graphData, (d) -> d.rank)

    people.selectAll(".line")
      .transition()
      .duration(500)
      .attr("d", (d) -> line(d.raw))
    people.selectAll("text")
      .transition()
      .duration(500)
      .attr("transform", (d) -> "translate(+#{x(d.value.date)},+#{y(d.value.count)})")
    
    enteringGroup = people.enter()
      .append("g")
      .attr("class", "people")

    enteringLines = enteringGroup.append("path")
      .attr("class", "line")
      .attr("stroke", (d, i) -> colorScale(d.fieldId, d.rankInField))


    people.exit()
      .transition()
      .duration(500)
      .style("stroke-opacity", 1e-6)
      .style("fill-opacity", 1e-6)
      .remove()


    draw = (k) ->
      # people.enter()#.selectAll("path")
      enteringLines.attr("d", (d) -> line(d.raw.slice(0,k)))
     
    k = 0; n = d3.max(graphData, (p) -> p.raw.length)
    d3.timer ->
      draw(k)
      k += 2
      if k >= n-1
        draw(n-1)
        drawTextForEnteringLine()
        return true

    drawTextForEnteringLine = () ->
      enteringGroup.append("text")
        .datum( (d) -> {
          name: d.person.name
          value: d.raw[d.raw.length-1]
          color: colorScale(d.fieldId, d.rankInField)
          })
        .attr("transform", (d) -> "translate(+#{x(d.value.date)},+#{y(d.value.count)})")
        .style("fill", (d) -> d.color)
        .text( (d) -> d.name)
  #end draw line
        

  return {
    addData: addData
    removeData: removeData
  }



$(document).ready ->

  mapPeople = {}
  getPeopleDef = $.getJSON("stats/person/")
  people = []
  getPeopleDef.then (allPeople) ->
    root.p = allPeople

    allPeople.sort (a,b) -> b.count - a.count
    people = allPeople.slice(0,20)

    fields = ({field: f, people: p} for f, p of people.reduce(
      (acc, curr) ->
        curr.field.forEach (f) -> if acc[f] then acc[f].push curr else acc[f] = [curr]
        return acc
    , {})).map (el) ->
      el.people.sort (a,b) -> b.count - a.count
      return el


    source = $("#leftMenuH").html()
    template = Handlebars.compile(source)
    $("#leftMenu").append(template({fields: fields}))

    $("#leftMenu li").each bindClickHandler

  bindClickHandler = -> $(this).click (ev) ->
    $(this).toggleClass('active')
    id = $(this).attr('data-personId')
    rankInField = 1+$(this).prevAll('li').length
    fieldId = 1+$(this).parent().prevAll('ul').length

    if $(this).hasClass('active')
      $.getJSON("stats/person/#{id}/month").done (raw) ->
        rank = people.length
        people.some (el, index) ->
          if el._id == id
            rank = index+1
            return true
          return false

        data =
          person: people[rank-1]
          raw: raw.slice(0, -1) #remove the last month (incomplete)
          rank: rank
          fieldId: fieldId
          rankInField: rankInField

        drawer.addData data
    else
      drawer.removeData(id)


  getPeopleDef.then -> $("#leftMenu li:first").click()






