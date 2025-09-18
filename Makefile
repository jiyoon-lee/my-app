# Makefile for Docker + Kubernetes + Jenkins CI/CD

# 기본 변수
DOCKER_REGISTRY ?= localhost:5000
APP_NAME ?= my-app
NAMESPACE ?= my-app
IMAGE_TAG ?= latest
FULL_IMAGE_NAME = $(DOCKER_REGISTRY)/$(APP_NAME):$(IMAGE_TAG)

.PHONY: help build push deploy clean logs status

# 도움말
help:
	@echo "사용 가능한 명령어:"
	@echo "  build       - Docker 이미지 빌드"
	@echo "  push        - Docker 이미지 푸시"
	@echo "  deploy      - Kubernetes에 배포"
	@echo "  clean       - 리소스 정리"
	@echo "  logs        - 애플리케이션 로그 확인"
	@echo "  status      - 배포 상태 확인"
	@echo "  dev         - 로컬 개발 환경 실행"
	@echo "  test        - 테스트 실행"

# Docker 이미지 빌드
build:
	@echo "🔨 Building Docker image..."
	docker build -t $(FULL_IMAGE_NAME) .
	docker tag $(FULL_IMAGE_NAME) $(DOCKER_REGISTRY)/$(APP_NAME):latest

# Docker 이미지 푸시
push: build
	@echo "📤 Pushing Docker image..."
	docker push $(FULL_IMAGE_NAME)
	docker push $(DOCKER_REGISTRY)/$(APP_NAME):latest

# Kubernetes 배포
deploy:
	@echo "🚀 Deploying to Kubernetes..."
	@sed 's|image: my-app:latest|image: $(FULL_IMAGE_NAME)|g' k8s/deployment.yaml | kubectl apply -f -
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/configmap.yaml
	kubectl apply -f k8s/secret.yaml
	kubectl apply -f k8s/service.yaml
	kubectl apply -f k8s/ingress.yaml
	kubectl apply -f k8s/hpa.yaml
	@echo "⏳ Waiting for deployment..."
	kubectl rollout status deployment/$(APP_NAME)-deployment -n $(NAMESPACE) --timeout=300s

# 리소스 정리
clean:
	@echo "🧹 Cleaning up resources..."
	kubectl delete namespace $(NAMESPACE) --ignore-not-found=true
	docker rmi $(FULL_IMAGE_NAME) --force || true
	docker rmi $(DOCKER_REGISTRY)/$(APP_NAME):latest --force || true

# 로그 확인
logs:
	@echo "📋 Fetching application logs..."
	kubectl logs -f -l app=$(APP_NAME) -n $(NAMESPACE)

# 상태 확인
status:
	@echo "📊 Checking deployment status..."
	kubectl get all -n $(NAMESPACE)
	@echo ""
	@echo "🏥 Health check:"
	kubectl get pods -n $(NAMESPACE) -o wide

# 로컬 개발 환경
dev:
	@echo "🛠️ Starting local development environment..."
	docker-compose up --build

# 테스트 실행
test:
	@echo "🧪 Running tests..."
	npm run lint
	npm run build
	@echo "✅ All tests passed!"

# 전체 배포 파이프라인
all: test build push deploy status

# Jenkins 서버 시작
jenkins:
	@echo "🔧 Starting Jenkins server..."
	cd jenkins && docker-compose -f docker-compose.jenkins.yml up -d
	@echo "Jenkins is starting at http://localhost:8080"
	@echo "Initial admin password:"
	@sleep 10
	@docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "Jenkins is still starting..."