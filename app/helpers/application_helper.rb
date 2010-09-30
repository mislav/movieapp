module ApplicationHelper
  
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
  
end
