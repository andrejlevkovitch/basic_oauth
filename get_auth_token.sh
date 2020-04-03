#!/bin/bash
# set filename with private service info in json as first argument

SERVICE_ACCOUNT_KEY_FILE=$1
if [ -z $SERVICE_ACCOUNT_KEY_FILE ]; then
  echo "you need set service account key file as first argument"
  exit 1
fi


BASE64URL_ENCODER="./base64url"
PRIVATE_KEY_GETTER="./get_private_key_file"
SERVICE_ACCOUNT_GETTER="./get_service_account"
TOKEN_URI_GETTER="./get_token_uri"
TOKEN_GETTER="./get_token_from_output"


SERVICE_ACCOUNT=$(cat $SERVICE_ACCOUNT_KEY_FILE | $SERVICE_ACCOUNT_GETTER)
RSA_KEY_FILE=$(cat $SERVICE_ACCOUNT_KEY_FILE | $PRIVATE_KEY_GETTER)
TOKEN_URI=$(cat $SERVICE_ACCOUNT_KEY_FILE | $TOKEN_URI_GETTER)


# create JWT header and claim
ONE_MINUTE=3600
CURRENT_TIME=$(date +%s)
REQUEST_TIME=$((CURRENT_TIME + ONE_MINUTE))

JWT_HEADER='{"alg":"RS256","typ":"JWT"}'
JWT_CLAIM="{
  \"iss\":\"$SERVICE_ACCOUNT\",
  \"scope\":\"https://www.googleapis.com/auth/firebase.messaging email\",
  \"aud\":\"$TOKEN_URI\",
  \"exp\":$REQUEST_TIME,
  \"iat\":$CURRENT_TIME
}"

JWT_HEADER_ENCODED=$(echo $JWT_HEADER | $BASE64URL_ENCODER)
JWT_CLAIM_ENCODED=$(echo $JWT_CLAIM | $BASE64URL_ENCODER)

# create signature for JWS
# XXX not use echo, because echo append \n character in teh end, so JWT signature will be invalid
JWT_SIGNATURE_ENCODED=$(printf "%s.%s" "$JWT_HEADER_ENCODED" "$JWT_CLAIM_ENCODED" | openssl dgst -sha256 -sign $RSA_KEY_FILE -binary | $BASE64URL_ENCODER)

# get full JWT request
JWT_FULL=$JWT_HEADER_ENCODED"."$JWT_CLAIM_ENCODED"."$JWT_SIGNATURE_ENCODED

# get oauth2 token
GRANT_TYPE="grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer"
OUTPUT=$(curl -X POST \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data "$GRANT_TYPE&assertion=$JWT_FULL" \
  $TOKEN_URI)

TOKEN=$(echo $OUTPUT | $TOKEN_GETTER)
echo $TOKEN
