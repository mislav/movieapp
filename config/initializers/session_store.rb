# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key    => '_movies_session',
  :secret => 'd485de517da9dbdf772fa01f0c28ae4a3efeca8ab3d9f39763619eb6fe8b8314ac395dd06e42ae54eabe946479c947338b862556b88348fccdbec826cca53b1f'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
