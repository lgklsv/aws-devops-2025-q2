# Task 6: Application Deployment via Jenkins Pipeline

## Overview

This task demonstrates a complete CI/CD pipeline using Jenkins to build, test, analyze, containerize, and deploy a Python Flask application to a Kubernetes cluster using Helm. The pipeline is defined in the `Jenkinsfile` and leverages Kubernetes, AWS ECR, SonarQube, and Slack for notifications.

---

## Pipeline Structure

The Jenkins pipeline (`Jenkinsfile`) is triggered on each push to the repository and consists of the following stages:

1. **Install Python Dependencies**

   - Installs all required Python packages from `requirements.txt` inside the application directory.

2. **Run Unit Tests**

   - Executes unit tests using `pytest` and generates a JUnit XML report for test results.

3. **SonarQube Analysis**

   - Runs static code analysis and security checks using SonarQube, uploading test and coverage results.

4. **Build & Push Docker Image**

   - Builds the Docker image for the Flask app using Kaniko and pushes it to AWS ECR. ECR authentication is handled securely using Jenkins credentials.

5. **Deploy to Kubernetes**

   - Uses Helm to deploy (or upgrade) the application on the Kubernetes cluster. The deployment uses the image built in the previous step and pulls secrets from ECR.

6. **Verify Application**
   - Optionally verifies the deployment by curling the main page of the application and checking for a successful response.

---

## Notification System

- Slack notifications are sent on both pipeline success and failure, providing immediate feedback on build status.

---

## Kubernetes RBAC

- The `jenkins-rbac.yaml` file defines the necessary Kubernetes Role and RoleBinding to allow the Jenkins agent to manage deployments, services, secrets, and other resources in the `default` namespace.

---

## How to Set Up and Run the Pipeline

1. **Prerequisites**

   - Jenkins server with Kubernetes plugin and required agents (Python, Kaniko, AWS CLI, kubectl)
   - AWS ECR repository for Docker images
   - SonarQube server and token
   - Slack webhook/token for notifications
   - Kubernetes cluster with Helm installed

2. **Repository Structure**

   - `flask_app/`: Python Flask application and Dockerfile
   - `flask-app-chart/`: Helm chart for deployment
   - `Jenkinsfile`: Pipeline definition
   - `jenkins-rbac.yaml`: Kubernetes RBAC for Jenkins

3. **Pipeline Configuration**

   - Store the `Jenkinsfile` in the root of your repository.
   - Configure Jenkins to trigger the pipeline on push events.
   - Set up the following Jenkins credentials:
     - `aws-account-id`: AWS account ID (string)
     - `aws-ecr-jenkins-credential`: AWS credentials for ECR (type: AWS)
     - `sonar-token-secret-id`: SonarQube token (string)
     - `k8s-cluster-kubeconfig`: Kubeconfig content for cluster access (string)

4. **RBAC Setup**

   - Apply `jenkins-rbac.yaml` to your Kubernetes cluster:
     ```sh
     kubectl apply -f jenkins-rbac.yaml
     ```

5. **Pipeline Execution**
   - On each push, Jenkins will:
     1. Install dependencies
     2. Run tests
     3. Analyze code with SonarQube
     4. Build and push Docker image to ECR
     5. Deploy/update the app on Kubernetes using Helm
     6. Verify the deployment
     7. Send Slack notifications

---

## Application Verification

- The pipeline verifies the deployment by curling the application's main page and checking for the expected response (e.g., 'Hello, World!').

