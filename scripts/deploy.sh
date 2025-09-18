#!/bin/bash

# 배포 스크립트
set -e

echo "🚀 Starting deployment process..."

# 환경 변수 설정
DOCKER_REGISTRY="${DOCKER_REGISTRY:-localhost:5000}"
APP_NAME="${APP_NAME:-my-app}"
NAMESPACE="${NAMESPACE:-my-app}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

# Docker 이미지 빌드
echo "📦 Building Docker image..."
docker build -t $DOCKER_REGISTRY/$APP_NAME:$IMAGE_TAG .

# Docker 이미지 푸시
echo "📤 Pushing Docker image..."
docker push $DOCKER_REGISTRY/$APP_NAME:$IMAGE_TAG

# Kubernetes 배포
echo "🎯 Deploying to Kubernetes..."

# 이미지 태그 업데이트
sed -i "s|image: my-app:latest|image: $DOCKER_REGISTRY/$APP_NAME:$IMAGE_TAG|g" k8s/deployment.yaml

# Kubernetes 리소스 적용
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml

# 배포 상태 확인
echo "⏳ Waiting for deployment to complete..."
kubectl rollout status deployment/$APP_NAME-deployment -n $NAMESPACE --timeout=300s

# 서비스 상태 확인
echo "✅ Deployment completed successfully!"
echo "📊 Current status:"
kubectl get pods -n $NAMESPACE
kubectl get svc -n $NAMESPACE

echo "🌐 Access your application at:"
kubectl get ingress -n $NAMESPACE