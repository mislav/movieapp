viewport = $(window)
pagination = $('.pagination').eq(0)

viewportOffset = (el) ->
  el.offset().top - document.body.scrollTop

if pagination.size()
  nextUrl = pagination.find('a[rel=next]').attr 'href'
  container = $('ol.movies').eq(0)
  loading = false

  scrollHandler = ->
    return if loading
    viewportHeight = viewport.height()
    paginationOffset = viewportOffset(pagination) - viewportHeight

    if paginationOffset < viewportHeight/2
      loading = true
      $.ajax
        url: nextUrl
        context: pagination
        success: (data, status, xhr) ->
          container.append data
          unless nextUrl = xhr.getResponseHeader 'X-Next-Page'
            $(document).unbind 'scroll', scrollHandler
            pagination.remove()
          loading = false

  $(document).bind 'scroll', scrollHandler
