# GitHub Credentials 설정 완벽 가이드

## 🔑 확실한 GitHub Credential 설정 방법

### 방법 1: Username with Password (권장)

#### 1단계: GitHub Personal Access Token 생성
```
GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
→ Generate new token (classic)

Token name: Jenkins CI/CD
Expiration: 90 days (또는 No expiration)

Select scopes:
✅ repo (전체)
✅ workflow  
✅ admin:repo_hook (전체)
✅ read:user
✅ user:email

Generate token → 토큰 복사 (다시 볼 수 없음!)
```

#### 2단계: Jenkins Credential 생성
```
Jenkins → Manage Jenkins → Credentials → System → Global credentials → Add Credentials

Kind: Username with password
Scope: Global (Jenkins, nodes, items, all child items, etc)
Username: your-github-username (예: jiyoon)
Password: ghp_xxxxxxxxxxxxxxxxxxxx (위에서 생성한 토큰)
ID: github-token
Description: GitHub Personal Access Token
```

#### 3단계: Pipeline에서 사용
```
Repository URL: https://github.com/your-username/my-app.git
Credentials: github-token
Branch: */main
```

### 방법 2: SSH Key (더 안전함)

#### 1단계: SSH 키 생성 (Windows PowerShell)
```powershell
# SSH 키 생성
ssh-keygen -t ed25519 -C "jenkins@your-email.com" -f $env:USERPROFILE\.ssh\github-jenkins

# 공개키 내용 확인
Get-Content $env:USERPROFILE\.ssh\github-jenkins.pub

# 개인키 내용 확인 (Jenkins에서 사용)
Get-Content $env:USERPROFILE\.ssh\github-jenkins
```

#### 2단계: GitHub에 공개키 등록
```
GitHub → Settings → SSH and GPG keys → New SSH key

Title: Jenkins CI/CD Key
Key type: Authentication Key
Key: (ssh-ed25519로 시작하는 공개키 내용 전체 붙여넣기)
```

#### 3단계: Jenkins SSH Credential 생성
```
Jenkins → Manage Jenkins → Credentials → System → Global credentials → Add Credentials

Kind: SSH Username with private key
Scope: Global (Jenkins, nodes, items, all child items, etc)
ID: github-ssh
Description: GitHub SSH Key
Username: git
Private Key: Enter directly
Key: (-----BEGIN OPENSSH PRIVATE KEY-----로 시작하는 개인키 전체 내용)
Passphrase: (키 생성시 설정한 경우만)
```

#### 4단계: Pipeline에서 SSH 사용
```
Repository URL: git@github.com:your-username/my-app.git
Credentials: github-ssh
Branch: */main
```

## 🔍 문제 해결

### Credential이 선택 목록에 나타나지 않는 경우

#### 원인 1: 잘못된 Kind 선택
```
❌ Secret text → SCM에서 사용 불가
✅ Username with password → SCM에서 사용 가능
✅ SSH Username with private key → SCM에서 사용 가능
```

#### 원인 2: 잘못된 Scope
```
❌ System scope → Pipeline에서 접근 불가
✅ Global scope → 모든 곳에서 사용 가능
```

#### 원인 3: Jenkins 캐시 문제
```bash
# 해결책: Jenkins 재시작 또는 설정 새로고침
Jenkins → Manage Jenkins → Reload Configuration from Disk
```

### Connection Test 방법

#### HTTPS 연결 테스트
```bash
# PowerShell에서 테스트
$headers = @{
    "Authorization" = "token your-github-token"
}
Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers
```

#### SSH 연결 테스트  
```bash
# Git Bash에서 테스트
ssh -T git@github.com -i ~/.ssh/github-jenkins
```

## 📋 체크리스트

설정 완료 후 다음을 확인하세요:

- [ ] GitHub Personal Access Token 생성 (올바른 권한)
- [ ] Jenkins Credential 생성 (Global scope, 올바른 Kind)
- [ ] Repository URL 형식 확인 (HTTPS 또는 SSH)
- [ ] Branch 이름 확인 (main 또는 master)
- [ ] Connection 테스트 성공
- [ ] Pipeline 설정에서 Credential 선택 가능

## 🚀 테스트 명령어

### Jenkins Pipeline에서 Git 연결 테스트
```groovy
pipeline {
    agent any
    stages {
        stage('Test Git Connection') {
            steps {
                checkout scm
                echo "Git connection successful!"
            }
        }
    }
}
```

### GitHub API 접근 테스트
```bash
# Jenkins Console에서 실행
curl -H "Authorization: token your-token" https://api.github.com/user
```

이 가이드를 따라하시면 GitHub Credentials 문제가 해결될 것입니다!