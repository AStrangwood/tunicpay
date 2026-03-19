# DocuVault Infrastructure — Hardening Review

## Executive Summary

The DocuVault Terraform codebase had critical security issues: plaintext secrets in version control, a network open to the internet on all ports, a publicly accessible database with no SSL or backups, over-permissioned IAM with `roles/editor`, and publicly readable customer document storage. There was no CI/CD, no state locking, and no monitoring that could actually reach anyone. I prioritised by blast radius — secrets and network first, then IAM and storage, then operability and developer experience.

---

## What I Found

### Critical Issues

**Plaintext secrets throughout the codebase** — `terraform.tfvars` had the database password and Onfido API key committed in plain text (`DocuV@ult_Pr0d_2024!`, `live_onfido_k3y_xR7mK9pL2nQ5wT8vB4jH`). The `variables.tf` default for `db_password` was `super_secret_passw0rd!`. Cloud Run services in `services.tf` received both secrets asplaintext environment variables via `value = var.db_password` — even though Secret Manager resources were already defined in `secrets.tf`, they weren't actually being used. The `database_password` was also exposed as an unmasked Terraform output. **These secrets are still recoverable from git history** — removing them from the current files does not make them safe. Both the database password and the Onfido API key must be rotated immediately.

**Network wide open** — A firewall rule (`allow_all`) permitted all protocols from `0.0.0.0/0` with a TODO comment saying "tighten this before production." The VPC used `auto_create_subnetworks` which creates subnets in every region that you don't control. The Cloud SQL database had `authorized_networks = 0.0.0.0/0` (publicly accessible) with `require_ssl = false`. Both Cloud Run services had ingress set to `"all"` and the API backend was publicly invokable by `allUsers` — even though it should only be called by the web UI.

**IAM over-permissioned** — A single service account was shared by both Cloud Run services with `roles/editor` (near-full project access), `roles/secretmanager.admin` (can manage all secrets, not just read them), and `roles/cloudsql.admin` (can delete database instances). All three were project-wide bindings. The customer documents bucket also had `allUsers` as `objectViewer` — public read access to customer documents.

### High Priority Issues

**Container images pinned to `:latest`** — Both Cloud Run services used `gcr.io/.../api-backend:latest` and `web-ui:latest`. The `:latest` tag is mutable — it can change without a Terraform change, making deployments unauditable. For fintech, you need to know exactly what code is running at all times.

**No database HA** — Single-zone Cloud SQL instance (`db-f1-micro`, shared-core, no SLA) with no `availability_type = "REGIONAL"`. A zone outage means complete downtime for a fintech platform handling customer identity verification.

**Database backups disabled** — `backup_configuration.enabled = false` and `point_in_time_recovery_enabled = false`. A data loss event would be unrecoverable.

**Database deletion protection disabled** — `deletion_protection = false` means an accidental `terraform destroy` or a bad PR could drop the production database.

**No IAM-based database authentication** — All database access was via a shared password. No way to audit who accessed the database or scope access per identity. No support for time-bounded break-glass access for developers.

**Storage bucket unprotected** — Customer documents bucket had `force_destroy = true` (can be deleted with all contents), no versioning (overwritten/deleted documents are gone forever), `uniform_bucket_level_access = false` (ACLs in play, harder to audit), and wildcard CORS origin (`*`).

**Monitoring gaps** — Only one alert (CPU > 50% with 0s duration — would fire constantly). No notification channel configured (PagerDuty TODO comment). No memory, error rate, database connection, or storage alerts. Audit log bucket had `force_destroy = true`, no versioning, no retention policy, and no log filter — it was capturing all logs rather than audit-specific ones. An audit log bucket that can be deleted defeats its purpose.

### Medium Priority Issues

**No CI/CD pipeline** — Terraform was run manually from developer laptops with `terraform apply`. No automated checks for security, formatting, linting, or compliance. No plan visibility in PRs.

**No pre-commit hooks** — Nothing prevented bad code from being committed locally.

**No remote state or locking** — Local state file, no locking. Two people running `terraform apply` simultaneously could corrupt state.

