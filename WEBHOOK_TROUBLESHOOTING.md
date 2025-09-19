# GitHub Webhook 문제 해결 가이드

## 🔍 Webhook 상태 진단

### 1. GitHub Repository에서 확인
```
Repository → Settings → Webhooks → 해당 Webhook 클릭
```

### 2. Recent Deliveries 확인
최근 push 후 다음 상태 중 어느 것인지 확인:

#### ✅ 성공 (200 OK)
```json
{
  "message": "Scheduled polling of jenkins-project"  
}
```
→ Webhook은 정상, Jenkins 설정 문제

#### ❌ 실패 (404 Not Found)
```json
{
  "message": "Not Found"
}
```
→ Jenkins URL 잘못됨

#### ❌ 실패 (Connection Timeout)
```json
{
  "message": "We couldn't deliver this payload"
}
```
→ Jenkins 서버 접근 불가

#### ❌ 실패 (500 Internal Server Error)
```json
{
  "message": "Internal server error"
}
```
→ Jenkins 서버 설정 오류

## 🚀 해결 방법

### Jenkins URL 문제인 경우
1. **로컬 개발 환경**: ngrok 사용
```bash
# ngrok 설치 (Windows)
choco install ngrok

# Jenkins 터널 생성
ngrok http 8080

# GitHub Webhook URL 업데이트
https://abc123.ngrok.io/github-webhook/
```

2. **서버 환경**: 공인 IP 사용
```bash
# Jenkins가 공인 IP로 접근 가능한지 확인
curl http://your-public-ip:8080/github-webhook/

# 방화벽 확인
netstat -an | findstr :8080
```

### Jenkins 설정 문제인 경우
1. **GitHub 플러그인 재설정**
```bash
Jenkins → Manage Jenkins → Configure System
GitHub → Advanced → Re-test connection
```

2. **Credentials 재확인**
```bash
Jenkins → Credentials → github-token 확인
Test connection으로 GitHub API 접근 테스트
```

### 네트워크 문제인 경우
1. **Jenkins 포트 개방**
```bash
# Windows 방화벽
netsh advfirewall firewall add rule name="Jenkins" dir=in action=allow protocol=TCP localport=8080

# 라우터 포트포워딩
8080 → Jenkins 서버 IP:8080
```

2. **Proxy 설정** (회사 환경)
```bash
Jenkins → Manage Jenkins → Configure System
HTTP Proxy Configuration 설정
```

## 🧪 테스트 방법

### 1. 수동 Webhook 테스트
```bash
# PowerShell에서 실행
$headers = @{
    "Content-Type" = "application/json"
    "X-GitHub-Event" = "push"
}

$body = @{
    "ref" = "refs/heads/main"
    "repository" = @{
        "name" = "my-app"
        "full_name" = "your-username/my-app"
    }
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://your-jenkins-ip:8080/github-webhook/" -Method POST -Headers $headers -Body $body
```

### 2. Jenkins 로그 실시간 모니터링
```bash
Jenkins → Manage Jenkins → System Log
"Add new log recorder" 클릭
Logger: com.cloudbees.jenkins.GitHubPushTrigger
Log level: ALL
```

### 3. GitHub Webhook 재설정
```bash
# 기존 Webhook 삭제 후 재생성
Webhook URL: http://your-jenkins-ip:8080/github-webhook/
Content type: application/json
Secret: (비워둠)
Events: Just the push event
Active: ✅
```

## 📋 체크리스트

배포 전 다음 사항들을 모두 확인하세요:

- [ ] Jenkins가 외부에서 접근 가능한 URL을 가지고 있음
- [ ] GitHub Webhook이 올바른 URL로 설정됨
- [ ] Jenkins에서 GitHub 플러그인이 활성화됨
- [ ] Personal Access Token이 올바른 권한을 가짐
- [ ] Jenkins 프로젝트에서 "GitHub hook trigger" 활성화
- [ ] 방화벽에서 Jenkins 포트(8080)가 열려있음
- [ ] Recent Deliveries에서 Webhook이 성공적으로 전달됨

## 💡 대안 방법

Webhook이 계속 작동하지 않는다면:

### 1. Poll SCM 사용
```
Build Triggers → Poll SCM
Schedule: H/5 * * * * (5분마다 확인)
```

### 2. GitHub Actions 사용
```yaml
# .github/workflows/trigger-jenkins.yml
name: Trigger Jenkins
on: [push]
jobs:
  trigger:
    runs-on: ubuntu-latest
    steps:
    - name: Trigger Jenkins Build
      run: |
        curl -X POST http://your-jenkins-ip:8080/job/your-project/build \
             --user admin:your-jenkins-token
```

### 3. 수동 빌드 트리거
```bash
# Jenkins REST API 사용
curl -X POST "http://your-jenkins-ip:8080/job/my-app/build" \
     --user "admin:your-api-token"
```