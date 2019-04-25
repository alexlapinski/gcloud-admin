terraform {
 backend "gcs" {
   bucket  = "alexlapinski-terraform-admin"
   prefix  = "terraform/state"
   project = "alexlapinski-terraform-admin"
 }
}
