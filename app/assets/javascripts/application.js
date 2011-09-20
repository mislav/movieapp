//= require zepto
//= require ujs
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
