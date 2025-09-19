pipeline {
    agent any
    
    environment {
        // 환경 변수 설정
        DOCKER_REGISTRY = '175.45.193.234'  // Harbor 또는 본인의 Registry
        DOCKER_REPO = 'my-app'
        DOCKER_IMAGE = "${DOCKER_REGISTRY}/${DOCKER_REPO}/nextjs-app"
        
        // NCP 서버 정보
        NCP_SERVER = '175.45.193.234'
        NCP_USER = 'ubuntu'
    }
    
    stages {
        stage('Initialize') {
            steps {
                script {
                    // Windows에서 Git 커밋 해시 가져오기
                    if (isUnix()) {
                        env.GIT_COMMIT_SHORT = sh(
                            script: "git rev-parse --short HEAD",
                            returnStdout: true
                        ).trim()
                    } else {
                        // Windows용 - PowerShell 사용
                        env.GIT_COMMIT_SHORT = powershell(
                            script: "git rev-parse --short HEAD",
                            returnStdout: true
                        ).trim()
                    }
                }
                echo "🚀 빌드 시작: ${env.BRANCH_NAME} - ${env.GIT_COMMIT_SHORT}"
            }
        }
        
        stage('Checkout') {
            steps {
                checkout scm
                echo "✅ 소스코드 체크아웃 완료"
            }
        }
        
        stage('Install Dependencies') {
            steps {
                script {
                    echo "📦 의존성 설치 중..."
                    if (isUnix()) {
                        sh 'npm ci'
                    } else {
                        // Windows용 - PowerShell 사용
                        powershell 'npm ci'
                    }
                }
                echo "✅ 의존성 설치 완료"
            }
        }
        
        stage('Code Quality') {
            parallel {
                stage('Lint Check') {
                    steps {
                        script {
                            echo "🔍 린트 검사 중..."
                            if (isUnix()) {
                                sh 'npm run lint'
                            } else {
                                powershell 'npm run lint'
                            }
                        }
                    }
                }
                stage('Type Check') {
                    steps {
                        script {
                            echo "📝 타입 검사 중..."
                            if (isUnix()) {
                                sh 'npx tsc --noEmit'
                            } else {
                                powershell 'npx tsc --noEmit'
                            }
                        }
                    }
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    echo "🏗️ 애플리케이션 빌드 중..."
                    if (isUnix()) {
                        sh 'npm run build'
                    } else {
                        powershell 'npm run build'
                    }
                }
                echo "✅ 빌드 완료"
            }
        }
        
        stage('Docker Build') {
            steps {
                script {
                    def imageTag = "${env.DOCKER_IMAGE}:${env.GIT_COMMIT_SHORT}"
                    def latestTag = "${env.DOCKER_IMAGE}:latest"
                    
                    echo "🐳 Docker 이미지 빌드 중..."
                    if (isUnix()) {
                        sh """
                            docker build -t ${imageTag} .
                            docker tag ${imageTag} ${latestTag}
                        """
                    } else {
                        powershell """
                            docker build -t ${imageTag} .
                            docker tag ${imageTag} ${latestTag}
                        """
                    }
                    
                    env.DOCKER_IMAGE_TAG = imageTag
                    env.DOCKER_IMAGE_LATEST = latestTag
                }
                echo "✅ Docker 이미지 빌드 완료"
            }
        }
        
        stage('Push to Registry') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                    branch 'master'
                }
            }
            steps {
                script {
                    echo "📤 Docker 이미지 푸시 중..."
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-registry-credentials',
                        usernameVariable: 'REGISTRY_USER',
                        passwordVariable: 'REGISTRY_PASS'
                    )]) {
                        if (isUnix()) {
                            sh '''
                                echo $REGISTRY_PASS | docker login $DOCKER_REGISTRY -u $REGISTRY_USER --password-stdin
                                docker push $DOCKER_IMAGE_TAG
                                docker push $DOCKER_IMAGE_LATEST
                            '''
                        } else {
                            powershell '''
                                echo $env:REGISTRY_PASS | docker login $env:DOCKER_REGISTRY -u $env:REGISTRY_USER --password-stdin
                                docker push $env:DOCKER_IMAGE_TAG
                                docker push $env:DOCKER_IMAGE_LATEST
                            '''
                        }
                    }
                }
                echo "✅ 이미지 푸시 완료"
            }
        }
        
        stage('Deploy to Production') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                }
            }
            steps {
                script {
                    echo "🚀 NCP 서버에 배포 중..."
                    
                    // SSH로 NCP 서버에 배포
                    sshagent(credentials: ['ncp-server-ssh']) {
                        if (isUnix()) {
                            sh '''
                                ssh -o StrictHostKeyChecking=no $NCP_USER@$NCP_SERVER "
                                    echo '배포 시작...'
                                    
                                    # Registry 로그인
                                    docker login $DOCKER_REGISTRY
                                    
                                    # 최신 이미지 가져오기
                                    docker pull $DOCKER_IMAGE_LATEST
                                    
                                    # 기존 컨테이너 중지 및 제거
                                    docker stop my-nextjs-app || true
                                    docker rm my-nextjs-app || true
                                    
                                    # 새 컨테이너 실행
                                    docker run -d \\
                                        --name my-nextjs-app \\
                                        --restart unless-stopped \\
                                        -p 3000:3000 \\
                                        -e NODE_ENV=production \\
                                        $DOCKER_IMAGE_LATEST
                                    
                                    # 헬스 체크
                                    sleep 15
                                    curl -f http://localhost:3000/api/health || curl -f http://localhost:3000 || echo 'Health check failed'
                                    
                                    # 컨테이너 상태 확인
                                    docker ps | grep my-nextjs-app
                                    
                                    # 이전 이미지 정리
                                    docker image prune -f
                                    
                                    echo '배포 완료!'
                                "
                            '''
                        } else {
                            // Windows에서 SSH 명령어 실행
                            powershell '''
                                ssh -o StrictHostKeyChecking=no $env:NCP_USER@$env:NCP_SERVER @"
                                docker pull $env:DOCKER_IMAGE_LATEST
                                docker stop my-nextjs-app 2>null; docker rm my-nextjs-app 2>null
                                docker run -d --name my-nextjs-app --restart unless-stopped -p 3000:3000 -e NODE_ENV=production $env:DOCKER_IMAGE_LATEST
                                sleep 10
                                curl -f http://localhost:3000 || echo 'App starting...'
                                docker image prune -f
                                echo 'Deploy completed!'
"@
                            '''
                        }
                    }
                }
                echo "✅ 배포 완료!"
            }
        }
    }
    
    post {
        always {
            script {
                echo "🧹 정리 작업 중..."
                if (isUnix()) {
                    sh 'docker system prune -f || true'
                } else {
                    powershell 'try { docker system prune -f } catch { Write-Host "정리 완료" }'
                }
            }
        }
        
        success {
            echo """
            🎉 파이프라인 성공!
            📋 빌드 정보:
              - 브랜치: ${env.BRANCH_NAME}
              - 커밋: ${env.GIT_COMMIT_SHORT}
              - 이미지: ${env.DOCKER_IMAGE_LATEST}
              - 서버: http://${env.NCP_SERVER}
            """
        }
        
        failure {
            echo "❌ 파이프라인 실패! 로그를 확인하세요."
        }
        
        unstable {
            echo "⚠️ 파이프라인 불안정!"
        }
    }
}