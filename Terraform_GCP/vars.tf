# =============================================================================
# NewsExpress Terraform Variables
# =============================================================================
# UPDATE THESE VALUES BEFORE RUNNING TERRAFORM
# =============================================================================

# -----------------------------------------------------------------------------
# GCP PROJECT CONFIGURATION (MUST UPDATE)
# -----------------------------------------------------------------------------
variable "project_id" {
  type        = string
  default     = "kafka-news-stream-1762484628"
  description = "Your GCP project ID"
}

variable "temp_bucket_name" {
  type        = string
  default     = "newsexpress-temp-358785751865"
  description = "GCS bucket for Spark temporary files"
}

variable "bq_dataset_id" {
  type        = string
  default     = "news_stream"
  description = "BigQuery dataset ID"
}

# -----------------------------------------------------------------------------
# REGION CONFIGURATION
# -----------------------------------------------------------------------------
variable "region" {
  type        = string
  default     = "us-central1"  # Change to your preferred region
  description = "GCP region for resources"
}

variable "zone" {
  type        = string
  default     = "us-central1-a"  # Change to your preferred zone
  description = "GCP zone for instances"
}

# -----------------------------------------------------------------------------
# NETWORK CONFIGURATION
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  type        = string
  default     = "172.20.0.0/16"
  description = "VPC CIDR block"
}

variable "public_subnet_cidr" {
  type        = string
  default     = "172.20.1.0/24"
  description = "Public subnet CIDR (control instance)"
}

variable "private_subnet_cidr" {
  type        = string
  default     = "172.20.2.0/24"
  description = "Private subnet CIDR (Kafka, Producer, Consumer)"
}

# -----------------------------------------------------------------------------
# INSTANCE CONFIGURATION
# -----------------------------------------------------------------------------
variable "instance_type" {
  type        = string
  default     = "e2-small"
  description = "Instance type for Kafka and Producer"
}

variable "instance_type_spark" {
  type        = string
  default     = "e2-standard-2"
  description = "Instance type for Spark Consumer (needs more resources)"
}

variable "instance_image" {
  type = map(string)
  default = {
    centos = "centos-cloud/centos-stream-9"
    ubuntu = "ubuntu-os-cloud/ubuntu-2204-lts"
  }
  description = "OS images for instances"
}

# -----------------------------------------------------------------------------
# KAFKA CONFIGURATION
# -----------------------------------------------------------------------------
variable "kafka_topic" {
  type        = string
  default     = "news-stream"
  description = "Kafka topic name"
}

# -----------------------------------------------------------------------------
# PRIVACY CONFIGURATION
# -----------------------------------------------------------------------------
variable "epsilon" {
  type        = string
  default     = "0.5"
  description = "Differential privacy epsilon"
}
