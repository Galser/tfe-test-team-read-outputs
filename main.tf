# VARIABLES
# We putting them here as we want to have ONE code file for thw hole test
variable "hostname" {
  default = "tfe-migtest-2.guselietov.com"
}

variable "org" {
  default = "migrotest"
}

variable "oauth_token" {
  default = "ot-XBbeoMfT8JAtf8yN" # VCS! 
}

variable "repo_identifier" {
  default = "Galser/tfc-random-pet"
  # My test repos that contains following code : 
  #
  # resource "random_pet" "demo" { }

  # output "demo" {
  #   value = "${random_pet.demo.id}"
  # }
  # 
  # So we should be able to access "demo" output
}

resource "random_pet" "workspace" {}

#
provider "tfe" {
  hostname = var.hostname
  #  token    = var.token. --> oinly if we really want it
  #  for the test we assume it is coming from TFE_TOKEN env var
  #  version  = "~> 0.15.0"
}

# RESOURCES 

# Creating workspaces
resource "tfe_workspace" "test" {
  name         = random_pet.workspace.id
  organization = var.org
  auto_apply   = true
  vcs_repo {
    identifier         = var.repo_identifier
    ingress_submodules = false
    oauth_token_id     = var.oauth_token
  }
}

# Creating team
resource "tfe_team" "test" {
  name         = "test-team"
  organization = var.org
}

# Adjusting permissions to the team above
# for out model workspace
resource "tfe_team_access" "test" {
  team_id      = tfe_team.test.id
  workspace_id = tfe_workspace.test.id
  permissions {
    runs           = "apply"
    variables      = "read"
    state_versions = "read-outputs"
    #state_versions    = "read"
    sentinel_mocks    = "none"
    workspace_locking = false
  }
}

# Team token
resource "tfe_team_token" "test" {
  team_id          = tfe_team.test.id
  force_regenerate = true
}

# Generation of test code  
# 
data "template_file" "test_code" {
  template = file("test-code/test.tf.tmpl")

  vars = {
    #    tfe_install_url = var.tfe_install_url
    #    distribution    = var.distribution
    host           = var.hostname
    org            = var.org
    data_workspace = tfe_workspace.test.name

    team_token = tfe_team_token.test.token
  }
}

# Saving it
resource "local_file" "test_code" {
  content  = data.template_file.test_code.rendered
  filename = "test-code/main.tf"
}


output "workspaces" {
  value = {
    workspace-with-public-outputs = tfe_workspace.test.name
    test-code-location            = "test-code/main.tf"
  }
}
