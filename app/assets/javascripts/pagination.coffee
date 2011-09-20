viewport = $(window)
pagination = $('.pagination').eq(0)

viewportOffset = (el) ->
  el.offset().top - document.body.scrollTop

if pagination.size()
  page = parseInt(pagination.find('.current').text())
  lastPage = parseInt(pagination.find('a:not(.next_page)').eq(-1).text())
  url = window.location.toString()
  container = $('ol.movies').eq(0)
  loading = false

  scrollHandler = ->
    return if loading
    viewportHeight = viewport.height()
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
            $(document).unbind 'scroll', scrollHandler
            pagination.hide()
          loading = false

  $(document).bind 'scroll', scrollHandler
