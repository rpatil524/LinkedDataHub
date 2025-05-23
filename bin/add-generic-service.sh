#!/usr/bin/env bash

print_usage()
{
    printf "Appends a generic service using endpoint URI.\n"
    printf "\n"
    printf "Usage:  %s options\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the application\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
    printf "\n"
    printf "  --title TITLE                        Title of the service\n"
    printf "  --description DESCRIPTION            Description of the service (optional)\n"
    printf "  --slug SLUG                          String that will be used as URI path segment (optional)\n"
    printf "\n"
    printf "  --endpoint ENDPOINT_URI              Endpoint URI\n"
    printf "  --graph-store GRAPH_STORE_URI        Graph Store URI (optional)\n"
    printf "  --auth-user AUTH_USER                Authorization username (optional)\n"
    printf "  --auth-pwd AUTH_PASSWORD             Authorization password (optional)\n"
}

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
        --title)
        title="$2"
        shift # past argument
        shift # past value
        ;;
        --description)
        description="$2"
        shift # past argument
        shift # past value
        ;;
        --fragment)
        fragment="$2"
        shift # past argument
        shift # past value
        ;;
        --endpoint)
        endpoint="$2"
        shift # past argument
        shift # past value
        ;;
        --graph-store)
        graph_store="$2"
        shift # past argument
        shift # past value
        ;;
        --auth-user)
        auth_user=true
        shift # past value
        ;;
        --auth-pwd)
        auth_pwd="$2"
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
if [ -z "$title" ] ; then
    print_usage
    exit 1
fi
if [ -z "$endpoint" ] ; then
    print_usage
    exit 1
fi

args+=("-f")
args+=("$cert_pem_file")
args+=("-p")
args+=("$cert_password")
args+=("-t")
args+=("text/turtle") # content type

if [ -n "$fragment" ] ; then
    # relative URI that will be resolved against the request URI
    subject="<#${fragment}>"
else
    subject="_:subject"
fi

turtle+="@prefix ldh:	<https://w3id.org/atomgraph/linkeddatahub#> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy#> .\n"
turtle+="@prefix a:	<https://w3id.org/atomgraph/core#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix sd:	<http://www.w3.org/ns/sparql-service-description#> .\n"
turtle+="${subject} a sd:Service .\n"
turtle+="${subject} dct:title \"${title}\" .\n"
turtle+="${subject} sd:endpoint <${endpoint}> .\n"
turtle+="${subject} sd:supportedLanguage sd:SPARQL11Query .\n"
turtle+="${subject} sd:supportedLanguage sd:SPARQL11Update .\n"

if [ -n "$graph_store" ] ; then
    turtle+="${subject} a:graphStore <${graph_store}> .\n"
fi
if [ -n "$auth_user" ] ; then
    turtle+="${subject} a:authUser \"${auth_user}\" .\n"
fi
if [ -n "$auth_pwd" ] ; then
    turtle+="${subject} a:authPwd \"${auth_pwd}\" .\n"
fi
if [ -n "$description" ] ; then
    turtle+="_:query dct:description \"${description}\" .\n"
fi

# submit Turtle doc to the server
echo -e "$turtle" | post.sh "${args[@]}"
