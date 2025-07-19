# Task 5: Simple Application Deployment with Helm

This guide explains how to containerize a simple Flask application, create a Helm chart for it, deploy it to a Kubernetes cluster (Minikube), and verify the deployment.

---

## Project Structure

```
├── flask_app/
│   ├── main.py           # Flask application code
│   ├── requirements.txt  # Python dependencies
│   └── Dockerfile        # Docker build instructions
├── flask-app-chart/
│   ├── Chart.yaml        # Helm chart metadata
│   ├── charts/           # (empty)
│   ├── templates/
│   │   ├── NOTES.txt
│   │   ├── _helpers.tpl
│   │   ├── deployment.yaml
│   │   ├── ingress.yaml  # (optional/removed)
│   │   ├── service.yaml
│   │   └── serviceaccount.yaml # (optional/removed)
│   └── values.yaml       # Chart configuration values
└── README.md             # This documentation file
```

---

## Application Overview

- The Flask app listens on `0.0.0.0:8080` and serves a simple web page at `/`.

---

## Prerequisites

- **Minikube**: Local Kubernetes cluster ([Install Guide](https://minikube.sigs.k8s.io/docs/start/))
- **kubectl**: Kubernetes CLI ([Install Guide](https://kubernetes.io/docs/tasks/tools/))
- **Helm**: Kubernetes package manager ([Install Guide](https://helm.sh/docs/intro/install/))
- **Docker**: For building the image ([Install Guide](https://docs.docker.com/get-docker/))

---

## Setup and Deployment

### 1. Start Minikube

```bash
minikube start
```

### 2. Containerize the Flask Application

```bash
cd flask_app
```

#### a. Use Minikube's Docker Daemon

```bash
eval $(minikube docker-env)
```

#### b. Build the Docker Image

```bash
docker build -t flask-app:v1.0.0 .
```

---

### 3. Helm Chart Setup

```bash
cd .. # Go back to project root
```

If not already created:

```bash
helm create flask-app-chart
```

#### a. Edit `flask-app-chart/values.yaml`

Set the image and service values:

```yaml
image:
  repository: flask-app
  tag: v1.0.0
  pullPolicy: IfNotPresent
service:
  type: NodePort
  port: 8080
  targetPort: 8080
  # nodePort: (optional, Minikube will assign if omitted)
ingress:
  enabled: false
```

#### b. Check `deployment.yaml` and `service.yaml`

- In `deployment.yaml`, ensure `containerPort: 8080`.
- In `service.yaml`, ensure ports are templated from `values.yaml`.

---

### 4. Deploy with Helm

From the project root:

```bash
helm upgrade --install flask-app-release ./flask-app-chart
```

---

### 5. Verify Deployment

```bash
helm list
kubectl get pods
kubectl get services
```

- You should see your release, a running pod, and a NodePort service.

To view pod logs (replace `<pod-name>`):

```bash
kubectl logs <pod-name>
```

Look for output like:

```
* Serving Flask app 'main'
* Running on http://0.0.0.0:8080
```

---

### 6. Access the Application

Get the service URL:

```bash
minikube service flask-app-release-flask-app-chart --url
```

Open the URL in your browser. You should see your Flask app's main page.
