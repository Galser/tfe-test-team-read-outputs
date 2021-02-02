# tfe-test-team-read-outputs
TFE - Test fro the issue - team with 'read-outputs' permission in custom - edit permissions not able to read outputs

# Hypothesis

The creation of a team for the workspace in question was done with:

```Terraform
permissions {
  runs = "apply"
  variables = "read"
  state_versions = "read-outputs"
  sentinel_mocks = "none"
  workspace_locking = false
}
```

While getting the outputs with `terraform output` - we can't actually see the output (`project_id` for example)

By changing the permissions of the team via the UI one the page which shows the below:
__________________
State versions
No access
No access to state versions associated with this workspace.

Read outputs only
Can read output values from the workspace's state versions.

Read
Can read the workspace's state versions.

Read and write
Can view and manually create new state versions. This permission is only required when the workspace execution mode is set to "Local".
_______________
and modifying the permission from "Read outputs only" to "Read" allowed us to workaround and stop seeing the failure that the project_id was not found. (We no longer have the exact error message, because unfortunately GitHub actions overwrite their logged output when re-run.)

These are outputs that are declared in the root module, using `output`. They are being read from a remote TFE (remote operation) call with `terraform output -json`. When we use a team token that only has custom permissions with state_versions = "read-outputs", we get no outputs, just an empty JSON object {}. When we elevate that team's access to state_versions = "read", it returns the JSON we expect (namely, the `outputs` object we can see in the workspace's state in the TFE UI).

I've reproduced this behavior with the following, simple string output:
```json
{
"project_id": {
"sensitive": false,
"type": "string",
"value": "test string"
}
}
```

# Testing 

Providing the code in [main.tf](main.tf) included the following piece for workspace, team, and team access creation :

```Terraform
...
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
...
```

> I've left away variables and provider definition

We defined **TFE_TOKEN** env variable with the value of the freshly created API TOKEN for the used TFE instance, as well **as oauth_token_id** - corresponding to the appropriate VCS connection - that **should be already defined in your testing TFE** and have access to the `repo_identifier` repository.

- Run `terraform init`, example log of init can be found [here](terraform_init.md)

- Execute `terraform apply --auto-approve`, example output  : 

```bash
 terraform apply --auto-approve
random_pet.workspace: Creating...
random_pet.workspace: Creation complete after 0s [id=faithful-stinkbug]
tfe_team.test: Creating...
tfe_workspace.test: Creating...
tfe_team.test: Creation complete after 1s [id=team-sfvaGUvgoexHLJBm]
tfe_team_token.test: Creating...
tfe_team_token.test: Creation complete after 0s [id=team-sfvaGUvgoexHLJBm]
tfe_workspace.test: Creation complete after 2s [id=ws-BSZEMJid5dL5ofKy]
data.template_file.test_code: Reading...
tfe_team_access.test: Creating...
data.template_file.test_code: Read complete after 0s [id=4b291405eb993fdf712730ee84362172cc4ad3d9f9ae9c2c8e3da550ab26b39f]
local_file.test_code: Creating...
local_file.test_code: Creation complete after 0s [id=210748da43eb413a15e5653722eb79cd8ab8d9fd]
tfe_team_access.test: Creation complete after 1s [id=tws-sEDSA1ZXP4bxgRqQ]

Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

workspaces = {
  "test-code-location" = "test-code/main.tf"
  "workspace-with-public-outputs" = "faithful-stinkbug"
}
```
- Now - the code had created 1 workspace with a random name ( "faithful-stinkbug" in the example ) and you have a special path in output  "test-code/main.tf"
- Return back to the TFE, there should be already an `apply` running in that new workspace, wait for it to finish, it should be fast and very simple : 

```
 
 
 
Terraform v0.13.5
Initializing plugins and modules...
random_pet.demo: Creating...
random_pet.demo: Creation complete after 0s [id=above-stallion]

Warning: Interpolation-only expressions are deprecated

  on maint.tf line 4, in output "demo":
   4:   value = "${random_pet.demo.id}"

Terraform 0.11 and earlier required all non-constant expressions to be
provided via interpolation syntax, but this pattern is now deprecated. To
silence this warning, remove the "${ sequence from the start and the }"
sequence from the end of this expression, leaving just the inner expression.

Template interpolation syntax is still used to construct strings from
expressions when the template includes multiple interpolation sequences or a
mixture of literal strings and interpolations. This deprecation applies only
to templates that consist entirely of a single interpolation sequence.


Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

demo = above-stallion

```
Note the "demo" output with value "above-stallion"
- Return back to our demo code folder
- Change directory to the subpath "test-code"
- The apply above should've generated `main.tf` for you with all data already pre-defined.
- Run `terraform init`
- Followed by: `terraform apply --auto-approve` 
- Run `terraform output`, observe the  following : 

```bash

Warning: No outputs found

The state file either has no outputs defined, or all the defined outputs are
empty. Please define an output in your configuration with the `output` keyword
and run `terraform refresh` for it to become available. If you are using
interpolation, please verify the interpolated value is not empty. You can use
the `terraform console` command to assist.
```
While it should be the value of the output with name `demo` from the newly created workspace

- Okay, let's test what happens when we change team access for the state. Go back to the root of the repo.
- In file `main.tf` lines 66-67 look like : 

```Terraform
    state_versions = "read-outputs"
    #state_versions    = "read"
```

- Change it to : 

```Terraform
    #state_versions = "read-outputs"
    state_versions    = "read"
```

- Run again: `terraform apply --auto-approve` : 

Example output : 

```bash
random_pet.workspace: Refreshing state... [id=faithful-stinkbug]
tfe_team.test: Refreshing state... [id=team-sfvaGUvgoexHLJBm]
tfe_workspace.test: Refreshing state... [id=ws-BSZEMJid5dL5ofKy]
tfe_team_token.test: Refreshing state... [id=team-sfvaGUvgoexHLJBm]
tfe_team_access.test: Refreshing state... [id=tws-sEDSA1ZXP4bxgRqQ]
local_file.test_code: Refreshing state... [id=210748da43eb413a15e5653722eb79cd8ab8d9fd]
tfe_team_access.test: Modifying... [id=tws-sEDSA1ZXP4bxgRqQ]
tfe_team_access.test: Modifications complete after 1s [id=tws-sEDSA1ZXP4bxgRqQ]

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

Outputs:

workspaces = {
  "test-code-location" = "test-code/main.tf"
  "workspace-with-public-outputs" = "faithful-stinkbug"
}
```

- Now cd again to the subfolder `test-code` 
- Run `terraform apply --auto-approve`. 

Observe that output - **already** had changed : 

```bash
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

pet-name-from-test-workspace-via-team-token = "above-stallion"
```
- Run `terraform output` , observe the correct output, as it should be  : 

```bash
pet-name-from-test-workspace-via-team-token = "above-stallion"
```

Conclusion: In theory, we should be able to read outputs from the designated remote state using the appropriate team token for the team with only permission `state_versions = "read-outputs"`. And this is not happening. Looks like a bug.


# TODO

- [X] Create code for team creation
- [X] Update readme
