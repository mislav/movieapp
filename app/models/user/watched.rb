module User::Watched
  def watched(options = nil)
    # memoize the default association, not ones created with custom options
    return @watched if options.nil? and defined?(@watched)
    association = Association.new(self, :watched, options || {})
    @watched = association if options.nil?
    association
  end

  class Association < User::MoviesAssociation
    def rate_movie(movie, liked)
      liked = case liked.downcase
        when 'yes', 'true', '1' then true
        when 'no', 'false', '0' then false
        else nil
        end if liked.respond_to? :downcase

      if link_doc = link_to_movie(movie)
        collection.update({_id: link_doc['_id']}, '$set' => {'liked' => liked})
      else
        insert movie_id: movie.id, user_id: @user.id, liked: liked
      end
    end

    def rating_for(movie)
      link_to_movie(movie)['liked']
    end

    def liked(options = {})
      self.dup.where(liked: true)
    end

    def disliked(options = {})
      self.dup.where(liked: false)
    end

    def minutes_spent
      movie_ids = link_documents.map { |doc| doc['movie_id'] }
      result = Movie.collection.aggregate([
        {
          '$match' => { _id: {'$in' => movie_ids} },
        },
        {
          '$group' => { _id: nil, minutes: { '$sum' => '$runtime' } }
        },
      ], cursor: {})

      result.first['minutes']
    end

    private

    def insert(link_doc)
      if result = super
        # remove matching movie from `to_watch` list
        @user.to_watch.delete link_doc[:movie_id]
      end
      result
    end
  end
end
