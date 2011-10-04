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
    # some usernames are numeric Facebook IDs, don't show them
    if user.username =~ /\D/
      link_to(user.username, watched_path(user), :title => user.name)
    else
      link_to(user.name, watched_path(user))
    end
  end
  
  def my_page?
    logged_in? and current_user == @user
  end
  
  def my_watchlist?
    controller.action_name == 'to_watch' and my_page?
  end
  
  def watched_liked(movie, user = nil, link = false)
    who = link ? link_to_user(user) : user ? user.name : 'You'
    liked = if block_given? then yield
      elsif user then movie.liked?
      else
        current_user.watched.rating_for(movie)
      end
    
    "#{who} ".tap do |out|
      unless liked.nil?
        if liked
          out << %(<em class="liked">#{nobr 'liked it'}</em>)
        else
          out << %(<em class="disliked">#{nobr "didn't like it"}</em>)
        end
      else out << nobr("watched it")
      end
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

    amount = if (hours < 48) then %(<em>#{hours}</em> hours)
    else %(<em>#{(minutes / 60.0 / 24).round}</em> days)
    end

    %(<span title="Total time spent watching these movies">#{amount}</span>).html_safe
  end
  
  def link_to_compare(user1, user2)
    compat = User::Compare.compatibility(user1, user2)
    link_to "<span>compatibility: </span><em>#{show_compatibility(compat)}</em>".html_safe,
      compare_path("#{user1.username}+#{user2.username}"), class: 'compare'
  end

  def show_compatibility(num)
    num ? number_to_percentage(num, precision: 0) : 'none'
  end
end
