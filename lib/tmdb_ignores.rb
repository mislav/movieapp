Tmdb.ignore_ids.tap do |ignored|
  ignored << 57691 # The Ring
  ignored << 58418 # The Ring
  ignored << 70305 # The Simpsons Movie
  ignored << 72906 # "9" 2005 short movie
  ignored << 64430 # Bad Timing (German version)
end

# Sweeney Todd
Tmdb.override_values[37924] = { year: 2006 }
# Porco Rosso
Tmdb.override_values[11621] = { year: 1992 }
