#!/bin/bash

if [ -z "${NGROK_API_KEY}" ]; then

    RED='\033[0;31m'
    NC='\033[0m' # No Color

    echo ""
    printf "${RED}NGROK_API_KEY is not set !${NC}\nPlease get an API Key from ngrok. https://dashboard.ngrok.com/api\n"

    echo "  And, set the value like this:"
    echo "       export NGROK_API_KEY=\"your_ngrok_API_key\" ./$(basename "$0")"
    echo "  or, pass the apikey as a Parameter like this:"
    echo "      NGROK_API_KEY=\"Your Key\" ./$(basename "$0") \"edghts_id*\" \"{\\\"body\\\":\\\"Custom Body Here\\\"}"
    echo ""
    exit 0
fi

#Need Label
if [ -z "$1" ]; then
    printf "${RED}Label Missing${NC}, an argument is required, please provide a alphanumeric Label like below\n"
    echo "       ./$(basename "$0") YourLabelHere "
    echo ""

    exit 1
fi

if [ ! -f "ca-cert.pem" ]; then
    echo "We need your Certificate Authority PEM file, named \"ca-cert.pem\", I can't find that\n\n"

    ########### Generating Certificates !!

    # use keygen.sh to generate Keys (Only works on MacOs)
    # Based on this: https://github.com/ngrok-patrick/Jenky-CA-Script

    ########### End Generating Certificates !!

    exit 1
fi

CA_CERT_PEM="ca-cert.pem"    #file that has the CA Cert.. could be an argument

#Get Label, Edge and Domain name
EMAIL=$1
EDGELABEL=(${EMAIL//@/ })

# UPLOAD CERTIFICATE ============

#prepare certificate for import
#  *remove newlines and carriage returns
#  Change " to \"

cat $CA_CERT_PEM | tr '\n\r' '\t' | sed 's/\t/\\n/g' >$CA_CERT_PEM.tmp
CACERT=$(cat $CA_CERT_PEM.tmp)
echo $CACERT
rm $CA_CERT_PEM.tmp #clean up file when done

result=$(curl --location "https://api.ngrok.com/certificate_authorities" --header "Authorization: Bearer $NGROK_API_KEY" --header "Content-Type: application/json" --header "Ngrok-Version: 2" --data "{\"description\":\"${TESTINGTIMESTAMP}\",\"metadata\":\"{\\\"internal_id\\\": \\\"72\\\"}\",\"ca_pem\":\"$CACERT\"}")

echo ${result} # for testing
results=$(jq '.id' <<<"${result}")
CA_AUTHORITY_ID=$(sed "s/\"//g" <<<"${results}")

echo $CA_AUTHORITY_ID # Need this to put a Bow on Edge, and give it a mutualTLS CA !

# END UPLOAD CERTIFICATE ============
NGROKAPIKEY="$NGROK_API_KEY"
BACKENDTUNNELGROUP1=''
BACKENDHTTPRESPONSE2=''
BACKENDFAILOVER3=''
RESERVEDDOMAIN4=''
CREATEHTTPSEDGE5=''
AUTHTOKEN=''
DOMAIN="$EDGELABEL.ngrok.app"

echo $DOMAIN

## Create Tunnel Backend
echo "Create Tunnel Backend"

curl --location --request POST 'https://api.ngrok.com/backends/tunnel_group' \
    --header "Authorization: Bearer $NGROKAPIKEY" \
    --header 'Content-Type: application/json' \
    --header 'Ngrok-Version: 2' \
    --data-raw '{"description":"edge tunnel group","metadata":"{\"environment\": \"middle_earth\"}","labels":{"edge":"'"$EDGELABEL"'"}}' \
    -o CreateTunnelBackend.json

read BACKENDTUNNELGROUP1 <<<$(jq '.id' CreateTunnelBackend.json | tr -d '"')
echo "Backend Tunnel Group:$BACKENDTUNNELGROUP1"

## Create HTTP Response
echo "Create HTTP Response"

curl --location --request POST 'https://api.ngrok.com/backends/http_response' \
    --header "Authorization: Bearer $NGROKAPIKEY" \
    --header 'Content-Type: application/json' \
    --header 'Ngrok-Version: 2' \
    --data-raw '{
  "body": "<div id='\''main'\''><div class='\''fof'\''><h1>Error 404</h1></div><p> Not all those who wander are lost. However, I do believe you are.</p></div>",
  "description": "404 Response",
  "headers": {
    "content-type": "text/html; charset=UTF-8"
  },
  "metadata": "",
  "status_code": 404
}' \
    -o BACKENDHTTPRESPONSE2.json

read BACKENDHTTPRESPONSE2 <<<$(jq '.id' BACKENDHTTPRESPONSE2.json | tr -d '"')
echo "Backend Http Response:$BACKENDHTTPRESPONSE2"

## Backend Failover
echo "Backend Failover"

curl --location --request POST 'https://api.ngrok.com/backends/failover' \
    --header "Authorization: Bearer $NGROKAPIKEY" \
    --header 'Content-Type: application/json' \
    --header 'Ngrok-Version: 2' \
    --data-raw '{
    "description": "Customer failover mirkwood_edge",
    "metadata": "{\"environment\": \"middle_earth\"}",
    "backends": [
        "'"$BACKENDTUNNELGROUP1"'",
        "'"$BACKENDHTTPRESPONSE2"'"
    ]
}' \
    -o BACKENDFAILOVER3Response.json

