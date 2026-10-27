output "function_domain" {
  description = "Domain serving the inference function"
  value       = appwrite_proxy_rule.inference.domain
}

output "function_url" {
  value = "https://${appwrite_proxy_rule.inference.domain}"
}

output "function_domain_status" {
  description = "Domain verification status"
  value       = appwrite_proxy_rule.inference.status
}
