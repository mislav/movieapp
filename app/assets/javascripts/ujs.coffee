fire = (el, name, data) ->
  event = $.Event(name)
  el.trigger(event, data)
  not event.defaultPrevented

handleRemote = (element) ->
  return unless fire(element, 'ajax:before')
  if element.is('form')
    method = element.attr('method')
    url = element.attr('action')
    data = element.serializeArray()
    # memoized value from clicked submit button
    # TODO: revisit when Zepto data() method supports JS objects
    button = element.get(0)._submitButton
    if button
      data.push button
      element.get(0)._submitButton = null
  else
   method = element.data('method')
   url = element.attr('href')
   data = element.data('params') || null

  ajaxOptions =
    type: method || 'GET'
    data: data
    headers:
      Accept: '*/*;q=0.5, ' + $.ajaxSettings.accepts.script
    beforeSend: (xhr, settings) ->
      element.trigger('ajax:beforeSend', [xhr, settings])
    success: (data, status, xhr) ->
      element.trigger('ajax:success', [data, status, xhr])
    complete: (xhr, status) ->
      element.trigger('ajax:complete', [xhr, status])
    error: (xhr, status, error) ->
      element.trigger('ajax:error', [xhr, status, error])

  ajaxOptions.url = url if url

  token = $('meta[name="csrf-token"]').attr('content')
  ajaxOptions.headers['X-CSRF-Token'] = token if token

  $.ajax(ajaxOptions)

handleMethod = (link) ->
  href = link.attr('href')
  method = link.data('method')
  csrf_token = $('meta[name=csrf-token]').attr('content')
  csrf_param = $('meta[name=csrf-param]').attr('content')
  form = $("<form method='post' action='#{href}'></form>")
  hidden = "<input name='_method' value='#{method}' type='hidden' />"

  if csrf_param? and csrf_token?
    hidden += "<input name='#{csrf_param}' value='#{csrf_token}' type='hidden' />"

  form.hide().append(hidden).appendTo('body')
  form.submit()

disableSelector = 'input[data-disable-with], button[data-disable-with], textarea[data-disable-with]'
enableSelector = 'input[data-disable-with]:disabled, button[data-disable-with]:disabled, textarea[data-disable-with]:disabled'

disableFormElements = (form) ->
  form.find(disableSelector).each ->
    element = $(this)
    method = if element.is('button') then 'html' else 'val'
    element.data('enable-with', element[method]())
    element[method](element.data('disable-with'))
    element.attr('disabled', 'disabled')

enableFormElements = (form) ->
  form.find(enableSelector).each ->
    element = $(this)
    method = if element.is('button') then 'html' else 'val'
    element[method](element.data('enable-with')) if element.data('enable-with')
    element.removeAttr('disabled')

allowAction = (element) ->
  message = element.data('confirm')
  not message or confirm(message)

$(document).delegate 'form[data-remote]', 'submit', (e) ->
  element = $(this)
  handleRemote element if allowAction element
  false

$(document).delegate 'form', 'ajax:beforeSend', (e) ->
  disableFormElements $(this) if this is e.target

$(document).delegate 'form', 'ajax:complete', (e) ->
  enableFormElements $(this) if this is e.target

submitSelector = 'form input[type=submit], form input[type=image], form button[type=submit], form button:not([type])'

$(document).delegate submitSelector, 'click', ->
  button = $(this)
  name = button.attr('name')
  data =
    if name
      name: name
      value: button.val()

  # TODO: revisit when Zepto data() method supports JS objects
  button.closest('form').get(0)._submitButton = data

$(document).delegate 'a[data-remote], a[data-method]', 'click', (e) ->
  element = $(this)
  if allowAction element
    if element.data('remote')
      handleRemote element
    else
      handleMethod element
  false
