# Infrastructure Bootstrap Project

This project provisions foundational Google Cloud resources required for deploying and managing service infrastructure projects. It sets up a dedicated GCP project, storage for Terraform state, required APIs, IAM permissions, and service accounts.

## Purpose

The Terraform configuration in this repository creates and configures the following:
- A new Google Cloud project with billing enabled
- Required APIs for infrastructure services such as Compute Engine, Cloud Build, and Secret Manager
- A service account with the necessary IAM roles for deployment pipelines
- A Google Cloud Storage bucket for storing Terraform state with versioning and lifecycle rules
- A global static IP address for use with load balancers
- A Secret Manager secret for storing sensitive OAuth tokens (e.g., GitHub connection)

## Prerequisites

Before deploying this Terraform configuration, ensure you have the following:
- A Google Cloud billing account ID
- An existing Google Cloud project with permissions to create projects and enable APIs (bootstrap project)
- A GitHub OAuth token for Cloud Build GitHub connection

## Required Variables

Define the following variables in your `terraform.tfvars` or as environment variables:

| Variable                     | Description                                                         |
|------------------------------|---------------------------------------------------------------------|
| `billing_account_id`         | Billing account ID for the project                                 |
| `bootstrap_billing_project`  | Project used for API activation and resource creation              |
| `create_service_account_key` | Control whether a service account key is created for CI/CD (bool)  |
| `gh_oauth_token`             | OAuth token for Cloud Build GitHub connections                     |
| `project_id`                 | The GCP project ID to be created                                   |

## Usage

1. Clone this repository to your local machine.
2. Define all required variables in a `terraform.tfvars` file.
3. Initialize Terraform:

   ```
   terraform init
   ```

4. Review the execution plan:

   ```
   terraform plan
   ```

5. Apply the configuration:

   ```
   terraform apply
   ```

After successful deployment, the infrastructure project is ready for further use in service deployments and automation pipelines.

## Notes

- Ensure the bootstrap billing project has sufficient permissions to create new GCP projects and enable services.
- The `create_service_account_key` variable should be set to `true` only when a service account key is explicitly required. It is recommended to avoid unnecessary key creation to maintain security standards.
- Terraform state is stored in a versioned GCS bucket with lifecycle rules to retain only a limited number of object versions.

## License

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
