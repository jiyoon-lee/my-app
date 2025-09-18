# NCP 서버 초기 설정 스크립트

#!/bin/bash
# 서버 IP: 175.45.193.234
# 이 스크립트를 NCP 서버에서 실행하세요

echo "🚀 NCP 서버 초기 설정 시작..."

# 1. 시스템 업데이트
sudo apt update && sudo apt upgrade -y

# 2. 필수 패키지 설치
sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    nginx

# 3. Docker 설치
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 4. Docker 그룹에 사용자 추가
sudo usermod -aG docker $USER

# 5. Node.js 18 설치 (LTS)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 6. PM2 설치 (프로세스 매니저)
sudo npm install -g pm2

# 7. Docker 서비스 시작
sudo systemctl enable docker
sudo systemctl start docker

# 8. 방화벽 설정
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3000/tcp
sudo ufw --force enable

# 9. 배포 디렉토리 생성
sudo mkdir -p /opt/my-app
sudo chown $USER:$USER /opt/my-app

# 10. GitHub Actions용 사용자 생성 (선택사항)
sudo useradd -m -s /bin/bash github-actions
sudo usermod -aG docker github-actions

echo "✅ 서버 초기 설정 완료!"
echo "🔄 재부팅 후 Docker가 정상 작동합니다."
echo "sudo reboot"