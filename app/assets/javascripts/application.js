//= require prototype
//= require rails
//*= require_tree .

if ('createTouch' in document) {
  try {
    $A(document.styleSheets).each(function(stylesheet){
      var ignore = /:hover\b/, idxs = []
      $A(stylesheet.cssRules).each(function(rule, idx) {
        if (rule.type == CSSRule.STYLE_RULE && ignore.test(rule.selectorText)) {
          idxs.push(idx)
        }
      })
      idxs.reverse().each(function(idx) { stylesheet.deleteRule(idx) })
    })
  } catch (e) {}
}

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
  if (useTransitions && !Prototype.Browser.Opera) {
    form.select('input[type=submit][data-disable-with]').invoke('removeAttribute', 'data-disable-with')
    
    form.up('.actions').addClassName('fadeout').transitionEnd(function() {
      var parent = this.up()
      this.replaceActions(e.memo.responseText)
      var actions = parent.down('.actions')
      actions.addClassName('hidden')
      ;(function() { actions.removeClassName('hidden').addClassName('fadein') }).defer()
    })
  } else {
    form.up('.actions').replaceActions(e.memo.responseText)
  }
})

document.on('ajax:success', 'a.revert', function(e, link) {
  link.up('.actions').replaceActions(e.memo.responseText)
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
  },
  // preserve the ".other-info" element while replacing ".actions"
  replaceActions: function(element, content) {
    element = $(element)
    var parent = element.up()
    element.replace(content)
    parent.down('.actions').insert({ top: element.down('.js-preserve') })
    return element
  }
})

var useTransitions = Modernizr.csstransitions,
    transitionEvent = Prototype.Browser.WebKit ? 'webkitTransitionEnd' :
                      Prototype.Browser.Opera ? 'oTransitionEnd' : 'transitionend'

if (useTransitions) {
  Element.addMethods({
    addClassNameTransition: function(element, name) {
      element = $(element)
      tmpName = name + '-transition'
      element.addClassName(tmpName).transitionEnd(function() {
        element.removeClassName(tmpName).addClassName(name)
      })
      return element
    },
    removeClassNameTransition: function(element, name) {
      element = $(element)
      tmpName = name + '-transition-back'
      element.removeClassName(name).addClassName(tmpName).transitionEnd(function() {
        element.removeClassName(tmpName)
      })
      return element
    },
    transitionEnd: function(element, handler) {
      element = $(element)
      element.once(transitionEvent, handler)
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

  var scrollHandler = Element.on(Prototype.Browser.WebKit ? document : window, 'scroll', function() {
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

// Emulates HTML5 "placeholder" and "autofocus" attributes.
// from https://github.com/teambox/teambox/blob/master/app/javascripts/html5.js
document.on('dom:loaded', function() {
  if (!window.Modernizr) return
  
  if (!Modernizr.input.placeholder) {
    var selector = 'input[placeholder], textarea[placeholder]'
    
    function emulatePlaceholder(input) {
      var val = input.getValue(), text = input.readAttribute('placeholder')
      if (val.empty() || val === text)
        input.setValue(text).addClassName('placeholder')
    }
    
    document.on('focusin', selector, function(e, input) {
      if (input.getValue() === input.readAttribute('placeholder'))
        input.setValue('').removeClassName('placeholder')
    })
    
    document.on('focusout', selector, function(e, input) {
      emulatePlaceholder(input)
    })
    
    // setup existing fields
    $$(selector).each(emulatePlaceholder)
    
    // observe form submits and clear emulated placeholder values
    $(document.body).on('submit', 'form:has(' + selector + ')', function(e, form) {
      form.select(selector).each(function(field) {
        if (field.getValue() == field.readAttribute('placeholder')) field.setValue('')
      })
    })
    
    // observe new forms inserted into document and setup fields inside
    document.on('DOMNodeInserted', 'form', function(e) {
      if (e.element().match('form')) e.element().select(selector).each(emulatePlaceholder)
    })
  }

  if (!Modernizr.input.autofocus) {
    var input = $(document.body).down('input[autofocus]')
    if (input) input.activate()
  }
})
