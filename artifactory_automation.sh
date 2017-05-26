#!/bin/bash
# VMware DevOps and Cloud Native Applications Customer onboarding script
# Artifactory Portion
# Written by Justin Jones (justinj@vmware.com)
# Last Updated: 2017-01-01
# Version: 0.6

function fail() {
	echo >&2 "$@"
	exit 1
}

function usage() {
	echo >&2 "error: $@"
	fail "$0 repoName customerName emailAddress

	The command line arguments must be provided with no switches in that order and must be valid for the script to complete correctly
	repoName == artifactory repository name (eg, Nike)
	customerName == customer username (eg, justin)
	emailAddress == email address of the customer account being created. (eg, justinj@vmware.com)"
}

# validate command line arguments
[  -n "$1" ] || usage "must set repository name"
[  -n "$2" ] || usage "must set customer name"
[  -n "$3" ] || usage "must set customer email"
REPOSITORY_NAME="$1"
CUSTOMER_USERNAME="$2"
CUSTOMER_EMAIL="$3"

# define defaults, but allow changing with env vars
URL=${ARTIFACTORY_URL:-'https://vmwaredocna.jfrog.io/vmwaredocna'}
USERNAME=${ARTIFACTORY_USERNAME:-'automation'}
# mandatory env var for API authentication
PASSWORD=${ARTIFACTORY_PASSWORD:?'env variable must be set'}

CUSTOMER_PASSWORD=${ARTIFACTORY_DEFAULT_PASS:-'VMware1!'}

# first task, create the repository
CREATE_REPO_URL="$URL/api/repositories/$REPOSITORY_NAME"

# bail if repo already exists
# Check if Repo exists using a GET of all repos and Grepping it for the repository name
if curl -s -u $USERNAME:$PASSWORD -X GET $CREATE_REPO_URL | grep -q -i "key.*$REPOSITORY_NAME" ; then
	echo "'$REPOSITORY_NAME' exists, bailing out"
	exit 0
fi

# Otherwise create it and carry on
curl -u $USERNAME:$PASSWORD -X PUT $CREATE_REPO_URL -H "Content-Type: application/json" -d '{"rclass":"local","packageType": "generic"}'
echo "Created a Repo called '$REPOSITORY_NAME'"
sleep 5
# second task, create the username
CREATE_USER_URL="$URL/api/security/users/$CUSTOMER_USERNAME"
curl -u $USERNAME:$PASSWORD -X PUT $CREATE_USER_URL -H "Content-Type: application/json" -d '{"email":"'"$CUSTOMER_EMAIL"'","password":"'"$CUSTOMER_PASSWORD"'"}'
echo "Created a user named '$USERNAME'"
sleep 5

# third task, create a read only permission allowing user access to repository
CREATE_PERMISSION_URL="$URL/api/security/permissions/${REPOSITORY_NAME}_permission"
curl -u $USERNAME:$PASSWORD -X PUT $CREATE_PERMISSION_URL -H "Content-Type: application/json" -d '{"name":"'"$REPOSITORY_NAME"'_permission","repositories": ["'"$REPOSITORY_NAME"'"], "principals": {"users" :{"'"$CUSTOMER_USERNAME"'": ["r"]},"groups":{"customer_accounts":["r"]}}}'
echo "Created a permission granting READ ONLY access to REPO='$REPOSITORY_NAME' for user='$USERNAME'"
sleep 5
echo ""
echo ""
echo "Artifactory Automated customer onboarding complete!!!"
echo ""
echo ""
