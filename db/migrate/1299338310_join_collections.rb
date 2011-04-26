Mingo::Migration.define do
  describe %(
    Removes embedded info about movies watched and to-watch from User documents
    and saves it to separate, 'join collections' named "watched" and "to-watch"
    where each document has a reference to both user and movie.
  )
  
  users = db.collection('User')
  watched = users['watched']
  to_watch = users['to_watch']

  # now to define a migration:
  migrate do
    matched_users = users.find('$or' => [{:watched => {'$exists' => true}}, {:to_watch => {'$exists' => true}}])
    matched_users.each do |user|
      user_created_at = user['_id'].generation_time
      user_watched = Array(user['watched'])
      user_to_watch = Array(user['to_watch'])
      
      user_watched.each do |watched_data|
        doc = {'movie_id' => watched_data['movie'], 'liked' => watched_data['liked'], 'user_id' => user['_id']}
        time = watched_data['time']
        doc[:_id] = BSON::ObjectId.from_time(time || user_created_at, :unique => true)
        watched.save doc
      end
      
      user_to_watch.each do |movie_id|
        doc = {'movie_id' => movie_id, 'user_id' => user['_id']}
        to_watch.save doc
      end
      
      users.update({:_id => user['_id']},
        '$set' => {'to_watch_count' => user_to_watch.size, 'watched_count' => user_watched.size}
      )
    end
    
    users.update({}, {'$unset' => {'watched' => 1, 'to_watch' => 1}}, :multi => true)
    
    index_args = [[['movie_id', Mongo::ASCENDING], ['user_id', Mongo::ASCENDING]], {:unique => true, :drop_dups => true}]
    watched.create_index(*index_args)
    to_watch.create_index(*index_args)
    
    puts "Status: %d watched, %d to watch" % [watched.size, to_watch.size]
  end

  # reverse operation:
  revert do
    users.find.each do |user|
      user_id = user['_id']
      embed_watched = watched.find({:user_id => user_id}, :sort => '_id').map do |watched_data|
        {'movie' => watched_data['movie_id'], 'liked' => watched_data['liked'], 'time' => watched_data['_id'].generation_time}
      end
      embed_to_watch = to_watch.find({:user_id => user_id}, :sort => '_id').map { |d| d['movie_id'] }
      
      users.update({:_id => user['_id']}, '$set' => {'watched' => embed_watched, 'to_watch' => embed_to_watch})
    end
    
    users.update({}, {'$unset' => {'watched_count' => 1, 'to_watch_count' => 1}}, :multi => true)
    
    watched.drop
    to_watch.drop
  end
end
