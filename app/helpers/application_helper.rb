module ApplicationHelper
  
  def nobr(str)
    str.gsub(/ +/, '&nbsp;')
  end
  
end
