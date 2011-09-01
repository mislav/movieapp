pagination = $('.pagination').eq(0)

viewportOffset = (el) ->
  el.offset().top - document.body.scrollTop

if pagination.size()
  page = parseInt(pagination.find('.current').text())
  lastPage = parseInt(pagination.find('a:not(.next_page)').eq(-1).text())
  url = window.location.toString()
  container = $('ol.movies').eq(0)
  loading = false
  scrollElement = if Zepto.browser.webkit then document else window

  $(scrollElement).bind 'scroll', ->
    return if loading
    viewportHeight = document.documentElement.clientHeight
    paginationOffset = viewportOffset(pagination) - viewportHeight

    if paginationOffset < viewportHeight/2
      loading = true
      $.ajax
        method: 'get'
        data:
          page: ++page
        success: (data) ->
          container.append data
          if page is lastPage
            $(scrollElement).unbind 'scroll'
            pagination.hide()
          loading = false