read BACKENDFAILOVER3 <<<$(jq '.id' BACKENDFAILOVER3Response.json | tr -d '"')
echo "Backend Failover Response:$BACKENDFAILOVER3"

## Create Reserved Domain
echo "Create Reserved Domain"

curl --location --request POST 'https://api.ngrok.com/reserved_domains' \
    --header "Authorization: Bearer $NGROKAPIKEY" \
    --header 'Ngrok-Version: 2' \
    --header 'Accept: application/json' \
    --header 'Content-Type: application/json' \
    --data-raw '{
    "name": "'"$DOMAIN"'"
}' \
    -o RESERVEDDOMAIN4Response.json

read RESERVEDDOMAIN4 <<<$(jq '.id' RESERVEDDOMAIN4Response.json | tr -d '"')
echo "Reserved Domain Response:$RESERVEDDOMAIN4"

## Create Https Edge
echo "Create Https Edge"

curl --location --request POST 'https://api.ngrok.com/edges/https' \
    --header "Authorization: Bearer $NGROKAPIKEY" \
    --header 'Content-Type: application/json' \
    --header 'Ngrok-Version: 2' \
    --data-raw '{
    "description": "Sauron Edge",
    "metadata": "{\"environment\": \"middle_earth\"}",
    "hostports": [
        "'"$DOMAIN"':443"
    ]
}' \
    -o CREATEHTTPSEDGE5.json

read CREATEHTTPSEDGE5 <<<$(jq '.id' CREATEHTTPSEDGE5.json | tr -d '"')
echo "Create Https Edge:$CREATEHTTPSEDGE5"

##Create HTTPS Edge Route
echo "Create HTTPS Edge Route"

curl --location -g --request POST "https://api.ngrok.com/edges/https/$CREATEHTTPSEDGE5/routes" \
    --header "Authorization: Bearer $NGROKAPIKEY" \
    --header 'Content-Type: application/json' \
    --header 'Ngrok-Version: 2' \
    --data-raw '{
    "backend": {
        "backend_id": "'"$BACKENDFAILOVER3"'",
        "enabled": true
    },
    "circuit_breaker": null,
    "compression": null,
    "description": "",
    "edge_id": "'"$CREATEHTTPSEDGE5"'",
    "ip_restriction": null,
    "match": "/",
    "match_type": "path_prefix",
    "metadata": "",
    "oauth": null,
    "oidc": null,
    "request_headers": null,
    "response_headers": null,
    "saml": null,
    "webhook_verification": null,
    "websocket_tcp_converter": null
}' -o CREATEHTTPSROUTE.json

# Update edghts with Mutual TLS
TLS_URL="https://api.ngrok.com/edges/https/${CREATEHTTPSEDGE5}/mutual_tls"

curl --location --request PUT ${TLS_URL} --header "Authorization: Bearer $NGROKAPIKEY" --header "Content-Type: application/json" --header "Ngrok-Version: 2" --data "{\"enabled\":true,\"certificate_authority_ids\":[\""${CA_AUTHORITY_ID}"\"]}"

echo "\n\nScript completed, created a Edge named: https://${DOMAIN}\n\n"
echo "Example using Curl: curl https://${DOMAIN} --key server-key.pem --cert server-cert.pem"
