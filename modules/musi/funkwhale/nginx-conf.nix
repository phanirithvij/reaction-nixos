{
  cfg
}:
''
upstream funkwhale-api {
    # depending on your setup, you may want to update this
    server api:5000;
}


# required for websocket support
map $http_upgrade $connection_upgrade {
    default upgrade;
    \'\'      close;
}

server {

    location /staticfiles/ {
        # django static files
        alias ${STATIC_ROOT}/;
    }
}
''
