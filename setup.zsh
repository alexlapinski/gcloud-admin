#!/bin/zsh

# TODO: Make sure gcloud is setup for bash

echo "# Setting up environment variables\n"
TF_VAR_billing_account=$(
	gcloud beta billing accounts list \
	--filter open=true \
	--limit 1 \
	--format json | \
	sed -n 's/.*"name": "billingAccounts\/\(.*\)",/\1/p')
TF_ADMIN=${USER}-terraform-admin
TF_CREDS=~/.gcp/${USER}-terraform-admin.json

echo "TF_VAR_billing_account = $TF_VAR_billing_account"
echo "TF_ADMIN = $TF_ADMIN"
echo "TF_CREDS = $TF_CREDS"

echo "\n\xE2\x9C\x94 Done\n"

# gcloud 