#!/usr/bin/env bash

print_usage()
{
    printf "Adds a SPARQL SELECT query.\n"
    printf "\n"
    printf "Usage:  %s options [TARGET_URI]\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the admin application\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
    printf "\n"
    printf "  --label LABEL                        Label of the query\n"
    printf "  --comment COMMENT                    Description of the query (optional)\n"
    printf "\n"
    printf "  --uri URI                            URI of the query (optional)\n"
    printf "  --query-file ABS_PATH                Absolute path to the text file with the SPARQL query string\n"
    printf "  --service SERVICE_URI                URI of the SPARQL service specific to this query (optional)\n"
}

hash turtle 2>/dev/null || { echo >&2 "turtle not on \$PATH.  Aborting."; exit 1; }

args=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -f|--cert-pem-file)
        cert_pem_file="$2"
        shift # past argument
        shift # past value
        ;;
        -p|--cert-password)
        cert_password="$2"
        shift # past argument
        shift # past value
        ;;
        -b|--base)
        base="$2"
        shift # past argument
        shift # past value
        ;;
        --label)
        label="$2"
        shift # past argument
        shift # past value
        ;;
        --comment)
        comment="$2"
        shift # past argument
        shift # past value
        ;;
        --uri)
        uri="$2"
        shift # past argument
        shift # past value
        ;;
        --query-file)
        query_file="$2"
        shift # past argument
        shift # past value
        ;;
        --service)
        service="$2"
        shift # past argument
        shift # past value
        ;;
        *)    # unknown arguments
        args+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done
set -- "${args[@]}" # restore args

if [ -z "$cert_pem_file" ] ; then
    print_usage
    exit 1
fi
if [ -z "$cert_password" ] ; then
    print_usage
    exit 1
fi
if [ -z "$base" ] ; then
    print_usage
    exit 1
fi
if [ -z "$label" ] ; then
    print_usage
    exit 1
fi
if [ -z "$query_file" ] ; then
    print_usage
    exit 1
fi
if [ -z "$1" ]; then
    print_usage
    exit 1
fi

# allow explicit URIs
if [ -n "$uri" ] ; then
    query="<${uri}>" # URI
else
    query="_:query" # blank node
fi

query_string=$(<"$query_file") # read query string from file

args+=("-f")
args+=("$cert_pem_file")
args+=("-p")
args+=("$cert_password")
args+=("-t")
args+=("text/turtle") # content type

turtle+="@prefix ldh:	<https://w3id.org/atomgraph/linkeddatahub#> .\n"
turtle+="@prefix sp:	<http://spinrdf.org/sp#> .\n"
turtle+="@prefix rdfs:	<http://www.w3.org/2000/01/rdf-schema#> .\n"
turtle+="${query} a sp:Select .\n"
turtle+="${query} rdfs:label \"${label}\" .\n"
turtle+="${query} sp:text \"\"\"${query_string}\"\"\" .\n"

if [ -n "$comment" ] ; then
    turtle+="${query} rdfs:comment \"${comment}\" .\n"
fi
if [ -n "$service" ] ; then
    turtle+="@prefix ldh:	<https://w3id.org/atomgraph/linkeddatahub#> .\n"
    turtle+="${query} ldh:service <${service}> .\n"
fi

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | post.sh "${args[@]}"