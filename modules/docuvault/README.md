<!-- BEGIN_TF_DOCS -->


## Requirements

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 5.46 |

## Providers

## Providers

No providers.

## Modules

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_backend"></a> [backend](#module\_backend) | ../backend | n/a |
| <a name="module_frontend"></a> [frontend](#module\_frontend) | ../frontend | n/a |
| <a name="module_iam"></a> [iam](#module\_iam) | ../iam | n/a |
| <a name="module_monitoring"></a> [monitoring](#module\_monitoring) | ../monitoring | n/a |
| <a name="module_network"></a> [network](#module\_network) | ../network | n/a |

## Resources

## Resources

No resources.

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_backend_image"></a> [api\_backend\_image](#input\_api\_backend\_image) | Container image for the API backend — must be a specific version or digest, not :latest | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (development, production) | `string` | `"production"` | no |
| <a name="input_pagerduty_integration_key"></a> [pagerduty\_integration\_key](#input\_pagerduty\_integration\_key) | PagerDuty service integration key for alert routing | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Prefix for resource names | `string` | `"docuvault"` | no |
| <a name="input_region"></a> [region](#input\_region) | GCP region | `string` | `"us-central1"` | no |
| <a name="input_web_ui_image"></a> [web\_ui\_image](#input\_web\_ui\_image) | Container image for the web UI — must be a specific version or digest, not :latest | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | GCP zone | `string` | `"us-central1-a"` | no |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_backend_service_account"></a> [api\_backend\_service\_account](#output\_api\_backend\_service\_account) | n/a |
| <a name="output_api_backend_url"></a> [api\_backend\_url](#output\_api\_backend\_url) | n/a |
| <a name="output_database_connection_name"></a> [database\_connection\_name](#output\_database\_connection\_name) | n/a |
| <a name="output_document_bucket"></a> [document\_bucket](#output\_document\_bucket) | n/a |
| <a name="output_web_ui_service_account"></a> [web\_ui\_service\_account](#output\_web\_ui\_service\_account) | n/a |
| <a name="output_web_ui_url"></a> [web\_ui\_url](#output\_web\_ui\_url) | n/a |
<!-- END_TF_DOCS -->