output "function_url" {
  description = "Public URL of the inference function"
  value       = module.appwrite.function_url
}

output "function_domain_status" {
  value = module.appwrite.function_domain_status
}
