module UsersHelper
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
      out << '.'
    end.html_safe
  end
end
