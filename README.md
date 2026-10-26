# runner-appbaq-terraform

An Azure virtual machine is provisioned to host a GitHub Actions runner.
Its configuration is then performed through the companion repository
`runner-appbaq-ansible`.

## Scope and Resource Ownership

AKS has been selected for the application infrastructure, which is managed in
a separate repository: [appbaq-infra-terraform](https://github.com/thomas-enj/appbaq-infra-terraform/).
Only the runner tooling is provisioned here.

- Runner resources are managed in a dedicated Terraform state.
- The existing resource group is referenced through a data source; it is
  neither managed nor destroyed by this configuration.
- Backend storage is prepared by a script outside the runner state. It is
  retained when the runner is destroyed.

An import is required only when a resource created outside Terraform is to be
adopted into its state. The mapping between the resource and its Terraform
address must then be recorded in an appropriately restricted location, and the
resulting plan must be reviewed. No new import is required for resources already
managed in the state or merely referenced through a data source.

## Structure

The Terraform root is located in `terraform/`. The `network` and `compute`
modules are called directly from that root. No intermediate parent module
is used.

- [Main configuration](terraform/main.tf).
- [Terraform variables](terraform/variables.tf).
- [Remote backend](terraform/backend.tf).
- [Network module](terraform/modules/network/main.tf).
- [Compute module](terraform/modules/compute/main.tf).
- [Backend bootstrap](deploy-remote-state-storage.sh).

## Workflows

### Plan and Apply

The [Runner - Plan and Apply](.github/workflows/deploy-runner.yml) workflow is
triggered by pull requests and pushes targeting `main`, or manually.

1. A plan is generated for same-repository pull requests, and its result is
   published in a comment that is updated on each run.
2. On `main`, a preview plan is generated before approval is requested through
   the `tf-apply` environment.
3. After approval, a local plan is regenerated and applied. The playbook from
   the Ansible repository is then executed.
4. A temporary SSH rule is opened for the configuration job. Its removal is
   attempted even if a subsequent step fails.

No apply is performed on pull requests. Azure plans for fork pull requests are
skipped. Manual runs on branches other than `main` are skipped.

### Destroy

The [Runner - Destroy](.github/workflows/destroy-runner.yml) workflow is
triggered only manually on `main`, without a text confirmation input.

1. A destruction plan is generated and displayed in the logs and run summary.
2. The plan can be reviewed before approval through `tf-destroy`.
3. After approval, the plan is regenerated and applied in a second job.

Destruction is blocked if the first job fails. The backend and shared resource
group are retained. Runner deregistration on GitHub has not yet been automated;
an offline entry may be left behind.

Both workflows are serialized through a shared concurrency group.
The runner state is kept separate from the application infrastructure state.

Sensitive data may be included in binary plans and state files. Neither is
published as a workflow artifact. Because the final plan is regenerated after
approval, differences from the preview are possible if resources or state have
changed in the meantime.

## Required Configuration

Environment-specific values are configured in GitHub; they are not reproduced
in this documentation.

| Type | Parameters | Purpose |
| --- | --- | --- |
| Repository variables | `TF_RGROUP`, `TF_SA_BACKEND`, `TF_OWNER` | Existing resource group, backend and state separation |
| Repository secrets | `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` | Azure authentication through OIDC |
| Repository secret | `MY_ADMIN_IP` | Network source allowed for administration |
| Repository secret | `PAT_GITHUB` | Request for a temporary GitHub runner registration token |

Parameters used by the plan job must be available at repository scope because
no GitHub environment is associated with that job.

The `tf-apply` and `tf-destroy` environments must be created with required
reviewers and deployment branches restricted to `main`. Without a **Required
reviewers** rule, no manual approval is enforced by the environment name alone.
Availability of this protection must be checked against the GitHub plan and
repository visibility.

### OIDC Federation

Federated credentials are configured on the application identified by
`AZURE_CLIENT_ID`, using the public issuer
`https://token.actions.githubusercontent.com` and audience
`api://AzureADTokenExchange`.

Separate subjects are required for `main`, pull requests, `tf-apply` and
`tf-destroy`. For a job associated with an environment, the branch subject is
replaced by the environment subject. The exact `subject claim` must be copied
from the Azure Login step; numeric identifiers may be included in that value.
No deployment-specific subject is published here.

For `AADSTS700213`, an exact match between subject, issuer and audience must be
verified. If a different value is generated by the portal wizard, the **Other
issuer** scenario can be used. Working federated credentials are retained until
their replacements have been validated.

## Preparation and Checks

An authorized Azure session, Terraform and Azure CLI are required for bootstrap.
The `OWNER`, `RG_BACKEND`, `SA_BACKEND`, `LOCATION` and `CONTAINER_BACKEND`
parameters must be set for the intended environment before the script is run.
Resources may be created or tagged, after which the local backend configuration
is updated. No migration is started automatically if a nonempty local state file
is detected.

The following local checks can be run from the repository root after providers
have been initialized:

```bash
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform validate -no-color
bash -n deploy-remote-state-storage.sh
```

Ansible changes must be merged into the companion repository's default branch
before deployment is rerun. After execution, the **Online / Idle** status must
be verified in the target application repository's runners, rather than in the
Terraform tooling repository.