#!/usr/bin/env bash

print_usage()
{
    printf "Creates an ACL authorization.\n"
    printf "\n"
    printf "Usage:  %s options\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the admin application\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
    printf "\n"
    printf "  --label LABEL                        Label of the authorization\n"
    printf "  --comment COMMENT                    Description of the authorization (optional)\n"
    printf "  --slug STRING                        String that will be used as URI path segment (optional)\n"
    printf "\n"
    printf "  --uri URI                            URI of the authorization (optional)\n"
    printf "  --agent AGENT_URI                    URI of the agent (optional)\n"
    printf "  --agent-class AGENT_CLASS_URI        URI of the agent class (optional)\n"
    printf "  --agent-group AGENT_GROUP_URI        URI of the agent group (optional)\n"
    printf "  --to RESOURCE_URI                    URI of the controlled resource (optional)\n"
    printf "  --to-all-in RESOURCE_TYPE_URI        URI of the controlled resource type (optional)\n"
    printf "  --append APPEND_MODE                 Append mode (optional)\n"
    printf "  --control CONTROL_MODE               Control mode (optional)\n"
    printf "  --read READ_MODE                     Read mode (optional)\n"
    printf "  --write WRITE_MODE                   Write mode (optional)\n"
}

hash turtle 2>/dev/null || { echo >&2 "turtle not on \$PATH.  Aborting."; exit 1; }

urlencode() {
  python -c 'import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], sys.argv[2]))' \
    "$1" "$urlencode_safe"
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
        --slug)
        slug="$2"
        shift # past argument
        shift # past value
        ;;
        --uri)
        uri="$2"
        shift # past argument
        shift # past value
        ;;
        --agent)
        agents+=("$2")
        shift # past argument
        shift # past value
        ;;
        --agent-class)
        agent_classes+=("$2")
        shift # past argument
        shift # past value
        ;;
        --agent-group)
        agent_groups+=("$2")
        shift # past argument
        shift # past value
        ;;
        --to)
        tos+=("$2")
        shift # past argument
        shift # past value
        ;;
        --to-all-in)
        to_all_ins+=("$2")
        shift # past argument
        shift # past value
        ;;
        --append)
        append=true
        shift # past value
        ;;
        --control)
        control=true
        shift # past value
        ;;
        --read)
        read=true
        shift # past value
        ;;
        --write)
        write=true
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
if [ ${#agents[@]} -eq 0 ] && [ ${#agent_classes[@]} -eq 0 ] && [ ${#agent_groups[@]} -eq 0 ] ; then

    #echo '--agent or --agent-class or --agent-group not set'
    print_usage
    exit 1
fi
if [ ${#tos[@]} -eq 0 ] && [ ${#to_all_ins[@]} -eq 0 ] ; then
    #echo '--to or --to-all-in not set'
    print_usage
    exit 1
fi
if [ -z "$append" ] && [ -z "$control" ] && [ -z "$read" ] && [ -z "$write" ] ; then
    #echo '--append or --control or --read or --write not set'
    print_usage
    exit 1
fi

if [ -z "$slug" ] ; then
    slug=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
fi
encoded_slug=$(urlencode "$slug")

container="${base}acl/authorizations/"

# allow explicit URIs
if [ -n "$uri" ] ; then
    auth="<${uri}>" # URI
else
    auth="_:auth" # blank node
fi

args+=("-f")
args+=("$cert_pem_file")
args+=("-p")
args+=("$cert_password")
args+=("-t")
args+=("text/turtle") # content type
args+=("${container}${encoded_slug}/")

turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy#> .\n"
turtle+="@prefix rdfs:	<http://www.w3.org/2000/01/rdf-schema#> .\n"
turtle+="@prefix acl:	<http://www.w3.org/ns/auth/acl#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="${auth} a acl:Authorization .\n"
turtle+="${auth} rdfs:label \"${label}\" .\n"
turtle+="<${container}${encoded_slug}/> a dh:Item .\n"
turtle+="<${container}${encoded_slug}/> foaf:primaryTopic ${auth} .\n"
turtle+="<${container}${encoded_slug}/> dct:title \"${label}\" .\n"

if [ -n "$comment" ] ; then
    turtle+="${auth} rdfs:comment \"${comment}\" .\n"
fi

for agent in "${agents[@]}"
do
    turtle+="${auth} acl:agent <${agent}> .\n"
done
for agent_class in "${agent_classes[@]}"
do
    turtle+="${auth} acl:agentClass <${agent_class}> .\n"
done
for agent_group in "${agent_groups[@]}"
do
    turtle+="${auth} acl:agentGroup <${agent_group}> .\n"
done
for to in "${tos[@]}"
do
    turtle+="${auth} acl:accessTo <${to}> .\n"
done
for to_all_in in "${to_all_ins[@]}"
do
    turtle+="${auth} acl:accessToClass <${to_all_in}> .\n"
done

if [ -n "$append" ] ; then
    turtle+="${auth} acl:mode acl:Append .\n"
fi
if [ -n "$control" ] ; then
    turtle+="${auth} acl:mode acl:Control .\n"
fi
if [ -n "$read" ] ; then
    turtle+="${auth} acl:mode acl:Read .\n"
fi
if [ -n "$write" ] ; then
    turtle+="${auth} acl:mode acl:Write .\n"
fi

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | put.sh "${args[@]}"