//= require zepto
//= require rails
//= require_tree .
//= require facebox

$.facebox.settings.loadingImage = '/assets/facebox-loading.gif'
$.facebox.settings.closeImage ='/assets/facebox-close.png'

$.fn.outerWidth = function() {
  return this[0] && this[0].offsetWidth;
}

var origTrigger = $.fn.trigger
$.fn.trigger = function(event, data) {
  if (typeof event == 'string') event = event.replace(/\..+$/, '')
  return origTrigger.call(this, event, data)
}

$(function(){
  $('a[rel*=facebox]').facebox()
})

$(document).delegate('#facebox .netflix_picker article', 'click', function(e) {
  if (e.which == 1) {
    var netflixId = $(this).data('netflix-id')
    $.facebox.close()
    quickPost(location.pathname + '/link_to_netflix?netflix_id=' + netflixId, 'put')
  }
  return false;
})

function quickPost(href, method) {
  var csrf_token = $('meta[name=csrf-token]').attr('content'),
    csrf_param = $('meta[name=csrf-param]').attr('content'),
    form = $("<form method='post' action='" + href + "'></form>"),
    hidden = ''

  if (method) hidden += "<input name='_method' value='" + method + "' type='hidden' />"

  if (csrf_param && csrf_token)
    hidden += "<input name='" + csrf_param + "' value='" + csrf_token + "' type='hidden' />"

  form.hide().append(hidden).appendTo(document.body)
  form.submit()
}
