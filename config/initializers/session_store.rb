# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_movieproject_session',
  :secret      => 'e57280c1957d11754d591b9eb6bc78f1ed3ff14e8c7bbc59cc274c1267e5c1360fd8a19d171f101ae76c667f88cbd7dad4ddd0dd2a91e761ad5a3a3f10d5ea2f'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
