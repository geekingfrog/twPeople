root = exports ? this
root.drawer = do ->
  margin =
    top: 20
    right: 20
    bottom: 30
    left: 50

  width = 960 - margin.right - margin.left
  height = 500 - margin.top - margin.bottom

  svg = d3.select("#svgPlaceholder").append("svg")
          .attr("width", width + margin.right + margin.left)
          .attr("height", height + margin.top + margin.bottom)
          .append("g")
          .attr("transform", "translate(#{margin.left},#{margin.top})")

  x = d3.time.scale().range([0, width])
  y = d3.scale.linear().range([height, 0])

  xAxis = d3.svg.axis().scale(x).orient('bottom')
  yAxis = d3.svg.axis().scale(y).orient('left')
  line = d3.svg.line()
    .x((d) -> x(d.date))
    .y((d) -> y(d.count))


  drawLine= (raw, format) ->
    parseDate = d3.time.format(format).parse
    data = raw.map (el) -> {date: parseDate(el.date), count: +el.count}

    x.domain(d3.extent(data, (d) -> d.date))
    y.domain(d3.extent(data, (d) -> d.count))

    svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0, #{height})")
      .call(xAxis)

    svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)

    svg.append("path")
      .datum(data)
      .attr("class", "line")
      .attr("d", line)


  return {drawLine: drawLine}




