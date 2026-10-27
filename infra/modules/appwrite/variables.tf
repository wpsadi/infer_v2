variable "appwrite_endpoint" {
  description = "Appwrite API endpoint"
  type        = string
}

variable "appwrite_project_id" {
  description = "Appwrite project ID"
  type        = string
}

variable "appwrite_api_key" {
  description = "Appwrite API key (needs wafRules.read and wafRules.write)"
  type        = string
  sensitive   = true
}

variable "appwrite_functions_token" {
  description = "Shared token callers must send in the x-functions-token header"
  type        = string
  sensitive   = true
}
