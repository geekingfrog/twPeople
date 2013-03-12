$(document).ready ->
  # $.getJSON("stats/person/513c363cf21fa12c11000063").done (data) ->
  #   console.log data
  #   drawer.drawLine(data, '%Y%m%d')

  $.getJSON("stats/person/513c363cf21fa12c11000063/month").done (data) ->
    drawer.drawLine(data, '%Y%m')


