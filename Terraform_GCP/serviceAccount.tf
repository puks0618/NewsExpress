resource "google_service_account" "bq_service_account" {
  account_id   = "bq-writer"
  display_name = "BigQuery Writer Service Account"
}

resource "google_project_iam_member" "bq_data_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.bq_service_account.email}"
}

resource "google_storage_bucket_iam_member" "bq_temp_writer" {
  bucket = var.temp_bucket_name
  role   = "roles/storage.objectAdmin" # or roles/storage.objectCreator
  member = "serviceAccount:${google_service_account.bq_service_account.email}"
}

resource "google_project_iam_member" "bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.bq_service_account.email}"
}