module ApplicationHelper

  def admin?
    logged_in? and current_user.admin?
  end
  
  def nobr(str)
    str.gsub(/ +/, '&nbsp;')
  end
  
  def body_class(*names)
    if names.empty?
      @body_class && @body_class.join(' ')
    else
      (@body_class ||= []).concat names
    end
  end
  
  def twitter_icon(alt = 'Twitter')
    image_tag('twitter.gif', :alt => alt, :class => 'icon')
  end
  
  def facebook_icon(alt = 'Facebook')
    image_tag('facebook.gif', :alt => alt, :class => 'icon')
  end

  def compare_page?
    request.path.start_with? '/compare/'
  end
  
end
