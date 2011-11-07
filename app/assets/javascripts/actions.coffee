$(document).on
  click: ->
    $(this).closest('.actions').addClass('asking')
    false
  ajaxBeforeSend: -> false
, '.actions input[type=submit].watched'

$(document).on 'click', '.actions .question a[href="#cancel"]', ->
  $(this).blur().closest('.actions').removeClass('asking')
  false

$(document).on 'ajaxSuccess', '.actions .button_to', (e, xhr, settings, html) ->
  replaceActions $(this).closest('.actions'), html

$(document).on 'ajaxSuccess', 'a.revert', (e, xhr, settings, html) ->
  replaceActions $(this).closest('.actions'), html

# preserve the ".other-info" element while replacing ".actions"
replaceActions = (element, content) ->
  parent = element.parent()
  element.replaceWith(content)
  preserve = element.find('.js-preserve')
  parent.find('.actions').eq(0).prepend preserve
