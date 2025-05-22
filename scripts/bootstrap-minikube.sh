#!/bin/bash
set -e  # bail on errors

# fire up minikube
minikube start --vm-driver=docker

# point docker to minikube 
eval $(minikube docker-env)

# build our image
docker build -t xayn/static-site:latest ./static-site

# setup traefik for ingress
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik \
  --namespace traefik --create-namespace \
  --set service.type=NodePort \
  --set service.nodePorts.https=30443

# create envs (ignore errors if they exist)
kubectl create namespace xayn-dev || true
kubectl create namespace xayn-prod || true

# dev certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -subj "/CN=dev.xayn.local" \
  -keyout dev.key -out dev.crt
kubectl create secret tls dev-tls-cert \
  --key dev.key --cert dev.crt \
  -n xayn-dev

# prod certs - same process different domain
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -subj "/CN=prod.xayn.local" \
  -keyout prod.key -out prod.crt
kubectl create secret tls prod-tls-cert \
  --key prod.key --cert prod.crt \
  -n xayn-prod

# deploy everything wheater it is DEV OR PRod
helm install xayn-dev ./helm/static-site \
  -n xayn-dev \
  -f ./helm/static-site/values.dev.yaml

helm install xayn-prod ./helm/static-site \
  -n xayn-prod \
  -f ./helm/static-site/values.prod.yaml

# get the IP for hosts file
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# remind about hosts entries
echo "Add these to /etc/hosts:"
echo "$MINIKUBE_IP dev.xayn.local"
echo "$MINIKUBE_IP prod.xayn.local"