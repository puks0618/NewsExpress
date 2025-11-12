resource "google_storage_bucket" "temp_bucket" {
  name          = var.temp_bucket_name # must be globally unique
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 3 # Optional: auto-delete objects older than 3 days
    }
  }
}

resource "google_storage_bucket_iam_member" "temp_bucket_iam" {
  bucket = google_storage_bucket.temp_bucket.name
  role   = "roles/storage.objectAdmin"                                                       # Adjust the role as needed
  member = "serviceAccount:terraform-q2352@api-project-269968866265.iam.gserviceaccount.com" # Replace with your service account's email
}