document.on('click', '.actions input[type=submit].watched', function(e, button) {
  e.stop()
  button.up('.actions').addClassNameTransition('asking')
})
document.on('ajax:before', '.actions input[type=submit].watched', function(e) { e.stop() })

document.on('click', '.actions .question a[href="#cancel"]', function(e, link) {
  e.stop()
  link.blur()
  link.up('.actions').removeClassNameTransition('asking')
})

document.on('ajax:success', '.actions .button_to', function(e, form) {
  if (useTransitions) {
    form.up('.actions').addClassName('fadeout').once('webkitTransitionEnd', function() {
      var parent = this.up()
      this.replace(e.memo.responseText)
      var actions = parent.down('.actions')
      actions.addClassName('hidden')
      ;(function() { actions.removeClassName('hidden').addClassName('fadein') }).defer()
    })
  } else {
    form.up('.actions').replace(e.memo.responseText)
  }
})

Element.addMethods({
  getText: function(element) {
    element = $(element)
    return element.textContent || element.innerHTML.stripTags()
  },
  once: function(element, event, selector, fn) {
    element = $(element)
    if (!fn) { fn = selector, selector = null }
    
    var handler, executed = false, wrapper = function() {
      if (!executed) {
        fn.apply(this, arguments)
        executed = true
        handler.stop()
      }
    }
    if (selector) handler = element.on(event, selector, wrapper)
    else handler = element.on(event, wrapper)
    
    return handler
  }
})

var useTransitions = Modernizr.csstransitions && Prototype.Browser.WebKit

if (useTransitions) {
  Element.addMethods({
    addClassNameTransition: function(element, name) {
      element = $(element)
      tmpName = name + '-transition'
      element.addClassName(tmpName).once('webkitTransitionEnd', function() {
        element.removeClassName(tmpName).addClassName(name)
      })
      return element
    },
    removeClassNameTransition: function(element, name) {
      element = $(element)
      tmpName = name + '-transition-back'
      element.removeClassName(name).addClassName(tmpName).once('webkitTransitionEnd', function() {
        element.removeClassName(tmpName)
      })
      return element
    }
  })
} else {
  Element.addMethods({
    addClassNameTransition: Element.addClassName,
    removeClassNameTransition: Element.removeClassName
  })
}

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
