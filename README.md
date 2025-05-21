# Xayn Static Site Deployment – DevOps Task

Follow the steps in the README above or see `scripts/bootstrap-minikube.sh` for setup.

# Xayn Static Site Deployment

**Author:** Syed Muhammad Abdullah Jafri  
**Role:** Senior DevOps Engineer (m/f/d) | Legal AI Tech Start-up | Full Remote  

---

## Overview

This repository contains all the resources needed to deploy a simple static website on Kubernetes using Traefik as an Ingress controller. The deployment supports two isolated environments—**dev** and **prod**—each served over HTTPS (self-signed for local testing) and injecting runtime configuration via environment variables.

Key features:
- Kubernetes manifests managed with **Helm**  
- **Traefik** Ingress for routing and TLS termination  
- **Nginx** container serving a static HTML site with dynamic env var injection  
- Two environments: **dev** and **prod**  
- Environment-specific secrets and hostnames  
- HTTPS enabled with self-signed certificates  
- Health checks via liveness and readiness probes  
- Bootstrap script for local setup with **Minikube**  
- Optional Terraform templates for provisioning on **EKS** / **GKE**

---

## Table of Contents

1. [Prerequisites](#prerequisites)  
2. [Repository Structure](#repository-structure)  
3. [Local Setup (Minikube)](#local-setup-minikube)  
4. [Build & Load Docker Image](#build--load-docker-image)  
5. [Install Traefik Ingress Controller](#install-traefik-ingress-controller)  
6. [Create Namespaces](#create-namespaces)  
7. [Generate Self-Signed Certificates](#generate-self-signed-certificates)  
8. [Deploy Static Site with Helm](#deploy-static-site-with-helm)  
9. [Access the Applications](#access-the-applications)  
10. [Cleanup](#cleanup)  
11. [Optional: Terraform for Cloud Providers](#optional-terraform-for-cloud-providers)  
12. [License](#license)

---

## Prerequisites

- **kubectl** (v1.20+)  
- **Helm** (v3.0+)  
- **Minikube** (v1.15+)  
- **Docker**  
- **openssl**  
- **Git**

---

## Repository Structure

```
xayn-static-site-k8s/
├── static-site/                # Nginx Docker image with env var injection
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── index.html.template
├── helm/
│   └── static-site/            # Helm chart for static site (dev/prod)
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values.dev.yaml
│       ├── values.prod.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           ├── configmap.yaml
│           └── secret.yaml
├── scripts/
│   └── bootstrap-minikube.sh   # One-step script to set up Minikube, Traefik, and apps
├── terraform/
│   ├── eks/                    # Terraform templates for AWS EKS
│   └── gke/                    # Terraform templates for GKE
└── README.md                   # This file
```

---

## Local Setup (Minikube)

1. **Start Minikube**  
   ```bash
   minikube start --driver=docker
   ```

2. **Enable Docker environment for Minikube**  
   ```bash
   eval $(minikube docker-env)
   ```

---

## Build & Load Docker Image

```bash
docker build -t xayn/static-site:latest ./static-site
```

---

## Install Traefik Ingress Controller

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update

helm install traefik traefik/traefik \
  --namespace traefik --create-namespace \
  --set service.type=NodePort \
  --set service.nodePorts.https=30443
```

---

## Create Namespaces

```bash
kubectl create namespace xayn-dev
kubectl create namespace xayn-prod
```

---

## Generate Self-Signed Certificates

```bash
# Dev
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -subj "/CN=dev.xayn.local" \
  -keyout dev.key -out dev.crt
kubectl create secret tls dev-tls-cert \
  --key dev.key --cert dev.crt -n xayn-dev

# Prod
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -subj "/CN=prod.xayn.local" \
  -keyout prod.key -out prod.crt
kubectl create secret tls prod-tls-cert \
  --key prod.key --cert prod.crt -n xayn-prod
```

---

## Deploy Static Site with Helm

```bash
# Dev
helm install xayn-dev ./helm/static-site \
  -n xayn-dev \
  -f ./helm/static-site/values.dev.yaml

# Prod
helm install xayn-prod ./helm/static-site \
  -n xayn-prod \
  -f ./helm/static-site/values.prod.yaml
```

---

## Access the Applications

1. **Add host entries** to `/etc/hosts`:
   ```
   <MINIKUBE_IP> dev.xayn.local
   <MINIKUBE_IP> prod.xayn.local
   ```
2. **Browse**:
   - [https://dev.xayn.local](https://dev.xayn.local)  
   - [https://prod.xayn.local](https://prod.xayn.local)  

   > Accept the browser warning for the self-signed certificate.

3. **Or use curl**:
   ```bash
   curl -k https://dev.xayn.local
   curl -k https://prod.xayn.local
   ```

---

## Cleanup

```bash
# Delete Helm releases
helm uninstall xayn-dev -n xayn-dev
helm uninstall xayn-prod -n xayn-prod
helm uninstall traefik -n traefik

# Remove Minikube
minikube delete
```

---

## Optional: Terraform for Cloud Providers

See the `terraform/eks` and `terraform/gke` directories for IaC templates to provision AWS EKS and Google GKE clusters, including VPC, EKS/GKE, and Traefik installation.

---

## License

This project is provided under the MIT License. Feel free to use and adapt it to your needs.