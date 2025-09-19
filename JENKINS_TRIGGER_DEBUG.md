# Jenkins GitHub 트리거 문제 해결 가이드

## 🔧 Jenkins 프로젝트 설정 체크리스트

### 1. Build Triggers 설정 (가장 중요!)

Jenkins → 프로젝트 → Configure → Build Triggers

**올바른 설정:**
```
☑️ GitHub hook trigger for GITScm polling
```

**주의사항:**
- 정확히 "GitHub hook trigger for GITScm polling" 이어야 함
- "Poll SCM"과 다른 옵션임
- 다른 trigger와 함께 선택 가능

### 2. Source Code Management 설정

**Git 설정:**
```
Repository URL: https://github.com/your-username/my-app.git
Credentials: github-token
Branches to build: */main (정확한 브랜치명)
Repository browser: (Auto)
```

**추가 설정 (Advanced 클릭):**
```
Name: origin
Refspec: +refs/heads/*:refs/remotes/origin/*
```

### 3. Pipeline 설정

**정확한 설정:**
```
Definition: Pipeline script from SCM
SCM: Git
Repository URL: https://github.com/your-username/my-app.git (동일한 URL)
Credentials: github-token (동일한 credential)
Branch Specifier: */main
Script Path: Jenkinsfile
Lightweight checkout: ☑️ (체크 권장)
```

## 🔍 고급 트러블슈팅

### Jenkins GitHub 플러그인 설정 확인

#### 1. GitHub 플러그인 활성화 확인
```bash
Jenkins → Manage Jenkins → Plugin Manager → Installed
다음 플러그인들이 활성화되어 있는지 확인:
- GitHub Integration Plugin
- GitHub Branch Source Plugin
- Pipeline: GitHub Groovy Libraries
- Git plugin
```

#### 2. GitHub 서버 설정
```bash
Jenkins → Manage Jenkins → Configure System → GitHub

GitHub Server 설정:
- Name: GitHub
- API URL: https://api.github.com
- Credentials: github-token
- Manage hooks: ☑️
- Test connection 성공 확인
```

### Jenkins 내부 URL 설정 확인

#### Jenkins URL 설정
```bash
Jenkins → Manage Jenkins → Configure System → Jenkins Location

Jenkins URL: http://your-jenkins-ip:8080/ (정확한 URL)
```

**중요**: 이 URL이 GitHub Webhook에서 접근 가능해야 함

## 🧪 디버깅 방법

### 1. Webhook 페이로드 확인

GitHub → Repository → Settings → Webhooks → Recent Deliveries에서:

**성공적인 응답 예시:**
```json
{
  "jobs": {
    "your-project-name": {
      "triggered": true,
      "url": "queue/item/123/"
    }
  }
}
```

**실패 응답 예시:**
```json
{
  "message": "No Git consumers using SCM API plugin could be found"
}
```

### 2. Jenkins Queue 확인

#### Build Queue 확인:
```bash
Jenkins → Build Queue

GitHub push 후 여기에 대기 중인 빌드가 있는지 확인
```

#### Build Executor Status 확인:
```bash
Jenkins → Build Executor Status

실행 중인 빌드가 있는지 확인
```

### 3. 수동 테스트 명령어

#### PowerShell에서 Webhook 수동 테스트:
```powershell
$body = @{
    "ref" = "refs/heads/main"
    "repository" = @{
        "name" = "my-app"
        "full_name" = "your-username/my-app"
        "clone_url" = "https://github.com/your-username/my-app.git"
    }
    "pusher" = @{
        "name" = "your-username"
    }
} | ConvertTo-Json -Depth 3

$headers = @{
    "Content-Type" = "application/json"
    "X-GitHub-Event" = "push"
    "User-Agent" = "GitHub-Hookshot/test"
}

# Jenkins Webhook 엔드포인트로 직접 POST 요청
Invoke-RestMethod -Uri "http://your-jenkins-ip:8080/github-webhook/" -Method POST -Body $body -Headers $headers
```

## 🚀 확실한 해결 방법들

### 방법 1: Generic Webhook Trigger 사용

#### Generic Webhook Trigger 플러그인 설치:
```bash
Jenkins → Plugin Manager → Available → "Generic Webhook Trigger" 검색 및 설치
```

#### 프로젝트 설정 변경:
```bash
Build Triggers → Generic Webhook Trigger

Token: my-app-webhook-token

Post content parameters:
- Variable: ref
- Expression: $.ref
- JSONPath: $.ref
```

#### GitHub Webhook URL 변경:
```
http://your-jenkins-ip:8080/generic-webhook-trigger/invoke?token=my-app-webhook-token
```

### 방법 2: GitHub Branch Source 사용

#### 새 프로젝트 생성:
```bash
Jenkins → New Item → Multibranch Pipeline

Branch Sources → Add source → GitHub

Repository HTTPS URL: https://github.com/your-username/my-app
Credentials: github-token

Build Configuration:
- Mode: by Jenkinsfile
- Script Path: Jenkinsfile
```

### 방법 3: Poll SCM 백업 설정

#### 임시 해결책:
```bash
Build Triggers → Poll SCM
Schedule: H/5 * * * * (5분마다 폴링)

이렇게 설정하면 Webhook 실패 시에도 자동 빌드 가능
```

## 📋 단계별 점검 체크리스트

다음 순서대로 확인하고 체크해보세요:

1. **[ ] Jenkins 로그 설정 완료**
2. **[ ] GitHub에서 코드 push 실행**
3. **[ ] Jenkins 로그에서 GitHub 이벤트 수신 확인**
4. **[ ] Build Queue에 대기 중인 작업 확인**
5. **[ ] "GitHub hook trigger for GITScm polling" 설정 확인**
6. **[ ] Repository URL과 Branch 이름 정확성 확인**
7. **[ ] Jenkins URL이 외부 접근 가능한지 확인**
8. **[ ] GitHub Webhook Response가 성공적인지 확인**

## 🎯 최종 확인 방법

### 단계별 테스트:
1. **수동 빌드**: "Build Now"가 성공하는지 확인
2. **Poll SCM**: 임시로 설정하여 자동 빌드 확인
3. **Webhook 로그**: Jenkins에서 GitHub 이벤트 수신 로그 확인
4. **최종 테스트**: 모든 설정 완료 후 GitHub push 테스트