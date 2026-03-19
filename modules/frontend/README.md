<!-- BEGIN_TF_DOCS -->


## Requirements

## Requirements

No requirements.

## Providers

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

## Modules

No modules.

## Resources

## Resources

| Name | Type |
|------|------|
| [google_cloud_run_service.api_backend](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service) | resource |
| [google_cloud_run_service.web_ui](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service) | resource |
| [google_cloud_run_service_iam_member.web_invoke_api](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service_iam_member) | resource |
| [google_cloud_run_service_iam_member.web_ui_public](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service_iam_member) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_backend_image"></a> [api\_backend\_image](#input\_api\_backend\_image) | Container image for the API backend (pin to a specific version or digest, never use :latest) | `string` | n/a | yes |
| <a name="input_api_backend_sa_email"></a> [api\_backend\_sa\_email](#input\_api\_backend\_sa\_email) | API backend service account email | `string` | n/a | yes |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Database name | `string` | n/a | yes |
| <a name="input_db_password_secret_id"></a> [db\_password\_secret\_id](#input\_db\_password\_secret\_id) | Secret Manager secret ID for database password | `string` | n/a | yes |
| <a name="input_db_private_ip"></a> [db\_private\_ip](#input\_db\_private\_ip) | Cloud SQL private IP address | `string` | n/a | yes |
| <a name="input_db_user"></a> [db\_user](#input\_db\_user) | Database application user | `string` | n/a | yes |
| <a name="input_documents_bucket_name"></a> [documents\_bucket\_name](#input\_documents\_bucket\_name) | Customer documents bucket name | `string` | n/a | yes |
| <a name="input_onfido_secret_id"></a> [onfido\_secret\_id](#input\_onfido\_secret\_id) | Secret Manager secret ID for Onfido API key | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Prefix for resource names | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region | `string` | n/a | yes |
| <a name="input_vpc_connector_name"></a> [vpc\_connector\_name](#input\_vpc\_connector\_name) | VPC Access Connector name for private network access | `string` | n/a | yes |
| <a name="input_web_ui_image"></a> [web\_ui\_image](#input\_web\_ui\_image) | Container image for the web UI (pin to a specific version or digest, never use :latest) | `string` | n/a | yes |
| <a name="input_web_ui_sa_email"></a> [web\_ui\_sa\_email](#input\_web\_ui\_sa\_email) | Web UI service account email | `string` | n/a | yes |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_backend_name"></a> [api\_backend\_name](#output\_api\_backend\_name) | API backend service name |
| <a name="output_api_backend_url"></a> [api\_backend\_url](#output\_api\_backend\_url) | API backend service URL |
| <a name="output_web_ui_url"></a> [web\_ui\_url](#output\_web\_ui\_url) | Web UI service URL |
<!-- END_TF_DOCS -->