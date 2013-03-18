root = exports ? this
root.drawer = do ->
  margin =
    top: 20
    right: 20
    bottom: 30
    left: 50

  width = 900 - margin.right - margin.left
  height = 500 - margin.top - margin.bottom

  svg = d3.select("#svgPlaceholder").append("svg")
          .attr("width", width + margin.right + margin.left)
          .attr("height", height + margin.top + margin.bottom)
          .append("g")
          .attr("transform", "translate(#{margin.left},#{margin.top})")


  x = d3.time.scale().range([0, width-90])
  y = d3.scale.linear().range([height, 0])

  colorScale = d3.scale.category20b().domain([0,20])
  xAxis = d3.svg.axis().scale(x).orient('bottom')
  yAxis = d3.svg.axis().scale(y).orient('left')
  line = d3.svg.line()
    .x((d) -> x(d.date))
    .y((d) -> y(d.count))


  graphData = []
  addData = ({person, raw, rank}, format='%Y%m') ->
    parseDate = d3.time.format(format).parse
    graphData = graphData.concat({
      person: person
      raw: raw.map (el) -> {count: +el.count, date: parseDate(el.date)}
      rank: rank
    })
    drawLines()

  removeData = (id) ->
    console.log "removing data with id: #{id}"
    graphData = graphData.filter (el) ->
      el.person._id isnt id
    drawLines()

  drawLines = ->
    # svg.select("*").remove()

    if graphData.length
      xRanges = graphData.map((person) -> d3.extent(person.raw, (d) -> d.date))
      x.domain [d3.min(xRanges, (d) -> d[0]), d3.max(xRanges, (d) -> d[1])]
      
      yRanges = graphData.map((person) -> d3.extent(person.raw, (d) -> d.count))
      y.domain [0, d3.max(yRanges, (d) -> d[1])]
      # x.domain(d3.max(graphData, (p) -> d3.extent(p.raw, (d) -> d.date)))
      # y.domain([0,d3.max(graphData, (p) -> d3.extent(p.raw, (d) -> d.count))])
    else
      x.domain([0,0])
      y.domain([0,0])
    # y.domain(d3.extent(flat, (d) -> d.count))


    isXaxis = svg.select("g.x.axis")[0][0] #null if no axis
    if isXaxis
      svg.select("g.x.axis").call(xAxis)
    else
      svg.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0, #{height})")
        .call(xAxis)

    # svg.append("g")
    #   .attr("class", "y axis")
    #   .call(yAxis)

    isYaxis = svg.select("g.y.axis")[0][0] #null if no axis
    if isYaxis
      svg.select("g.y.axis")
        .transition()
        .duration(500)
        .call(yAxis)
    else
      svg.append("g").attr("class", "y axis")
        .call(yAxis)

    console.log 'graphData: ', graphData

    people = svg.selectAll(".people")
      .data(graphData, (d) -> d.rank)

    console.log "update: ", people
    console.log "enter: ", people.enter()
    console.log "exit: ", people.exit()

    console.log "updated lines: ", people.selectAll(".line")
    people.selectAll(".line")
      .transition()
      .duration(500)
      .attr("d", (d) -> line(d.raw))
    
    enteringGroup = people.enter()
      .append("g")
      .attr("class", "people")

    enteringLines = enteringGroup.append("path")
      .attr("class", "line")
      .attr("stroke", (d) -> console.log "stroke color: ", colorScale(d.rank), d.rank; colorScale(d.rank))
      # .attr("d", (d) -> line(d.raw))

    enteringGroup.append("text")
      .datum( (d) -> {
        name: d.person.name+' '+d.person.english
        value: d.raw[d.raw.length-1]
        })
      .attr("transform", (d) -> "translate(+#{x(d.value.date)},+#{y(d.value.count)})")
      .attr("x", 3)
      .attr("dy", ".35em")
      .text( (d) -> d.name)


    people.exit()
      .transition()
      .duration(500)
      .style("stroke-opacity", 1e-6)
      .style("fill-opacity", 1e-6)
      .remove()

    # people.transition()
    #   .attr("d", line)

    # people = people.enter()
    #   .append("g")
    #   .attr("class", "people")

    # enteringLine = people.append("path")
    #   .attr("stroke", (d, i) -> colorScale(d.rank))
    #   # .attr("d", (d) -> line(d.raw))
    #   .attr("class", "line")


    draw = (k) ->
      # people.enter()#.selectAll("path")
      enteringLines.attr("d", (d) -> line(d.raw.slice(0,k)))
     
    k = 0; n = d3.max(graphData, (p) -> p.raw.length)
    d3.timer ->
      draw(k)
      k += 2
      if k >= n-1
        draw(n-1)
        return true

  #end draw line
        

  return {
    addData: addData
    removeData: removeData
  }






$(document).ready ->
  # $.getJSON("stats/person/513c363cf21fa12c11000063").done (data) ->
  #   console.log data
  #   drawer.drawLine(data, '%Y%m%d')

  # $.getJSON("stats/person/513c363cf21fa12c11000063/month").done (data) ->
  #   drawer.drawLine(data, '%Y%m')

  mapPeople = {}
  $.getJSON("stats/person/").done (allPeople) ->

    allPeople.sort (a,b) -> b.count - a.count
    people = allPeople.slice(0,20)
    console.log "people at the beginning: ", people

    source = $("#leftMenuH").html()
    template = Handlebars.compile(source)
    $("#leftMenu").append(template({people: people}))

    $("[type=checkbox]").each (el) -> $(this).click (el,ev) ->
      id = $(this).closest('li').attr('id')
      if $(this).is(':checked')
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

          drawer.addData data
      else
        drawer.removeData(id)