**Flat codebase structure** — All resources in a single directory, environments split only by tfvars. No modules, no separation of concerns. Every change touched the same pool of resources.

**No consistent resource labelling** — Labels were applied inconsistently across resources (`managed-by` on some, `team` on some, nothing on others). No default labels at the provider level. Makes cost attribution, audit filtering, and automated policy enforcement harder.

### Low Priority Issues

**Generated secrets in Terraform state** — `random_password` stores the generated value in state in plaintext. This is a known Terraform limitation with no clean workaround. The risk is mitigated by the GCS backend being encrypted at rest and access-controlled via IAM, but anyone with state access can read the password. Worth noting for compliance conversations — it's a reason to lock down state bucket permissions tightly and to prefer IAM-based database authentication over passwords where possible.

---

## What I Fixed and Why

### Security & Compliance

**Secrets** — Removed all hardcoded secrets from `terraform.tfvars`, variable defaults, and outputs. No secret value appears in code, tfvars, or Terraform output.

The database password is generated at runtime via `random_password` and stored in Secret Manager via `google_secret_manager_secret_version`. Because `random_password` already puts the value in Terraform state, writing it to Secret Manager from within Terraform doesn't increase the blast radius — the state is the exposure boundary either way, and it's mitigated by the encrypted GCS backend with scoped IAM.

The Onfido API key uses a different pattern: Terraform creates the Secret Manager secret container and the IAM bindings (`secretmanager.secretAccessor` scoped to the API backend SA), but the secret **value** is populated out-of-band via CI or `gcloud secrets versions add`. This means the plaintext key never flows through Terraform variables, never passes through module wiring, and never lands in state. The original approach passed the key through `TF_VAR_onfido_api_key` → 3 module layers → `secret_data`, which stored it in state at every boundary. The GCP best practice is: Terraform owns the infrastructure (the secret exists, IAM is configured, Cloud Run references it), but externally-sourced secret values are managed outside of Terraform's lifecycle.

Cloud Run services reference both secrets via `value_from` / `secret_key_ref` — the container runtime pulls the value directly from Secret Manager at startup, never via Terraform.

**Note on PagerDuty integration key:** The PagerDuty `service_key` is a direct attribute of `google_monitoring_notification_channel` — there's no Secret Manager reference or out-of-band option for this resource type. It must flow through Terraform and will sit in state in plaintext. The variable is marked `sensitive = true` so it's redacted from plan output, but state access = key access. This is an unavoidable limitation of the Google provider for this resource. Mitigation is tight IAM on the state bucket.

**Networking** — Removed the `allow_all` firewall rule entirely. Replaced `auto_create_subnetworks` with an explicit subnet with `private_ip_google_access` enabled. Added an explicit deny-all ingress rule and an allow-internal rule scoped to the VPC CIDR. Cloud SQL now uses private networking only (`ipv4_enabled = false`) and requires SSL. The API backend ingress is set to `internal` with invocation restricted to the application service account. The web UI uses `internal-and-cloud-load-balancing` so it's only reachable via a load balancer, not directly. Added a VPC Access Connector so Cloud Run services can reach private Cloud SQL — without it, the private database was unreachable.

**Database hardening** — Enabled backups with point-in-time recovery (`start_time = "03:00"`). Enabled `deletion_protection`. Upgraded to `db-custom-2-4096` with `availability_type = "REGIONAL"` for automatic failover across zones — `db-f1-micro` is shared-core with no SLA, unsuitable for production fintech. **Cost tradeoff:** Regional HA roughly doubles the Cloud SQL cost because GCP provisions a standby instance in a second zone with its own compute and storage. the cost of downtime (lost revenue, SLA penalties, reputational damage) far exceeds the infrastructure delta. For development environments, `availability_type = "ZONAL"` is appropriate to keep costs down since there's no uptime SLA to meet.

