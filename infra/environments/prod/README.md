# Prod infrastructure

Terraform config for the Appwrite project (function, function variable, WAF rules). State lives in HCP Terraform.

## HCP Terraform backend

[backend.tf](backend.tf) uses a `cloud` block with only `project = "infer"`. A `cloud` block can't read variables or tfvars, so the organization and workspace come from environment variables:

| Env var | Value |
|---|---|
| `TF_CLOUD_ORGANIZATION` | `ord-name` |
| `TF_WORKSPACE` | `workspace-name` |
| `TF_TOKEN_app_terraform_io` | HCP Terraform API token (or run `terraform login`) |

Pass them inline for one command:

```bash
TF_CLOUD_ORGANIZATION=ord-name TF_WORKSPACE=workspace-name terraform init
TF_CLOUD_ORGANIZATION=ord-name TF_WORKSPACE=workspace-name terraform plan
TF_CLOUD_ORGANIZATION=ord-name TF_WORKSPACE=workspace-name terraform apply
```

or export them once per shell:

```bash
export TF_CLOUD_ORGANIZATION=ord-name
export TF_WORKSPACE=workspace-name
terraform init
```

## Variables

Declared in [variables.tf](variables.tf). Copy [secrets.auto.tfvars.example](secrets.auto.tfvars.example) to `secrets.auto.tfvars` and fill it in:

| Variable | Notes |
|---|---|
| `APPWRITE_ENDPOINT` | e.g. `https://fra.cloud.appwrite.io/v1` |
| `APPWRITE_PROJECT_ID` | Appwrite project ID |
| `APPWRITE_API_KEY` | sensitive; needs `wafRules.read` and `wafRules.write` |
| `APPWRITE_FUNCTIONS_TOKEN` | sensitive; callers send it in the `x-functions-token` header |

`*.tfvars` is gitignored, so the real file is never committed (the `.example` file is). In CI the file is written from GitHub secrets/vars by the "Create tfvars" step of [infra-check.prod.yaml](../../../.github/workflows/infra-check.prod.yaml).

Variables can also be passed as `TF_VAR_<name>` env vars, e.g. `TF_VAR_APPWRITE_API_KEY=...`.

## What gets managed

All resources are in [../../modules/appwrite](../../modules/appwrite/resources.tf):

- `appwrite_function.inference`: function ID `inference-function`, executable by `any`.
- `appwrite_function_variable.functions_token`: sets the secret `APPWRITE_FUNCTIONS_TOKEN` on the function.
- `terraform_data.inference_waf`: runs [waf-rules.sh](../../modules/appwrite/scripts/waf-rules.sh) to create one WAF deny rule on the function. Requests are denied unless `x-functions-token` equals the token.

## Nuances

- **No WAF resource in the provider.** The rules are applied through the Appwrite REST API by a script. They re-apply only when the token, the function ID or the script changes. Edits or deletions made in the Appwrite console are not detected by `plan`.
- **Existing function.** If `inference-function` already exists in Appwrite, import it before the first apply:
  ```bash
  TF_CLOUD_ORGANIZATION=ord-name TF_WORKSPACE=workspace-name \
    terraform import module.appwrite.appwrite_function.inference inference-function
  ```
- **Drift check.** The infra-check workflow runs every 6 hours with `terraform plan -detailed-exitcode`. Exit 0 = in sync, 2 = mismatch (workflow fails), 1 = error. It fails until the config has been applied once.
- **Token in state.** The WAF resource stores only a SHA-256 hash of the token in its triggers. The token itself is still in the workspace state through the sensitive function variable.
- **Lowercase header.** WAF header conditions must use lowercase names, hence `x-functions-token`.
- **Setup script.** `source scripts/setup.sh` checks the three HCP vars above and exports them into your current shell (running it with `./` only validates, since a child process can't export to its parent). In GitHub Actions it also appends them to `$GITHUB_ENV` for later steps.
- **Leftover files.** `hcp.auto.tfvars` and `terraform.tfvars` are no longer used by anything and can be deleted.

## Common commands

```bash
export TF_CLOUD_ORGANIZATION=wpsadi TF_WORKSPACE=prod

terraform init
terraform fmt -recursive ../..
terraform validate
terraform plan -detailed-exitcode   # 0 in sync, 2 changes pending
terraform apply
terraform state list
```

`terraform init -backend=false` is enough for `fmt` and `validate` without HCP access.
