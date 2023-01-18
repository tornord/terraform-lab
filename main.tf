terraform {
  required_version = ">= 1.0.0"

  backend "gcs" {
    bucket = "di-gruppen-terraform-states"
    prefix = "tn-test230116"
  }
}

provider "google" {
  region = local.location
}

locals {
  app_name  = "tn-test230116"
  location = "europe-west1"
}

resource "random_string" "project_suffix" {
  length  = 4
  upper   = false
  special = false
}

resource "google_project" "project" {
  name       = local.app_name
  project_id = "${local.app_name}-${random_string.project_suffix.result}"
  folder_id  = "279533588562"
  billing_account     = "01DCC5-A088C3-4D604D"
  auto_create_network = false
  labels = { "department" : "di-gruppen" }
}

resource "google_project_service" "cloud_run" {
  service = "run.googleapis.com"
  project = google_project.project.project_id
}

resource "google_project_service" "artifact_registry" {
  service = "artifactregistry.googleapis.com"
  project = google_project.project.project_id
}

resource "google_artifact_registry_repository" "repo" {
  provider      = google-beta
  project       = google_project.project.project_id
  location      = local.location
  repository_id = "images"
  format        = "DOCKER"
  depends_on = [
    google_project_service.artifact_registry
  ]
}

resource "google_project_service" "cloudbuild_api" {
  service = "cloudbuild.googleapis.com"
  project = google_project.project.project_id
}

resource "google_storage_bucket" "cloud_build_bucket" {
  name          = "${google_project.project.project_id}_cloudbuild"
  location      = local.location
  project       = google_project.project.project_id
  force_destroy = true
}

resource "google_service_account" "cloud_run" {
  account_id   = "${local.app_name}-cloudrun"
  display_name = "Cloud Run Identity"
  project      = google_project.project.project_id
}

resource "google_cloud_run_service" "application" {
  provider = google-beta
  name     = local.app_name
  location = local.location
  project  = google_project.project.project_id

  template {
    spec {
      containers {
        env {
          name  = "NODE_ENV"
          value = "production"
        }
        image = "europe-west1-docker.pkg.dev/shared-artifacts-f67x/docker-public/cloud-run-dummy:latest"
      }
      service_account_name = google_service_account.cloud_run.email
    }
  }
  metadata {
    annotations = {
      "run.googleapis.com/ingress" = "all"
    }
  }
  autogenerate_revision_name = true

  lifecycle {
    ignore_changes = [
      template[0].spec[0].containers[0].image,
    ]
  }
  depends_on = [
    google_project_service.cloud_run,
  ]
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.application.location
  project  = google_cloud_run_service.application.project
  service  = google_cloud_run_service.application.name
  policy_data = data.google_iam_policy.noauth.policy_data
}