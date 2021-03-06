#!/bin/zsh
#
# Loosely based on the following tutorial
# https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform
#
# TODO: Make sure gcloud is setup for bash
# TODO: Convert this back to a 'Bash' script

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

echo "# Creating Terraform Admin project"
gcloud projects create ${TF_ADMIN} \
  --set-as-default
echo "\n\xE2\x9C\x94 Done\n"

echo "# Setting default billing account"
gcloud beta billing projects link ${TF_ADMIN} \
  --billing-account ${TF_VAR_billing_account}
echo "\n\xE2\x9C\x94 Done\n"


echo "# Creating Terraform Service Account"
gcloud iam service-accounts create terraform \
  --display-name "Terraform admin account"

gcloud iam service-accounts keys create ${TF_CREDS} \
  --iam-account terraform@${TF_ADMIN}.iam.gserviceaccount.com
echo "\n\xE2\x9C\x94 Done\n"

echo "# Granting the service account permissions"
gcloud projects add-iam-policy-binding ${TF_ADMIN} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/viewer

gcloud projects add-iam-policy-binding ${TF_ADMIN} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/storage.admin

gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable cloudbilling.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable compute.googleapis.com

# TODO: Figure out if these organization level changes are needed
# My GCP account doesn't have an org
# gcloud organizations add-iam-policy-binding \
#  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
#  --role roles/resourcemanager.projectCreator

#gcloud organizations add-iam-policy-binding \
#  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
#  --role roles/billing.user
echo "\n\xE2\x9C\x94 Done\n"

echo "# Setting up Remote Storage for Terraform State"
gsutil mb -p ${TF_ADMIN} gs://${TF_ADMIN}

cat > backend.tf << EOF
terraform {
 backend "gcs" {
   bucket  = "${TF_ADMIN}"
   prefix  = "terraform/state"
   project = "${TF_ADMIN}"
 }
}
EOF

gsutil versioning set on gs://${TF_ADMIN}
echo "\n\xE2\x9C\x94 Done\n"

echo "# Setting up Environment variables for Terraform Provider"
export GOOGLE_APPLICATION_CREDENTIALS=${TF_CREDS}
export GOOGLE_PROJECT=${TF_ADMIN}
echo "\n\xE2\x9C\x94 Done\n"

