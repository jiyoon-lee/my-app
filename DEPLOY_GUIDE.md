# NCP 서버 자동 배포 설정 가이드

## 🎯 완료된 구성
- **서버 IP**: 175.45.193.234
- **배포 방식**: GitHub Actions → SSH → Docker
- **접근 URL**: http://175.45.193.234

## 📋 설정 단계

### 1단계: NCP 서버 초기 설정

```bash
# 서버에 SSH 접속
ssh ubuntu@175.45.193.234

# 초기 설정 스크립트 실행
curl -sSL https://raw.githubusercontent.com/your-username/my-app/main/scripts/setup-ncp-server.sh | bash

# 재부팅
sudo reboot
```

### 2단계: SSH 키 생성 및 설정

```bash
# 로컬에서 SSH 키 생성
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ncp-deploy-key -C "github-actions"

# 공개키를 서버에 복사
ssh-copy-id -i ~/.ssh/ncp-deploy-key.pub ubuntu@175.45.193.234

# 개인키 내용 복사 (GitHub Secrets에 사용)
cat ~/.ssh/ncp-deploy-key
```

### 3단계: GitHub Secrets 설정

GitHub Repository → Settings → Secrets and variables → Actions

다음 Secrets 추가:
```
NCP_SERVER_HOST = 175.45.193.234
NCP_SERVER_USER = ubuntu
NCP_SERVER_KEY = (위에서 생성한 개인키 전체 내용)
```

### 4단계: Nginx 설정

```bash
# 서버에서 실행
sudo cp /opt/my-app/nginx/my-app.conf /etc/nginx/sites-available/my-app
sudo ln -s /etc/nginx/sites-available/my-app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 5단계: 방화벽 설정 (NCP 콘솔)

**NCP 콘솔 → Compute → Server → ACG 설정**

Inbound 규칙 추가:
```
1. HTTP: TCP 80 0.0.0.0/0
2. HTTPS: TCP 443 0.0.0.0/0  
3. Custom: TCP 3000 0.0.0.0/0 (개발용)
4. SSH: TCP 22 your-ip/32 (보안을 위해 본인 IP만)
```

## 🚀 배포 테스트

### 수동 배포 테스트
```bash
# 로컬에서 실행
git add .
git commit -m "feat: 배포 테스트"
git push origin main
```

### 배포 확인
1. **GitHub Actions 확인**: Repository → Actions 탭
2. **서버 접속 확인**: http://175.45.193.234
3. **헬스 체크**: http://175.45.193.234/health

## 📊 모니터링 명령어

### 서버에서 실행할 명령어:
```bash
# 컨테이너 상태 확인
docker ps

# 애플리케이션 로그 확인
docker logs my-app -f

# 리소스 사용량 확인
docker stats my-app

# Nginx 로그 확인
sudo tail -f /var/log/nginx/my-app.access.log
sudo tail -f /var/log/nginx/my-app.error.log

# 시스템 리소스 확인
htop
df -h
```

## 🔧 문제 해결

### 일반적인 문제들:

#### 1. 배포 실패 시
```bash
# 컨테이너 로그 확인
docker logs my-app

# 수동으로 다시 시작
sudo /opt/my-app/deploy.sh
```

#### 2. 포트 접근 불가 시
```bash
# 방화벽 상태 확인
sudo ufw status

# 포트 열기
sudo ufw allow 80/tcp
sudo ufw allow 3000/tcp
```

#### 3. Nginx 오류 시
```bash
# Nginx 설정 테스트
sudo nginx -t

# Nginx 재시작
sudo systemctl restart nginx
```

## 📈 성능 최적화

### 1. Docker 이미지 최적화
- Multi-stage build 사용 ✅
- 불필요한 파일 제외 ✅
- 레이어 캐싱 최적화 ✅

### 2. 서버 최적화
```bash
# PM2로 프로세스 관리 (선택사항)
pm2 start ecosystem.config.js
pm2 startup
pm2 save
```

### 3. 캐싱 설정
- Nginx에서 정적 파일 캐싱 ✅
- CDN 설정 (선택사항)

## 🔒 보안 고려사항

1. **SSH 키 관리**: 정기적으로 키 로테이션
2. **방화벽**: 필요한 포트만 열기
3. **SSL**: Let's Encrypt로 HTTPS 설정 (선택사항)
4. **업데이트**: 정기적인 보안 업데이트

## 🎉 완료!

이제 main 브랜치에 merge될 때마다 자동으로 NCP 서버에 배포됩니다!

**접속 URL**: http://175.45.193.234
**관리 URL**: http://175.45.193.234/health