# Experimental version of the GOV.UK Knowledge Graph on Google Cloud Platform

## Terraform

Terraform has been configured to "plan" on any push to a pull request, and
"apply" on any merge to the "main" branch.

To run locally, provide your own github token from `gh auth status
--show-token`.

```sh
export GITHUB_TOKEN=$( \
  gh auth status --show-token 2>&1 >/dev/null \
  | grep "oken" -A 0 -B 0 \
  | grep -oP '\w+$' \
)
terraform apply
```

If retrospectively terraforming a resource that already exists, you'll have to
import it first.  That probably goes for the repository, branch, collaborator,
etc.  One does not simply bootstrap a terraform configuration.

## Authentication

There must be a repository secret called `TERRAFORM_TOKEN_GITHUB` that is a
PAT (personal access token) with full `repo` and `admin:org` permissions, and
that belongs to an admin of this repository.

## Licence

Unless stated otherwise, the codebase is released under [the MIT License][mit].
This covers both the codebase and any sample code in the documentation.

The documentation is [© Crown copyright][copyright] and available under the terms
of the [Open Government 3.0][ogl] licence.

[rvm]: https://www.ruby-lang.org/en/documentation/installation/#managers
[bundler]: http://bundler.io/
[mit]: LICENCE
[copyright]: http://www.nationalarchives.gov.uk/information-management/re-using-public-sector-information/uk-government-licensing-framework/crown-copyright/
[ogl]: http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/
