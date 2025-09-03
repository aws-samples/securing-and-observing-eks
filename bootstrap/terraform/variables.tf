variable "name" {
  description = "Name to be used on all resources."
}

variable "version" {
  description = "Amazon EKS Auto Mode Cluster Version"
  type        = string
  default     = "1.33"
}