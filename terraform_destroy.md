# Terraform destroy

```Terraform
terraform destroy --auto-approve
local_file.test_code: Destroying... [id=ab8b16c32772e58346aa2dc5e48e7f5162f1d72c]
local_file.test_code: Destruction complete after 0s
tfe_team_token.test: Destroying... [id=team-oA7fgSLRbfEjneyJ]
tfe_team_access.test: Destroying... [id=tws-7hvzFRGMQ7dM8WfG]
tfe_team_token.test: Destruction complete after 1s
tfe_team_access.test: Destruction complete after 1s
tfe_team.test: Destroying... [id=team-oA7fgSLRbfEjneyJ]
tfe_workspace.test: Destroying... [id=ws-CSKcSdAQiRb8HLhr]
tfe_team.test: Destruction complete after 0s
tfe_workspace.test: Destruction complete after 1s
random_pet.workspace: Destroying... [id=fast-rhino]
random_pet.workspace: Destruction complete after 0s

Destroy complete! Resources: 6 destroyed.
```
