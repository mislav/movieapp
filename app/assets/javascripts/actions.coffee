$(document).delegate '.actions input[type=submit].watched', 'click', ->
  $(this).closest('.actions').addClass('asking')
  false

$(document).delegate '.actions input[type=submit].watched', 'ajax:before', ->
  false

$(document).delegate '.actions .question a[href="#cancel"]', 'click', ->
  $(this).blur().closest('.actions').removeClass('asking')
  false

$(document).delegate '.actions .button_to', 'ajax:success', (e, html) ->
  replaceActions $(this).closest('.actions'), html

$(document).delegate 'a.revert', 'ajax:success', (e, html) ->
  replaceActions $(this).closest('.actions'), html

# preserve the ".other-info" element while replacing ".actions"
replaceActions = (element, content) ->
  parent = element.parent()
  element.replaceWith(content)
  preserve = element.find('.js-preserve')
  parent.find('.actions').eq(0).prepend preserve
