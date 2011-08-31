module UsersHelper
  def username_with_icon(user)
    [].tap { |out|
      out << twitter_icon if user.from_twitter?
      out << facebook_icon if user.from_facebook?
      out << link_to_user(user)
    }.join(' ').html_safe
  end
  
  def user_name(user)
    user.name.presence || user.username
  end
  
  def link_to_user(user)
    link_to(user.username, watched_path(user), :title => user.name)
  end
  
  def my_page?
    logged_in? and current_user == @user
  end
  
  def my_watchlist?
    controller.action_name == 'to_watch' and my_page?
  end
  
  def watched_liked(movie, user = nil)
    who = user ? user.name : 'You'
    liked = user ? movie.liked? : current_user.watched.rating_for(movie)
    
    "#{who} watched this movie".tap do |out|
      unless liked.nil?
        if liked
          out << %( and <em class="liked">#{nobr 'liked it'}</em>)
        else
          out << %(, but <em class="disliked">#{nobr "didn't like it"}</em>)
        end
      end
      # out << '.'
    end.html_safe
  end
  
  def list_of_people(users, options = {})
    limit = options[:limit] || 3
    listed = users[0, limit].map { |user| link_to_user(user) }
    rest = users.size - limit
    listed << pluralize(rest, options[:other] || 'other') if rest > 0
    listed.to_sentence.html_safe
  end
  
  def positive(user)
    positive = user.watched.liked.count * 100 / user.watched.count
    %(<em class="liked">#{positive}%</em> positive).html_safe
  end
  
  def hater(user)
    hater = user.watched.disliked.count * 100 / user.watched.count
    %(<em class="disliked">#{hater}%</em> hater).html_safe
  end
  
  def life_wasted(user)
    minutes = user.watched.minutes_spent
    hours = (minutes / 60.0).round

    if (hours < 48) then %(<em>#{hours}</em> hours).html_safe
    else %(<em>#{(minutes / 60.0 / 24).round}</em> days).html_safe
    end
  end
  
end
