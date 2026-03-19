<!-- BEGIN_TF_DOCS -->


## Requirements

## Requirements

No requirements.

## Providers

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

## Modules

No modules.

## Resources

## Resources

| Name | Type |
|------|------|
| [google_secret_manager_secret.db_password](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret.onfido_api_key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_iam_member.api_db_password](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_iam_member.api_onfido_key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_version.db_password](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_sql_database.app](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database) | resource |
| [google_sql_database_instance.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance) | resource |
| [google_sql_user.app](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_user) | resource |
| [google_sql_user.app_iam](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_user) | resource |
| [google_storage_bucket.documents](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_member.api_documents](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [random_password.db_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_backend_sa_email"></a> [api\_backend\_sa\_email](#input\_api\_backend\_sa\_email) | API backend service account email for resource-scoped IAM | `string` | n/a | yes |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | VPC network self-link for Cloud SQL private networking | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Prefix for resource names | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region | `string` | n/a | yes |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_db_connection_name"></a> [db\_connection\_name](#output\_db\_connection\_name) | Cloud SQL connection name for Auth Proxy |
| <a name="output_db_name"></a> [db\_name](#output\_db\_name) | Database name |
| <a name="output_db_password_secret_id"></a> [db\_password\_secret\_id](#output\_db\_password\_secret\_id) | Secret Manager secret ID for database password |
| <a name="output_db_private_ip"></a> [db\_private\_ip](#output\_db\_private\_ip) | Cloud SQL private IP address |
| <a name="output_db_user"></a> [db\_user](#output\_db\_user) | Database application user |
| <a name="output_documents_bucket_name"></a> [documents\_bucket\_name](#output\_documents\_bucket\_name) | Customer documents bucket name |
| <a name="output_documents_bucket_url"></a> [documents\_bucket\_url](#output\_documents\_bucket\_url) | Customer documents bucket URL |
| <a name="output_onfido_secret_id"></a> [onfido\_secret\_id](#output\_onfido\_secret\_id) | Secret Manager secret ID for Onfido API key |
<!-- END_TF_DOCS -->