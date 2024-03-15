# Terraform

There are three separate Google Cloud projects, each with its own terraform configuration. Each environment is meant to be exactly the same, except when planned changes are deployed to `dev` or `staging` for testing. The only permanent differences are roles/permissions, the GovSearch URL, and the GovSearch login mechanism.

| GCP Project                                    | Terraform                                | GovSearch                                                                                   | GOV.UK Signon                                                                                                 |
|------------------------------------------------|------------------------------------------|---------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------|
|       [govuk-knowledge-graph][gcp-prod]      |       [terraform][terraform-prod]      | [https://govgraphsearch.dev][govsearch-prod] redirects to https://gov-search.service.gov.uk | [Production][signon-prod]                                                                                     |
| [govuk-knowledge-graph-staging][gcp-staging] | [terraform-staging][terraform-staging] | [ https://govgraphsearchstaging.dev][govsearch-prod]                                        | Access is controlled by [Google IAM](../terraform-staging/environment.auto.tfvars) rather than GOV.UK Signon. |
|     [govuk-knowledge-graph-dev][gcp-dev]     |     [terraform-dev][terraform-dev]     | [ https://govgraphsearchdev.dev][govsearch-prod]                                            | [Integration][signon-integration]                                                                             |

## Deploying

There is no continuous deployment.  A person must run `terraform apply`.

The GCP API isn't perfect, and nor is terraform, and the most noticeable nuisance is certain "permadiffs" when doing `terraform plan`.  There are certain bits of infrastructure that it always thinks need to be changed. Let it try. If nothing breaks in `dev` or `staging`, be reassured about production.

## Pull requests

Pull requests that change files in any of the terraform directories will trigger GitHub actions.

* [Diff][github-action-diff] will fail if [`diff-terraform.sh`][diff] detects any differences between the configuration in each terraform directory.  Files and subdirectories listed in [`diff-exclude`][diff-exclude] are ignored, which is how GovSearch can be deployed differently in each environment.
* [Validate][github-action-validate] will fail if `terraform validate` fails or if `terraform fmt` would change any files.

Pull requests should not be merged until those checks pass.  That is no guarantee, however, that what is actually deployed is the same as what has been merged.

The production environment should be exactly the same as what has been merged to the `main` branch.  If `terraform apply` fails from the `terraform` directory on the `main` branch, then the production environment is out of sync with the `main` branch. Please fix it.

If `terraform apply` fails from the `terraform-dev` directory on a branch other than `main`, that is a normal part of doing new work, but the pull request isn't ready to merge until `terraform apply` succeeds.

If two people are working on different things at the same time, then one person should use the `dev` environment, and the other should use the `staging` environment, to avoid interference.  The `staging` environment is particularly useful for user testing, because users can be given temporary access to the GovSearch app via IAM permissions in this project, without having to use GOV.UK Signon accounts.  See the [`environment.auto.tfvars`](../terraform-staging/environment.auto.tfvars) file.

## How to allow differences between environments

Differences are configured in each environment's `environment.auto.tfvars` file.  This is self-explanatory for things such as lists of users who have certain roles and permissions.

To control whether a certain piece of infrastructure exists at all, look at how Redis is configured.  A variable, `enable_redis_session_store_instance` is defined in the configuration's `environment.auto.tfvars` file, which is allowed to differ between configurations by being listed in [`diff-exclude`][diff-exclude].  The terraform block that declares the Redis instance refers to that variable when deciding how many instances to create.  If the variable is true, then it is interpreted as 1 instance, otherwise it is interpreted as 0 instances.

```terraform
# Enable / Disable instance
count = var.enable_redis_session_store_instance ? 1 : 0
```

## What infrastructure is in what file

Most infrastructure is in a file named after the relevant GCP service.  For example, most buckets are configured in `storage.tf`.

Some infrastructure is in a file named after its purpose.  For example, most of the infrastructure of the GovSearch app is in the `govgraphsearch.tf` file.

It isn't possible to perfectly organise everything either by GCP service or by purpose.  It is useful to be able to do quick searches on the whole repository to find things that are referred to by other things.

When creating something that is similar to something that already exists, look for a pull request that implemented the original thing, to see what was involved.

[gcp-prod]: https://console.cloud.google.com/welcome?project=govuk-knowledge-graph
[gcp-staging]: https://console.cloud.google.com/welcome?project=govuk-knowledge-graph-staging
[gcp-dev]: https://console.cloud.google.com/welcome?project=govuk-knowledge-graph-dev
[terraform-prod]: ../terraform
[terraform-staging]: ../terraform-staging
[terraform-dev]: ../terraform-dev
[govsearch-prod]: https://govgraphsearch.dev
[govsearch-staging]: https://govgraphsearchstaging.dev
[govsearch-dev]: https://govgraphsearchdev.dev
[signon-prod]: https://signon.publishing.service.gov.uk/users/sign_in
[signon-integration]: https://signon.integration.publishing.service.gov.uk/users/sign_in
[github-action-diff]: ../.github/workflows/diff-terraform.yml
[github-action-validate]: ../.github/workflows/diff-terraform.yml
[diff]: ../diff-terraform.sh
[diff-exclude]: ../diff-exclude
