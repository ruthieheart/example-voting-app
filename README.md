# Example Voting App — DevOps Capstone

## 1. Project Overview

This project uses the Docker Samples Example Voting App to demonstrate a beginner DevOps workflow. It covers containerization, local application testing, automated CI/CD, container image security scanning, infrastructure as code, and Kubernetes deployment configuration.

The application allows users to vote between two options and displays the results.

## 2. Architecture

The application consists of these services:

- **Vote:** Web interface for submitting votes.
- **Redis:** Temporarily stores submitted votes in a queue.
- **Worker:** Reads votes from Redis and records them in PostgreSQL.
- **PostgreSQL:** Stores the votes.
- **Result:** Web interface that displays the voting results.

### DevOps components

- **Docker and Docker Compose:** Build and run the application containers locally.
- **GitHub Actions:** Automates application smoke tests, image builds, vulnerability scanning, and image publishing.
- **Trivy:**  Scans container images for high and critical vulnerabilities. The scan is currently non-blocking while reported findings are reviewed and remediated.
- **Terraform:** Defines AWS networking and Amazon EKS infrastructure.
- **Helm:** Packages the application and its supporting services as Kubernetes resources.

## 3. Prerequisites

Install the following tools for the relevant tasks:

- Git and a GitHub account
- Docker Desktop with WSL 2 integration, or Docker Engine with Docker Compose
- Terraform
- Helm
- `kubectl` for Kubernetes administration
- AWS CLI and appropriate AWS credentials for a future AWS deployment

## 4. Run the Application Locally

Clone your repository and enter the project directory:

```bash
git clone https://github.com/ruthieheart/example-voting-app.git
cd example-voting-app
```

Create a local `.env` file. Do not commit this file or put real credentials in source control.

```bash
cat > .env <<'ENV'
POSTGRES_USER=postgres
POSTGRES_PASSWORD=replace-with-a-local-password
DATABASE_URL=postgres://postgres:replace-with-a-local-password@db/postgres
DB_CONNECTION_STRING=Server=db;Username=postgres;Password=replace-with-a-local-password;
ENV
```

Build and start the services:

```bash
docker compose up -d --build --wait
docker compose ps
```

Open the application in a browser:

- Voting page: http://localhost:8080
- Results page: http://localhost:8081

View service logs:

```bash
docker compose logs --tail=50
```

Stop the application:

```bash
docker compose down
```

To remove the local database volume and its stored test data as well, run:

```bash
docker compose down -v
```

**Warning:** Removing volumes permanently deletes the data stored in those volumes.

## 5. Continuous Integration and Delivery

The workflow is defined in `.github/workflows/capstone-ci-cd.yml`.

When changes are pushed to `main` or a pull request targets `main`, the workflow runs an application smoke test using Docker Compose. It checks that the voting and results pages respond and that a submitted vote appears in the results.

After the smoke test succeeds, the workflow builds the vote, result, and worker images and scans them with Trivy. High and critical vulnerabilities that are not fixed are configured to fail the scan.

When a push to `main` passes the preceding jobs, the workflow publishes the images to GitHub Container Registry (GHCR).

The image names follow this pattern:

```text
ghcr.io/ruthieheart/example-voting-app-vote
ghcr.io/ruthieheart/example-voting-app-result
ghcr.io/ruthieheart/example-voting-app-worker
```

The workflow uses GitHub's `GITHUB_TOKEN` for registry authentication. No hard-coded registry credentials are required.

After pushing the workflow to GitHub, check the **Actions** tab to confirm whether the workflow actually passes. A workflow file in the repository does not, by itself, prove a successful CI run.

## 6. Terraform Infrastructure

The `terraform/` directory defines the AWS infrastructure for a proposed deployment, including:

- A Virtual Private Cloud (VPC)
- Public and private subnets across availability zones
- An Amazon EKS Kubernetes cluster
- A managed worker node group

The example is designed to avoid NAT Gateway charges, but it is not a production-ready network design. The cluster API endpoint is private, so administration requires access through suitable private connectivity into the VPC. Confirm node networking and image-pull connectivity before attempting deployment.

Validate the configuration:

```bash
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform validate
```

Review any proposed infrastructure changes with `terraform plan` after configuring AWS credentials and the required provider access.

**Cost and deployment notice:** Terraform validation does not create AWS resources. No AWS deployment is claimed by this repository documentation. Do not run `terraform apply` unless deployment is explicitly approved, the estimated costs are understood, and the required access and networking have been reviewed.

## 7. Kubernetes Deployment with Helm

The `helm/example-voting-app/` chart defines Kubernetes resources for the vote, result, worker, Redis, and PostgreSQL services.

Lint and render the chart locally:

```bash
helm lint helm/example-voting-app
helm template voting helm/example-voting-app
```

Before a real deployment:

1. Ensure the three application images have been built, scanned, and published.
2. Ensure the cluster can pull the images from GHCR. Configure package visibility or image-pull credentials as appropriate.
3. Replace the chart's demo database password with a secure deployment-specific secret.
4. Review persistent storage, backups, resource limits, health probes, network exposure, and availability requirements.
5. Configure access to the private EKS API endpoint.

The chart currently uses a demonstration password value. Do not use that default in a real environment. For production, use an appropriate Kubernetes Secret or a secrets-management integration instead of committing credentials to Helm values.

The chart uses internal ClusterIP services. Access to the web interfaces requires an approved ingress/load-balancer configuration or a temporary `kubectl port-forward` connection.

## 8. Security Considerations

- Keep `.env`, AWS credentials, registry credentials, and other secrets out of Git.
- Use least-privilege IAM permissions for automation and deployment.
- Review Trivy findings and update vulnerable dependencies and base images.
- The inherited application uses older runtime versions in some Dockerfiles. Review their support lifecycle and upgrade them in a tested change before production use.
- Restrict access to application and debugging ports.
- Use persistent storage and a tested backup/restore process for any deployment containing important votes.
- Use a remote Terraform backend with state locking and appropriate access controls for collaborative or production infrastructure work.

## 9. Validation Performed

The following local checks have been run successfully during project preparation:

- `docker compose config --quiet`
- `docker compose up -d --build --wait`
- Application smoke test through the voting and results pages
- `terraform -chdir=terraform fmt -check -recursive`
- `terraform -chdir=terraform validate`
- `helm lint helm/example-voting-app`
- `helm template voting helm/example-voting-app`

Additional deployment checks were completed on a local Minikube cluster:

- Helm release deployed successfully and application pods reached Running/Ready.
- Voting page and results page were accessed through Kubernetes port-forwarding.
- A test vote was cast and confirmed on the results page.
- A Helm upgrade was performed, then successfully rolled back to release revision 5.

These checks demonstrate a local Kubernetes deployment and rollback. They do not establish that AWS/EKS infrastructure was deployed.

## 10. Project Status

**Verified:** Docker Compose configuration and application behavior, Terraform formatting and validation, Helm chart linting and rendering, a successful GitHub Actions run, GHCR image publication, and local Minikube deployment with a successful Helm rollback.

**Not performed:** provisioning or deploying the application to AWS/EKS. Terraform configuration validation does not create cloud infrastructure.

The project status distinguishes verified local and CI/CD results from cloud deployment work that has not been performed.
