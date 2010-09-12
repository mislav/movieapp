document.on('click', '.actions input[type=submit].watched', function(e, button) {
  e.stop()
  button.up('.actions').addClassName('asking')
})

document.on('click', '.actions .question a[href="#cancel"]', function(e, link) {
  e.stop()
  link.blur()
  link.up('.actions').removeClassName('asking')
})

document.on('ajax:success', '.actions .button_to', function(e, form) {
  form.up('.actions').replace(e.memo.responseText)
})

Element.addMethods({
  getText: function(element) {
    element = $(element)
    return element.textContent || element.innerHTML.stripTags()
  }
})

Function.prototype.throttle = function(t) {
  var timeout, scope, args, fn = this, tick = function() {
    fn.apply(scope, args)
    timeout = null
  }
  return function() {
    scope = this
    args = arguments
    if (!timeout) timeout = setTimeout(tick, t)
  }
}

var pagination = $$('.pagination').first()

if (pagination) {
  var page = parseInt(pagination.down('em').getText()),
      lastPage = parseInt(pagination.select('a:not(.next_page)').last().getText()),
      url = window.location.toString(),
      container = $$('ol.movies').first(),
      loading = false
  
  var scrollHandler = document.on('scroll', function() {
    if (loading) return
    var viewportHeight = document.viewport.getHeight()
    
    if (pagination.viewportOffset().top - viewportHeight < viewportHeight/2) {
      loading = true
      new Ajax.Request(url, {
        method: 'get', parameters: {page: ++page},
        onSuccess: function(r) {
          container.insert(r.responseText)
          if (page == lastPage) {
            scrollHandler.stop()
            pagination.hide()
          }
          loading = false
        }
      })
    }
  })
}
