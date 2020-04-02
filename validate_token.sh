#!/bin/bash
# set token as first argument

TOKEN=$1


HOST=https://oauth2.googleapis.com
URI="tokeninfo"

curl -X GET \
  $HOST"/"$URI"?access_token=$TOKEN"
