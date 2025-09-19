pipeline {
    agent any
    
    environment {
        // Docker Hub 또는 Private Registry 설정
        DOCKER_REGISTRY = 'jiyoon3421/my-app'
        DOCKER_REPO = 'my-app'
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'
        
        // Kubernetes 설정
        KUBECONFIG_CREDENTIALS_ID = 'kubernetes-config'
        NAMESPACE = 'my-app'
        
        // Git 설정
        GIT_COMMIT_SHORT = sh(
            script: "printf \$(git rev-parse --short HEAD)",
            returnStdout: true
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Building ${env.BRANCH_NAME} - ${env.GIT_COMMIT_SHORT}"
            }
        }
        
        stage('Install Dependencies') {
            steps {
                script {
                    sh 'npm ci'
                }
            }
        }
        
        stage('Code Quality Check') {
            parallel {
                stage('Lint') {
                    steps {
                        sh 'npm run lint'
                    }
                }
                stage('Type Check') {
                    steps {
                        sh 'npx tsc --noEmit'
                    }
                }
            }
        }
        
        stage('Build Application') {
            steps {
                sh 'npm run build'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    def imageName = "${DOCKER_REGISTRY}/${DOCKER_REPO}:${env.GIT_COMMIT_SHORT}"
                    def latestImage = "${DOCKER_REGISTRY}/${DOCKER_REPO}:latest"
                    
                    docker.build(imageName)
                    
                    // 최신 태그도 추가
                    sh "docker tag ${imageName} ${latestImage}"
                    
                    env.DOCKER_IMAGE = imageName
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                script {
                    // Trivy를 사용한 보안 스캔 (선택사항)
                    sh """
                        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \\
                        -v \$PWD/cache:/root/.cache/ \\
                        aquasec/trivy image ${env.DOCKER_IMAGE}
                    """
                }
            }
        }
        
        stage('Push Docker Image') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", DOCKER_CREDENTIALS_ID) {
                        sh "docker push ${env.DOCKER_IMAGE}"
                        sh "docker push ${DOCKER_REGISTRY}/${DOCKER_REPO}:latest"
                    }
                }
            }
        }
        
        stage('Deploy to Development') {
            when {
                branch 'develop'
            }
            steps {
                script {
                    deployToKubernetes('development')
                }
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                script {
                    // 프로덕션 배포 승인 요청
                    input message: 'Deploy to Production?', ok: 'Deploy'
                    deployToKubernetes('production')
                }
            }
        }
    }
    
    post {
        always {
            // 빌드 후 정리
            sh 'docker system prune -f'
            
            // 테스트 결과 보고 (테스트가 있는 경우)
            // publishHTML([
            //     allowMissing: false,
            //     alwaysLinkToLastBuild: false,
            //     keepAll: true,
            //     reportDir: 'coverage',
            //     reportFiles: 'index.html',
            //     reportName: 'Coverage Report'
            // ])
        }
        
        success {
            echo 'Pipeline succeeded!'
            // Slack 알림 (설정된 경우)
            // slackSend channel: '#deployments',
            //           color: 'good',
            //           message: "✅ ${env.JOB_NAME} - ${env.BUILD_NUMBER} succeeded"
        }
        
        failure {
            echo 'Pipeline failed!'
            // Slack 알림 (설정된 경우)
            // slackSend channel: '#deployments',
            //           color: 'danger',
            //           message: "❌ ${env.JOB_NAME} - ${env.BUILD_NUMBER} failed"
        }
    }
}

def deployToKubernetes(environment) {
    withCredentials([kubeconfigFile(credentialsId: KUBECONFIG_CREDENTIALS_ID, variable: 'KUBECONFIG')]) {
        sh """
            # 이미지 태그 업데이트
            sed -i 's|image: my-app:latest|image: ${env.DOCKER_IMAGE}|g' k8s/deployment.yaml
            
            # Kubernetes에 배포
            kubectl apply -f k8s/namespace.yaml
            kubectl apply -f k8s/configmap.yaml
            kubectl apply -f k8s/secret.yaml
            kubectl apply -f k8s/deployment.yaml
            kubectl apply -f k8s/service.yaml
            kubectl apply -f k8s/ingress.yaml
            kubectl apply -f k8s/hpa.yaml
            
            # 배포 상태 확인
            kubectl rollout status deployment/my-app-deployment -n ${NAMESPACE} --timeout=300s
            
            # 서비스 상태 확인
            kubectl get pods -n ${NAMESPACE}
            kubectl get svc -n ${NAMESPACE}
        """
    }
}