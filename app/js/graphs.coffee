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

  colorScale = d3.scale.category10()
  xAxis = d3.svg.axis().scale(x).orient('bottom')
  yAxis = d3.svg.axis().scale(y).orient('left')
  line = d3.svg.line()
    .x((d) -> x(d.date))
    .y((d) -> y(d.count))


  graphData = []
  addData = ({person, raw}, format='%Y%m') ->
    parseDate = d3.time.format(format).parse
    graphData = graphData.concat({
      person: person
      raw: raw.map (el) -> {count: +el.count, date: parseDate(el.date)}
    })
    drawLines()

  removeData = (id) ->
    console.log "removing data with id: #{id}"
    graphData = graphData.filter (el) ->
      el.person._id isnt id
    drawLines()

  drawLines = ->
    svg.select("*").remove()

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
    svg.selectAll(".people").remove()

    peopleRaw = svg.selectAll(".people")
      .data(graphData)

    peopleRaw.exit().remove()
    people = peopleRaw.enter()
      .append("g")
      .attr("class", "people")

    people.append("path")
      .attr("stroke", (d, i) -> colorScale(i))
      .attr("d", (d) -> line(d.raw))
      .attr("class", "line")

    people.append("text")
      .datum( (d) -> {
        name: d.person.name+' '+d.person.english
        value: d.raw[d.raw.length-1]
        })
      .attr("transform", (d) -> "translate(+#{x(d.value.date)},+#{y(d.value.count)})")
      .attr("x", 3)
      .attr("dy", ".35em")
      .text( (d) -> d.name)

  #end draw line
        

  return {
    addData: addData
    removeData: removeData
  }




