resource "appwrite_function" "inference" {
  id                    = "inference-function"
  name                  = "inference"
  runtime               = "bun-1.4"
  entrypoint            = "src/main.ts"
  commands              = "bun install"
  build_specification   = "s-2vcpu-2gb"
  runtime_specification = "s-0.5vcpu-512mb"
  scopes                = ["users.read"]
  execute               = ["any"]
  events                = []
  timeout               = 180
  enabled               = true
  logging               = true
  deployment_retention = 7
}


resource "appwrite_function_variable" "functions_token" {
  function_id = appwrite_function.inference.id
  key         = "APPWRITE_FUNCTIONS_TOKEN"
  value       = var.appwrite_functions_token
  secret      = true
}

# The provider has no WAF resource, so the rules are applied through the REST API.
# One deny rule on the function blocks any request without the exact token.
resource "terraform_data" "inference_waf" {
  triggers_replace = {
    token_hash  = sha256(var.appwrite_functions_token)
    function_id = appwrite_function.inference.id
    script_hash = filesha256("${path.module}/scripts/waf-rules.sh")
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/waf-rules.sh"
    environment = {
      APPWRITE_ENDPOINT        = var.appwrite_endpoint
      APPWRITE_PROJECT_ID      = var.appwrite_project_id
      APPWRITE_API_KEY         = var.appwrite_api_key
      APPWRITE_FUNCTIONS_TOKEN = var.appwrite_functions_token
      FUNCTION_ID              = appwrite_function.inference.id
    }
  }
}

locals {
  # fra.cloud.appwrite.io -> fra
  appwrite_region = split(".", replace(var.appwrite_endpoint, "https://", ""))[0]
  function_domain = coalesce(
    var.function_domain,
    "${appwrite_function.inference.id}-${var.appwrite_project_id}.${local.appwrite_region}.appwrite.run"
  )
}

# Public domain that serves the function's active deployment
resource "appwrite_proxy_rule" "inference" {
  type        = "function"
  resource_id = appwrite_function.inference.id
  domain      = local.function_domain
}
