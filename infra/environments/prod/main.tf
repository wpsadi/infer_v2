module "appwrite" {
  source = "../../modules/appwrite"

  appwrite_endpoint        = var.APPWRITE_ENDPOINT
  appwrite_project_id      = var.APPWRITE_PROJECT_ID
  appwrite_api_key         = var.APPWRITE_API_KEY
  appwrite_functions_token = var.APPWRITE_FUNCTIONS_TOKEN
}
