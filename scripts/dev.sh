#!/bin/bash

# 로컬 개발 환경 설정 스크립트
set -e

echo "🛠️  Setting up local development environment..."

# Docker Compose로 로컬 환경 시작
echo "🐳 Starting local services with Docker Compose..."
docker-compose up -d

# 헬스 체크
echo "🏥 Performing health check..."
sleep 10

if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
    echo "✅ Application is healthy!"
    echo "🌐 Application is running at: http://localhost:3000"
    echo "📊 Health check endpoint: http://localhost:3000/api/health"
else
    echo "❌ Health check failed!"
    echo "📋 Container logs:"
    docker-compose logs nextjs-app
fi

echo "📝 Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Stop services: docker-compose down"
echo "  - Rebuild: docker-compose up --build"