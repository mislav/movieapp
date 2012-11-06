$(document).on 'click', '#facebox .netflix_picker article', (e) ->
  if e.which is 1
    $.ajax
      type: 'PUT'
      url:  location.pathname + '/link_to_netflix'
      data: netflix_id: $(this).data('netflix-id')
    $.facebox.close()
  false

$(document).on 'click', '#facebox .poster_picker article', (e) ->
  if e.which is 1
    images = $(this).find('img')
    params =
      movie:
        poster_medium_url: images.eq(0).attr('src')
        poster_small_url:  images.eq(1).attr('src')

    $.ajax
      type: 'PUT'
      url:  location.pathname
      data: JSON.stringify(params)
      contentType: 'application/json'

    # prevents bug in Chrome where we remain scrolled completely off page
    window.scrollTo 0
    $.facebox.close()

    $('.movie img.poster').attr('src', params.movie.poster_medium_url)
  false
