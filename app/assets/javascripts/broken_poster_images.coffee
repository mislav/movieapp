numProcessed = 0

processImage = ->
  if this.naturalWidth is 0
    link = $(this).parent 'a[href]'
    if link.length
      $.ajax
        url: link.attr('href') + '/broken_poster'
        type: 'put'
        context: this
        success: (data) => $(this).replaceWith data

detectBrokenPosterImages = ->
  images = $('img.poster').slice numProcessed
  numProcessed += images.length
  for img in images
    if img.complete then processImage.call img
    else $(img).on 'load error', processImage

$(document).on 'ajaxSuccess', '.pagination', detectBrokenPosterImages
$(window).on 'load', detectBrokenPosterImages
