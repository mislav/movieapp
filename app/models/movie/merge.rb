module Movie::Merge
  # TODO: slim down this method
  def merge!(*records)
    options = records.extract_options!
    movie_ids = records.map { |m| BSON::ObjectId.from_object m }
    fields = %w[ title tmdb_id imdb_id netflix_id wikipedia_title ]

    target, *dups = find(movie_ids, fields: fields).to_a
    dups_ids = dups.map(&:id)

    # delete duplicates
    collection.remove _id: {'$in' => dups_ids}

    if options.fetch(:inherit, true)
      # slurp useful metadata from movies that were deleted
      for field in fields
        if target.send(field).blank?
          if value = dups.map { |m| m.send(field) }.compact.first
            target.send("#{field}=", value)
          end
        end
      end
      target.save
    end

    watched_collection = User.collection['watched']
    to_watch_collection = User.collection['to_watch']
    watches = watched_collection.find(:movie_id => {'$in' => movie_ids}).sort(:_id).to_a
    users_to_update = []
    good_watches, watches_to_fix = watches.partition {|watched| watched['movie_id'] == target.id }

    sanitize_records = -> records {
      records.each_with_object([]) do |doc, to_remove|
        user = doc['user_id']
        if good_watches.find { |w| w['user_id'] == user }
          # this user has already watched this movie
          to_remove << doc['_id']
          users_to_update << user
        else
          # this record's movie_id will be updated
          good_watches << doc
        end
      end
    }

    # sanitize records in "watched" collection
    watches_to_remove = sanitize_records.(watches_to_fix)

    watched_collection.remove(_id: {'$in' => watches_to_remove}) if watches_to_remove.any?
    watched_collection.update({ movie_id: {'$in' => dups_ids} }, {'$set' => {movie_id: target.id}}, :multi => true)

    plans = to_watch_collection.find(:movie_id => {'$in' => movie_ids}).sort(:_id).to_a
    good_plans, plans_to_fix = plans.partition {|doc| doc['movie_id'] == target.id }
    good_watches.concat good_plans

    # sanitize records in "to watch" collection
    plans_to_remove = sanitize_records.(plans_to_fix)

    to_watch_collection.remove(_id: {'$in' => plans_to_remove}) if plans_to_remove.any?
    to_watch_collection.update({ movie_id: {'$in' => dups_ids} }, {'$set' => {movie_id: target.id}}, :multi => true)

    User.find(users_to_update.uniq).each do |user|
      user.reset_counter_caches!
    end
  end
end
