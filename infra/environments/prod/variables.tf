variable "APPWRITE_ENDPOINT" {
  description = "Appwrite API endpoint"
  type        = string
}

variable "APPWRITE_API_KEY" {
  description = "Appwrite API key"
  type        = string
  sensitive   = true
}

variable "APPWRITE_PROJECT_ID" {
  description = "Appwrite project ID"
  type        = string
}


variable "APPWRITE_FUNCTIONS_TOKEN" {
  description = "Shared token required in the x-functions-token header to call the inference function"
  type        = string
  sensitive   = true
}
