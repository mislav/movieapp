# Emulates HTML5 "placeholder" and "autofocus" attributes.
# from https://github.com/teambox/teambox/blob/master/app/javascripts/html5.js
$ ->
  return unless window.Modernizr

  unless Modernizr.input.placeholder
    inputs = $('input[placeholder], textarea[placeholder]')

    emulatePlaceholder = (input) ->
      val = input.val()
      text = input.attr('placeholder')
      if not val or val is text
        input.val(text).addClass 'placeholder'

    inputs.live 'focusin', ->
      input = $(this)
      if input.val() is input.attr('placeholder')
        input.val('').removeClass 'placeholder'

    inputs.live 'focusout', ->
      emulatePlaceholder $(this)

    # setup existing fields
    inputs.each ->
      emulatePlaceholder $(this)

    $(document).delegate "form:has(#{inputs.selector})", 'submit', ->
      $(this).find(inputs.selector).each ->
        input = $(this)
        input.val('') if input.val() is field.attr('placeholder')

    # observe new forms inserted into document and setup fields inside
    $(document).delegate 'form', 'DOMNodeInserted', (e) ->
      el = $(this)
      if el.is('form')
        el.find(inputs.selector).each ->
          emulatePlaceholder $(this)

  unless Modernizr.input.autofocus
    input = $('input[autofocus]').eq(0)
    if input.size()
      input.focus()
      input.get(0).select()
