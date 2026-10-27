terraform {
  cloud {
    # Organization and workspace come from the TF_CLOUD_ORGANIZATION and
    # TF_WORKSPACE environment variables (a cloud block can't read tfvars/variables)
    workspaces {
      project = "infer"
    }
  }
}
