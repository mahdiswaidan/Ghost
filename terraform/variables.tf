variable "create_cluster" {
  description = "Controls whether to create the GKE Autopilot cluster."
  type        = bool
  default     = true
}

variable "delete_cluster" {
  description = "Controls whether to delete the existing GKE Autopilot cluster."
  type        = bool
  default     = true
}

