# Configure the region and project
provider "google" {
  project     = var.project_id # Replace with your project ID
  region      = var.region     # Replace with your desired region
  credentials = file("terraform-key.json")
  zone        = var.zone
}


