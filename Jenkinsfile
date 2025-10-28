pipeline {
    agent any
    
    environment {
        AWS_REGION = 'eu-west-3'
        EKS_CLUSTER = 'garden-web-app-cluster'
        ECR_REGISTRY = '964711978492.dkr.ecr.eu-west-3.amazonaws.com'
        APP_NAME = 'garden-web-app'
        DOCKER_IMAGE_TAG = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}-${env.GIT_COMMIT.substring(0,7)}"
    }
    
    options {
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    
    stages {
        // Stage 1: Checkout Code
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        // Stage 2: SonarQube Quality Check
        stage('SonarQube Analysis') {
            steps {
                script {
                    // Install dependencies if needed (for Java/Node.js projects)
                    // sh 'npm install'  // Uncomment for Node.js
                    // sh 'mvn clean compile'  // Uncomment for Java
                    
                    withSonarQubeEnv('sonarqube-server') {
                        sh """
                            sonar-scanner \
                            -Dsonar.projectKey=${APP_NAME}-${env.BRANCH_NAME} \
                            -Dsonar.projectName=${APP_NAME}-${env.BRANCH_NAME} \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=\${SONAR_HOST_URL} \
                            -Dsonar.login=\${SONAR_AUTH_TOKEN}
                        """
                    }
                }
            }
        }
        
        // Stage 3: Quality Gate Check
        stage('Quality Gate') {
            steps {
                script {
                    timeout(time: 5, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }
        
        // Stage 4: Build Docker Image
        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        docker build -t ${APP_NAME}:${DOCKER_IMAGE_TAG} .
                        docker tag ${APP_NAME}:${DOCKER_IMAGE_TAG} ${ECR_REGISTRY}/${APP_NAME}:${DOCKER_IMAGE_TAG}
                    """
                }
            }
        }
        
        // Stage 5: Trivy Security Scan
        stage('Trivy Security Scan') {
            steps {
                script {
                    sh """
                        # Install trivy if not exists
                        if ! command -v trivy &> /dev/null; then
                            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
                        fi
                        
                        # Scan the Docker image
                        trivy image --exit-code 1 --severity HIGH,CRITICAL ${APP_NAME}:${DOCKER_IMAGE_TAG}
                        
                        # Generate report (optional)
                        trivy image --format template --template "@/usr/local/share/trivy/templates/html.tpl" -o trivy-report.html ${APP_NAME}:${DOCKER_IMAGE_TAG}
                    """
                }
            }
            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'trivy-report.html',
                        reportName: 'Trivy Security Report'
                    ])
                }
            }
        }
        
        // Stage 6: Push to ECR
        stage('Push to ECR') {
            steps {
                script {
                    sh """
                        # Login to ECR
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        
                        # Push image to ECR
                        docker push ${ECR_REGISTRY}/${APP_NAME}:${DOCKER_IMAGE_TAG}
                    """
                }
            }
        }
        
        // Stage 7: Deploy to Kubernetes using Helm
        stage('Deploy to EKS') {
            steps {
                script {
                    sh """
                        # Configure EKS access
                        aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER}
                        
                        # Deploy using Helm
                        helm upgrade --install ${APP_NAME} ./charts/${APP_NAME} \
                            --namespace ${APP_NAME} \
                            --create-namespace \
                            --set image.repository=${ECR_REGISTRY}/${APP_NAME} \
                            --set image.tag=${DOCKER_IMAGE_TAG} \
                            --set-string image.pullPolicy=Always \
                            --wait
                    """
                }
            }
        }
    }
    
    post {
        always {
            // Clean up Docker images to save space
            sh 'docker system prune -f'
            
            // Update build description
            script {
                currentBuild.description = "Branch: ${env.BRANCH_NAME} | Commit: ${env.GIT_COMMIT.substring(0,7)}"
            }
        }
        success {
            emailext (
                subject: "SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: "The build ${env.BUILD_URL} completed successfully.",
                to: "dev-team@company.com"
            )
        }
        failure {
            emailext (
                subject: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: "The build ${env.BUILD_URL} failed. Please check the logs.",
                to: "dev-team@company.com"
            )
        }
    }
}
