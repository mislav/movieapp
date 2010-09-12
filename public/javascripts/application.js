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
