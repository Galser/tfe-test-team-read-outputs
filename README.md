# tfe-test-team-read-outputs
TFE - Test fro the issue - team with 'read-outputs' permission in custom - edit permissions not able to read outputs

# Hypothesis

Creation of a team for the workspace in question was done with:

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

# TODO 

- [ ] Create code for team creation
- [ ] Update readme
