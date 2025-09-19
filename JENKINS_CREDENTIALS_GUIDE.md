# Jenkins Credentials 설정 가이드

## 필요한 Credentials 목록

Jenkins 관리 → Credentials → System → Global credentials에서 다음 항목들을 추가하세요:

### 1. GitHub 토큰
```
Kind: Secret text
Secret: ghp_xxxxxxxxxxxxxxxxxxxx (GitHub Personal Access Token)
ID: github-token
Description: GitHub Personal Access Token
```

### 2. Docker Registry 인증 (Harbor 또는 Docker Hub)
```
Kind: Username with password
Username: admin (Harbor) 또는 docker-username (Docker Hub)
Password: Harbor12345 또는 docker-password
ID: docker-registry-credentials
Description: Docker Registry Login
```

### 3. NCP 서버 SSH 키
```
Kind: SSH Username with private key
Username: ubuntu
Private Key: (NCP 서버 접속용 SSH 개인키 전체 내용)
ID: ncp-server-ssh
Description: NCP Server SSH Key
```

### 4. Slack 알림 (선택사항)
```
Kind: Secret text
Secret: xoxb-xxxxx-xxxxx-xxxxxxxx (Slack Bot Token)
ID: slack-token
Description: Slack Bot Token
```

## SSH 키 생성 방법 (Windows)

### PowerShell에서 실행:
```powershell
# SSH 키 생성
ssh-keygen -t rsa -b 4096 -f C:\Users\%USERNAME%\.ssh\jenkins-ncp -C "jenkins@ncp"

# 공개키를 NCP 서버에 복사
scp C:\Users\%USERNAME%\.ssh\jenkins-ncp.pub ubuntu@175.45.193.234:~/.ssh/authorized_keys

# 개인키 내용 확인 (Jenkins Credentials에 입력)
Get-Content C:\Users\%USERNAME%\.ssh\jenkins-ncp
```

## Docker Registry 설정

### Harbor 사용 시:
```
Registry URL: 175.45.193.234
Username: admin
Password: Harbor12345
```

### Docker Hub 사용 시:
```
Registry URL: docker.io (또는 비워둠)
Username: your-dockerhub-username
Password: your-dockerhub-password
```

## 설정 완료 확인

모든 Credentials가 올바르게 설정되었는지 확인하세요:

1. github-token: GitHub API 접근용
2. docker-registry-credentials: 이미지 푸시용
3. ncp-server-ssh: NCP 서버 배포용
4. slack-token: 알림용 (선택사항)

## 테스트 방법

### 1. GitHub 연동 테스트
```
Jenkins → 프로젝트 → Configure → Pipeline
"Poll SCM"에서 "H/5 * * * *" 입력하고 저장
코드 변경 후 GitHub에 push하여 자동 빌드 확인
```

### 2. Docker 빌드 테스트
```
Jenkins → 프로젝트 → Build Now
빌드 로그에서 "Docker 이미지 빌드 완료" 메시지 확인
```

### 3. 배포 테스트
```
main 브랜치에 코드 push
Jenkins에서 자동 빌드 및 배포 실행
http://175.45.193.234:3000 접속하여 배포 확인
```

## 문제 해결

### 일반적인 문제들:

1. **GitHub Webhook 오류**
   - Jenkins URL이 외부에서 접근 가능한지 확인
   - 방화벽에서 Jenkins 포트(8080) 열려있는지 확인

2. **Docker 빌드 오류**
   - Jenkins에서 Docker 데몬에 접근 가능한지 확인
   - Jenkins 사용자가 docker 그룹에 속해있는지 확인

3. **SSH 배포 오류**
   - SSH 키가 올바르게 설정되었는지 확인
   - NCP 서버에서 SSH 접속이 허용되는지 확인

4. **Windows 환경 오류**
   - Git이 PATH에 포함되어 있는지 확인
   - Jenkins에서 Git 경로가 올바르게 설정되었는지 확인