Tmdb.ignore_ids.tap do |ignored|
  ignored << 57691 # The Ring
  ignored << 58418 # The Ring
end

# Sweeney Todd
Tmdb.override_values[37924] = { year: 2006 }