**IAM database authentication and audit trail** — Enabled Cloud SQL IAM authentication (`cloudsql.iam_authentication` flag) and added an IAM-based database user for the API backend service account. This is one of the most important changes for compliance. With IAM auth, every database connection is tied to a specific Google identity — Cloud SQL audit logs show exactly **who** accessed the database, **when**, and **from where**. This gives you a complete, tamper-proof audit trail that satisfies SOC2 CC6.1/CC6.2 (logical access controls and audit logging), PCI-DSS Requirement 10 (track and monitor access), and bank security questionnaires that ask "can you demonstrate who accessed customer data and when?". Without IAM auth, the original setup used a single shared password — in an audit, you'd have no way to distinguish between legitimate application access and a compromised credential. The shared password user (`docuvault-app`) is kept as a fallback for cases where the application's database driver doesn't support IAM auth, but IAM auth should be the primary access path. This same audit trail is what makes the break-glass developer access pattern work — time-bounded IAM bindings with individual identity, fully logged, auto-expiring.

**Container images** — Replaced hardcoded `:latest` image tags with variables (`var.api_backend_image`, `var.web_ui_image`) that must be set per environment. Images should be pinned to a specific version tag or digest for auditability and reproducibility. CI should update these as part of the deployment pipeline.

**IAM least-privilege** — Split the single shared service account into two: `api-sa` (API backend) and `web-sa` (web UI). Replaced project-wide primitive/admin roles with resource-scoped least-privilege bindings. API backend gets `cloudsql.client` (project), `secretmanager.secretAccessor` (per-secret), and `storage.objectUser` (per-bucket). Web UI only gets `run.invoker` on the API backend — it has no access to the database, secrets, or storage. Removed `allUsers` public read from the customer documents bucket.

**Storage hardening** — Set `force_destroy = false` so the bucket can't be deleted with contents. Enabled `uniform_bucket_level_access` for IAM-only access control. Enabled versioning with lifecycle rules — keeps 3 versions, deletes non-current objects after 30 days. Added a 7-day soft delete policy for recovery of accidentally deleted objects. Restricted CORS origin from `*` to the application domain. Added `environment` label for auditability. **Cost tradeoff:** Versioning increases storage costs because every overwrite or delete creates a non-current version that continues to consume space. For a document-heavy bucket this can add up — in the worst case, 3 retained versions triples the storage footprint. The lifecycle rules cap this: non-current versions are deleted after 30 days and only 3 versions are kept per object, so costs stabilise rather than growing unboundedly. For a fintech platform storing customer identity documents, the alternative — an accidental overwrite or deletion being permanent and unrecoverable — is a compliance and legal risk that outweighs the storage cost. The 30-day lifecycle window is a deliberate balance between recoverability and cost control; it can be shortened if storage costs become a concern.

