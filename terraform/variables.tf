variable "mongodb_uri" {
  description = "MongoDB Atlas connection string"
  type        = string
  sensitive   = true
}

variable "secret_token" {
  description = "Secret token for the app"
  type        = string
  sensitive   = true
}