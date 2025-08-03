# nullpoint-aws

The initial phase of the complex modular deployment involves preparing an AWS account for ongoing deployments.

## Local Testing with act

You can test the GitHub Actions pipeline locally using [act](https://github.com/nektos/act) before pushing to GitHub.

### Prerequisites
- [act](https://github.com/nektos/act) installed
- AWS CLI configured with valid credentials
- Docker running

### Run Pipeline Locally

```bash
act -j terraform \
  --env AWS_ACCESS_KEY_ID="$(aws configure get aws_access_key_id)" \
  --env AWS_SECRET_ACCESS_KEY="$(aws configure get aws_secret_access_key)" \
  --env AWS_DEFAULT_REGION="$(aws configure get region || echo eu-central-1)"
```

This command:
- Runs the `terraform` job from `.github/workflows/terraform.yml`
- Automatically extracts AWS credentials from your local AWS CLI configuration
- Uses your configured AWS region, or defaults to `eu-central-1`
- Tests AWS CLI authentication and basic AWS operations

The same pipeline file works identically in both local testing and GitHub Actions.