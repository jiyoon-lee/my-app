#!/bin/bash
# NCP 서버에서 실행할 배포 스크립트
# 파일 위치: /opt/my-app/deploy.sh

set -e

echo "🚀 My App 배포 시작..."

# 변수 설정
APP_NAME="my-app"
APP_PORT="3000"
DOCKER_IMAGE="my-app:latest"
BACKUP_DIR="/opt/backups"
DEPLOY_DIR="/opt/my-app"

# 백업 디렉토리 생성
mkdir -p $BACKUP_DIR

# 현재 실행 중인 컨테이너 백업
if docker ps | grep -q $APP_NAME; then
    echo "📦 현재 컨테이너 백업 중..."
    docker commit $APP_NAME $APP_NAME:backup-$(date +%Y%m%d_%H%M%S)
fi

# 기존 컨테이너 중지 및 제거
echo "🛑 기존 컨테이너 중지 중..."
docker stop $APP_NAME || true
docker rm $APP_NAME || true

# 새 컨테이너 실행
echo "🏃 새 컨테이너 실행 중..."
docker run -d \
    --name $APP_NAME \
    --restart unless-stopped \
    -p $APP_PORT:3000 \
    -e NODE_ENV=production \
    -e PORT=3000 \
    -v /opt/my-app/logs:/app/logs \
    $DOCKER_IMAGE

# 컨테이너 시작 대기
echo "⏳ 컨테이너 시작 대기 중..."
sleep 10

# 헬스 체크
echo "🏥 헬스 체크 실행 중..."
for i in {1..30}; do
    if curl -f http://localhost:$APP_PORT/api/health > /dev/null 2>&1; then
        echo "✅ 헬스 체크 성공!"
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "❌ 헬스 체크 실패! 배포 롤백 중..."
        docker stop $APP_NAME
        docker rm $APP_NAME
        
        # 백업에서 복원
        BACKUP_IMAGE=$(docker images --format "table {{.Repository}}:{{.Tag}}" | grep backup | head -1)
        if [ ! -z "$BACKUP_IMAGE" ]; then
            docker run -d --name $APP_NAME --restart unless-stopped -p $APP_PORT:3000 $BACKUP_IMAGE
        fi
        exit 1
    fi
    
    echo "헬스 체크 재시도 중... ($i/30)"
    sleep 2
done

# 이전 이미지 정리 (백업 제외)
echo "🧹 이전 이미지 정리 중..."
docker image prune -f

# 백업 이미지 정리 (최근 3개만 유지)
echo "🗂️ 백업 정리 중..."
docker images --format "table {{.Repository}}:{{.Tag}}" | grep backup | tail -n +4 | while read image; do
    docker rmi $image || true
done

# 로그 확인
echo "📝 최근 로그:"
docker logs --tail 20 $APP_NAME

echo "🎉 배포 완료!"
echo "🌐 애플리케이션 URL: http://175.45.193.234"
echo "🔗 헬스 체크 URL: http://175.45.193.234/health"