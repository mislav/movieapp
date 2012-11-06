$(document).on 'click', '#facebox .netflix_picker article', (e) ->
  if e.which is 1
    $.ajax
      type: 'PUT'
      url:  location.pathname + '/link_to_netflix'
      data: netflix_id: $(this).data('netflix-id')
    $.facebox.close()
  false
