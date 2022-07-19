terraform {
  required_version = "~> 1.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }
}

provider "github" {
  owner = "alphagov"
}

resource "github_repository" "repo" {
  name                   = "govuk-knowledge-graph-gcp"
  description            = "Experimental version of govuk-knowledge-graph hosted on the Google Cloud Platform"
  visibility             = "internal"
  delete_branch_on_merge = true
  has_downloads          = true
  has_issues             = true
  vulnerability_alerts   = true
}

# Add an admin user to the repository
resource "github_repository_collaborator" "duncan_garmonsway" {
  repository = github_repository.repo.name
  username   = "nacnudus"
  permission = "admin"
}

resource "github_branch" "main" {
  repository = github_repository.repo.name
  branch     = "main"
}

resource "github_branch_default" "default" {
  repository = github_repository.repo.name
  branch     = github_branch.main.branch
}

resource "github_branch_protection" "main" {
  repository_id           = github_repository.repo.node_id
  pattern                 = "main"
  allows_deletions        = false
  require_signed_commits  = true
  required_linear_history = true
  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 1
  }
}
