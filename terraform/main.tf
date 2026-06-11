terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "gcp-de-learning-498109"
  region  = "us-central1"
}

resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifact_registry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "dbt_repo" {
  location      = "us-central1"
  repository_id = "dbt-runner"
  format        = "DOCKER"
  depends_on    = [google_project_service.artifact_registry]
}

resource "google_artifact_registry_repository_iam_member" "dbt_reader" {
  location   = google_artifact_registry_repository.dbt_repo.location
  repository = google_artifact_registry_repository.dbt_repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:dbt-runner@gcp-de-learning-498109.iam.gserviceaccount.com"
}

resource "google_cloud_run_v2_job" "dbt_run" {
  name     = "dbt-run-kenya-econ"
  location = "us-central1"

  template {
    template {
      service_account = "dbt-runner@gcp-de-learning-498109.iam.gserviceaccount.com"
      containers {
        image = "us-central1-docker.pkg.dev/gcp-de-learning-498109/dbt-runner/dbt-kenya-econ:latest"
      }
    }
  }

  depends_on = [google_project_service.run]
}

resource "google_cloud_scheduler_job" "dbt_scheduler" {
  name      = "dbt-daily-run"
  schedule  = "0 7 * * *"
  time_zone = "UTC"

  http_target {
    http_method = "POST"
    uri         = "https://us-central1-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/gcp-de-learning-498109/jobs/dbt-run-kenya-econ:run"

    oauth_token {
      service_account_email = "dbt-runner@gcp-de-learning-498109.iam.gserviceaccount.com"
    }
  }
}