**Monitoring & alerting** — Set up PagerDuty notification channel so alerts actually page someone. Replaced the single noisy CPU alert (50%, 0s duration) with tuned alerts: CPU > 80% for 5 mins, memory > 85% for 5 mins, 5xx error rate, Cloud SQL connection failures, storage permission denied spikes, and unusual document deletion rates — all with 30-minute auto-close. Every alert includes a `documentation` block with environment, threshold, console links, and step-by-step runbook so on-call engineers have context at 2am. Alerts are labelled with `environment`, `team`, and `severity` for PagerDuty routing (critical pages, warning goes to Slack). Hardened the audit log bucket: `force_destroy = false`, versioning enabled, locked 365-day retention policy (immutable — can't be shortened or removed), lifecycle rule to move to Coldline after a year. Added a log filter to the sink so it only captures admin activity and data access audit logs, not all project logs.

**Default labels** — Added `default_labels` in the provider block (`project`, `environment`, `managed-by`, `team`) so every resource gets consistent labels automatically. Individual resources only set labels that add specific context (e.g. `data-classification = "customer-pii"` on the documents bucket, `severity` on alerts). Removed duplicate manual labels from secrets, storage, and monitoring resources.

### Operability

**CI/CD pipeline** — Added a GitHub Actions workflow (`.github/workflows/terraform-ci.yml`) that runs on every PR: `terraform fmt`, `validate`, TFLint (GCP ruleset), tfsec, Checkov, Trivy, and Gitleaks. Plan output is posted as a PR comment. All checks must pass via a CI Gate before merge. On merge to `main`, `terraform apply` runs against production behind a GitHub Environment protection gate. Auth uses Workload Identity Federation — no long-lived service account keys.

**Pre-commit hooks** — `.pre-commit-config.yaml` runs the same fmt, validate, tflint, and tfsec checks locally before push. CI is the enforcement gate, but pre-commit gives developers fast feedback without waiting for a pipeline round-trip.

**Remote state with locking** — GCS backend with per-environment prefix (`backend.tf` in each environment folder). GCS has native state locking — no additional infrastructure needed. Each environment uses its own state bucket (`docuvault-dev-terraform-state`, `docuvault-prod-terraform-state`) so a developer with dev state access cannot read production secrets from state. The buckets should live in their respective GCP projects.

**`.gitignore`** — Added standard Terraform ignores (`.terraform/`, `*.tfstate`, `crash.log`), sensitive file patterns (`*.tfvars` with an exception for the production tfvars that contains no secrets), and IDE/OS files. For a codebase about hardening secrets, preventing accidental commits of state files or local tfvars is baseline hygiene.

### Developer Experience

**Project restructure** — Split into `gcp/development/` and `gcp/production/` folders instead of workspaces. Developers can see what environments exist by looking at the directory tree, and `cd gcp/development` means you know you're not touching production. Each environment has its own `main.tf`, `versions.tf`, and `backend.tf`.

**Module split** — Split the flat codebase into five sub-modules (`network`, `iam`, `backend`, `frontend`, `monitoring`) called by a `docuvault` orchestrator. Each module has its own variables, outputs, and owns its own resource-scoped IAM bindings. The orchestrator wires outputs between modules — a developer changing a Cloud Run service never touches the database or network config. Resource-scoped IAM lives in the module that owns the resource (e.g. secret accessor bindings in `backend/`, run invoker in `frontend/`).

**Provider and version pinning** — `required_version >= 1.7` and provider pinned to `~> 5.46`. Provider config moved out of the module into the root (where it belongs) so each environment controls its own provider settings.

---

## What I Chose Not to Fix and Why

**Enforced policy-as-code** — Checkov, tfsec, and Trivy catch misconfigurations in CI, but they run as checks that can be bypassed (admin merge, laptop apply). For fintech I'd want the policy engine in the apply path — tools like Atlantis, Spacelift, or Terraform Enterprise put policy checks between `plan` and `apply` so non-compliant infrastructure physically cannot be deployed. The big win for audits is that well-written policy-as-code is proof — not just that you check for insecure config, but that it's not even possible to deploy it. Spacelift and Terraform Enterprise are SOC2 Type II certified themselves, which matters when auditors ask about the toolchain. This requires infrastructure (a server or SaaS account) beyond the scope of a take-home, but the `policy/` directory exists as a placeholder.

**Cloud Armor / WAF** — The web UI is customer-facing behind a load balancer, but there's no Cloud Armor security policy. For a fintech platform handling identity verification documents, banks and auditors will ask how public endpoints are protected. Cloud Armor provides layer 3/4 DDoS mitigation (Adaptive Protection), preconfigured OWASP Top 10 WAF rules (SQLi, XSS, LFI, RCE), geo-blocking to restrict traffic to operating regions, rate limiting, and IP allowlisting/denylisting. The policy attaches to a backend service behind the external HTTP(S) load balancer. Cloud Armor Standard is free; managed WAF rules and Adaptive Protection require Cloud Armor Enterprise (~$3,000/month + per-request). For fintech the cost is easily justified — a single DDoS or SQLi exfiltration would cost far more. Not implemented here because Cloud Armor requires a load balancer backend service resource that doesn't exist yet in the Terraform (Cloud Run ingress is handled differently), but it should be a Week 1 item once the load balancer is provisioned.

**CMEK (Customer-Managed Encryption Keys)** — All data in GCP is encrypted at rest by default using Google-managed keys. For a fintech platform storing customer PII, banks and compliance frameworks (PCI-DSS requirement 3.5, SOC2 CC6.1) increasingly expect customer-managed encryption. CMEK gives you key lifecycle control (rotate, disable, destroy on your schedule), separation of duties (key management ≠ data management), crypto-shredding (destroy the key and data becomes permanently unreadable — definitive "right to be forgotten"), and an audit trail of every key usage in Cloud Audit Logs. Cloud SQL, GCS, and Secret Manager all support CMEK via Cloud KMS. Cost is negligible ($0.06/month per key version + $0.03 per 10k operations), but operational complexity is real — key rotation, disaster recovery (lose the key, lose the data), and cross-region replication of keyrings. This is a Week 2–3 item: create a KMS keyring with per-resource-type keys, grant each GCP service agent `cloudkms.cryptoKeyEncrypterDecrypter` on its specific key, and add `encryption_key_name` to Cloud SQL and `default_kms_key_name` to GCS.

**VPC Service Controls** — VPC-SC creates a security perimeter around GCP services that prevents data exfiltration — even by authorised principals. Without it, a compromised service account could copy the documents bucket to an external project. With it, services inside the perimeter can only communicate with other services inside the perimeter. VPC-SC also provides context-aware access (restrict API calls by IP, device, identity) and logs every denied request at the boundary. For banks this is often a hard requirement — it's the GCP equivalent of a network security boundary. Not implemented because it requires an Access Context Manager policy (org-level resource), careful ingress/egress rules, and can break legitimate API calls if misconfigured. Should be deployed in dry-run mode first to observe what would be blocked, then enforced. This is a Week 3–4 initiative.

**Cloud SQL maintenance window** — The database has no `maintenance_window` configured, meaning GCP can apply patches at any time including peak hours. For a fintech identity-verification platform, an unexpected database restart during customer onboarding means failed verifications. The fix is a one-liner (`maintenance_window { day = 7, hour = 4, update_track = "stable" }`) targeting Sunday 4 AM UTC on the stable track (most battle-tested patches). Should also add a `deny_maintenance_period` for critical business periods. Not included in this pass but should be added immediately — it's low effort, high operability impact.

**CORS origin is a placeholder** — The storage bucket CORS origin is set to `https://${var.project_name}.example.com` which won't work in practice. If the web UI makes direct browser requests to GCS (e.g. signed URL uploads), the CORS origin must match the real application domain. This should be a variable so each environment uses its own domain, with a validation block enforcing HTTPS-only origins. The `response_header` list should also include `Content-Disposition` and potentially `Content-Range` / `x-goog-resumable` if resumable uploads are used. Quick fix, just needs the real domain to be decided.

---

## Next Steps (30-Day Roadmap)

### Start with OpenTofu, Not Terraform

Since this infrastructure has not been deployed yet, there is no existing state to migrate and no binary to swap mid-flight. This is the ideal time to start with [OpenTofu](https://opentofu.org/) rather than planning a future migration. OpenTofu is the open-source fork of Terraform maintained by the Linux Foundation — same HCL syntax, same state format, same providers, same workflow. The CI pipeline just uses `tofu` instead of `terraform`.

Why start with OpenTofu now:
- **Variable references in `source` and `backend` blocks** — no more hardcoding bucket names or module paths. This codebase currently duplicates the module source path and state bucket name across environments; OpenTofu lets you variablise both
- **Native state encryption at rest** — encrypts sensitive values in state without relying solely on the backend's encryption. Directly addresses the "generated secrets in Terraform state" concern from day one
- **`for_each` on provider blocks** — useful if the platform expands to multi-project or multi-region
- **No licence risk** — OpenTofu is MPL 2.0 under the Linux Foundation. Terraform's BSL licence restricts competitive usage, which may matter as the company scales
- **Features that Terraform locks behind Enterprise/Cloud are available in the open-source CLI** — e.g. OPA policy evaluation, run tasks, and ephemeral values

There is no migration cost because there is nothing to migrate. The team learns one tool from the start, and gets the better feature set from day one.

### Week-by-Week

**Week 1 — Foundations**
- Switch to OpenTofu (replace `terraform` with `tofu` in CI and pre-commit — no other changes needed)
- Add Cloud SQL `maintenance_window` (one-liner, high operability impact)
- Make CORS origin a variable with HTTPS validation
- Add variable validation blocks (`environment`, image tags rejecting `:latest`, `project_id` format)
- Expose Cloud SQL instance tier, `availability_type`, and Cloud Run resource limits (`cpu`, `memory`, `maxScale`) as variables with safe production defaults — dev opts into cheaper settings (`db-f1-micro`, `ZONAL`), production gets HA automatically
- Add module READMEs via terraform-docs
- Provision Cloud Armor WAF policy once external load balancer is in place

**Week 2 — Load Testing, Policy-as-Code, CMEK**
- Deploy to development with realistic traffic simulation
- Load test and tune alert thresholds — current values (CPU > 80%, memory > 85%, 5xx > 5%) are reasonable starting points but not validated against real workload data. An identity verification service may spike CPU during document processing, and the 5xx threshold may be too generous where every failed verification is a lost customer
- Observe baseline resource usage, set thresholds relative to baselines, start with warning-level alerts (Slack) before escalating to PagerDuty pages
- Right-size the production instance tier using load test data — `db-custom-2-4096` is a starting point but actual requirements depend on connection count, query complexity, and dataset size
- Deploy Atlantis, evaluate Spacelift, or Terraform Enterprise for enforced policy-as-code — the goal is being able to **prove** to auditors that non-compliant infrastructure cannot be deployed, not just that you check for it. Policy-as-code (OPA/Sentinel) is audit evidence. Spacelift and Terraform Enterprise are both SOC2 Type II certified
- Write policies for critical guardrails: no public buckets, no `0.0.0.0/0`, no overly permissive IAM, no plaintext secrets, no `:latest` image tags
- Set up drift detection (scheduled plan that alerts on non-empty diffs)
- Begin CMEK implementation — KMS keyring, per-resource keys, service agent IAM bindings

**Week 3 — VPC Service Controls, Monitoring Gaps**
- Deploy VPC Service Controls in dry-run mode
- Add alerts for Secret Manager access anomalies and IAM policy changes
- Add uptime checks for the web UI endpoint
- Review alert frequency from Week 2 — tune thresholds that are too noisy or too quiet

**Week 4 — Enforce, Document, Launch-Ready**
- Enforce VPC Service Controls after dry-run validation
- Developer documentation and onboarding
- Runbook for break-glass database access via IAM + Cloud SQL Auth Proxy
- Runbook for state recovery
- Final alert threshold review before production launch

---

### Database Access for Debugging

With IAM database authentication enabled, break-glass access works like this:

1. Developer requests access via a ticketed process
2. A time-bounded IAM binding is granted: `roles/cloudsql.client` with an IAM condition (`request.time < timestamp("...")`)
3. Developer connects via Cloud SQL Auth Proxy using their own Google identity — no shared password
4. Access is auditable (Cloud SQL audit logs show the individual's identity) and auto-expires

The shared password user (`docuvault-app`) exists as a fallback but should only be used if IAM auth isn't supported by the application's database driver.


## Assumptions

- **This infrastructure has not been deployed yet.** The original codebase had `deletion_protection = false`, a `db-f1-micro` instance with no backups, TODO comments for production hardening, and test credentials as variable defaults. The brief confirms `terraform apply` is not expected. Because nothing is live, I was able to make breaking structural changes (module split, state bucket separation, secret management pattern, starting with OpenTofu instead of migrating later) without worrying about state migration, import workflows, or downtime. If this were a live system, several of these changes would need a careful migration plan with `terraform state mv` and `terraform import` steps.
- The two Cloud Run services (web-ui, api-backend) are the only workloads — no VMs, GKE, or other compute
- The web UI is customer-facing and needs to be publicly accessible via a load balancer
- The API backend is internal only — called by the web UI, not directly by customers
- The Onfido API key is provisioned externally and provided at deploy time — Terraform doesn't manage the Onfido account
- The GCS state buckets (`docuvault-dev-terraform-state`, `docuvault-prod-terraform-state`) exist in their respective GCP projects and are pre-configured with appropriate IAM
