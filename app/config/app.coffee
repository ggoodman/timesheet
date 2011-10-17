# Main Application Config
# -----------------------
# Optional config files can be added to /config/environments/<SS_ENV>.coffee (e.g. /config/environments/development.coffee)
# giving you the opportunity to override each setting on a per-environment basis
# Tip: Type 'SS.config' into the SocketStream Console to see the full list of possible config options and view the current settings

exports.config =

  # HTTP server (becomes secondary server when HTTPS is enabled)
  http:
    port:         process.env.C9_PORT
    hostname:     "0.0.0.0"
  
  # HTTPS server (becomes primary server if enabled)
  https:
    enabled:      false
    port:         443
    domain:       "www.socketstream.org"

  # Redis support. Must be enabled before hosting your app!
  # Install Redis 2.2 or above from http://redis.io/ then run 'redis-server'
  redis:
    enabled:      false

  # HTTP(S) request-based API module
  api:
    enabled:      false
    prefix:       'api'
    https_only:   false
  
  # Load balancing. Install ZeroMQ (type 'socketstream help' for info) then set suitable TCP values for your network once you're ready to run across multiple boxes
  #cluster:
  #  sockets:
  #    fe_main:    "tcp://10.0.0.10:9000"
  #    fe_pub:     "tcp://10.0.0.10:9001"
  #    be_main:    "tcp://10.1.1.10:9000"