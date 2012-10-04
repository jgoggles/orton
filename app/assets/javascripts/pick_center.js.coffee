$ ->
  $("td").hover (->
    team = $(this).siblings(".team").text()
    spread = $(this).siblings(".spread").text()
    col = $(this).parent().children().index(this)
    heading = $("#header_row th").eq(col).text()
    $("#tooltip").text(team + "(" + spread + "), " + heading)
  ), ->
