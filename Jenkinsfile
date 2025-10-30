pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-west-3'
        EKS_CLUSTER = 'garden-web-app-cluster'
        ECR_REGISTRY = '964711978492.dkr.ecr.eu-west-3.amazonaws.com'
        DOCKER_IMAGE_TAG = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}-${env.GIT_COMMIT.substring(0,7)}"
    }

    options {
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Checkout Repository') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    extensions: [[$class: 'CleanBeforeCheckout']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/MegoDevops/web-app.git',
                        credentialsId: 'github-creds'
                    ]]
                ])

                sh '''
                    echo "=== Repository Structure ==="
                    ls -la
                    echo "=== Checking subdirectory web-app-example ==="
                    ls -la web-app-example || echo "web-app-example folder not found!"
                '''
            }
        }

        stage('Verify Structure') {
            steps {
                sh '''
                    echo "=== Verifying Project Structure ==="
                    ls -la web-app-example/web/
                    ls -la web-app-example/api/
                    echo "=== Checking Dockerfiles ==="
                    ls -la web-app-example/web/Dockerfile
                    ls -la web-app-example/api/Dockerfile
                '''
            }
        }

        stage('Build & Push Docker Images') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    script {
                        // Login to ECR
                        sh """
                            aws ecr get-login-password --region ${env.AWS_REGION} | docker login --username AWS --password-stdin ${env.ECR_REGISTRY}
                        """

                        // Build and push WEB image
                        sh """
                            cd web-app-example/web
                            docker build -t ${env.ECR_REGISTRY}/garden-web-app-web:${env.DOCKER_IMAGE_TAG} .
                            docker push ${env.ECR_REGISTRY}/garden-web-app-web:${env.DOCKER_IMAGE_TAG}
                            cd ../..
                        """

                        // Build and push API image
                        sh """
                            cd web-app-example/api
                            docker build -t ${env.ECR_REGISTRY}/garden-web-app-api:${env.DOCKER_IMAGE_TAG} .
                            docker push ${env.ECR_REGISTRY}/garden-web-app-api:${env.DOCKER_IMAGE_TAG}
                            cd ../..
                        """
                    }
                }
            }
        }

        stage('Trivy Security Scan') {
            steps {
                script {
                    sh """
                        if ! command -v trivy &> /dev/null; then
                            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
                        fi

                        trivy image --exit-code 0 --severity HIGH,CRITICAL ${env.ECR_REGISTRY}/garden-web-app-web:${env.DOCKER_IMAGE_TAG}
                        trivy image --exit-code 0 --severity HIGH,CRITICAL ${env.ECR_REGISTRY}/garden-web-app-api:${env.DOCKER_IMAGE_TAG}

                        trivy image --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
                          -o trivy-report-web.html ${env.ECR_REGISTRY}/garden-web-app-web:${env.DOCKER_IMAGE_TAG}
                        trivy image --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
                          -o trivy-report-api.html ${env.ECR_REGISTRY}/garden-web-app-api:${env.DOCKER_IMAGE_TAG}
                    """
                }
            }
            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'trivy-report-web.html,trivy-report-api.html',
                        reportName: 'Trivy Security Report'
                    ])
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    script {
                        // Configure kubeconfig
                        sh """
                            aws eks update-kubeconfig --region ${env.AWS_REGION} --name ${env.EKS_CLUSTER}
                        """

                        // Create namespace if not exists
                        sh """
                            kubectl create namespace garden-web-app --dry-run=client -o yaml | kubectl apply -f -
                        """

                        // Deploy web
                        sh """
                            cat > web-deployment.yaml << EOF
                            apiVersion: apps/v1
                            kind: Deployment
                            metadata:
                              name: garden-web-app-web
                              namespace: garden-web-app
                            spec:
                              replicas: 2
                              selector:
                                matchLabels:
                                  app: garden-web-app-web
                              template:
                                metadata:
                                  labels:
                                    app: garden-web-app-web
                                spec:
                                  containers:
                                  - name: web
                                    image: ${env.ECR_REGISTRY}/garden-web-app-web:${env.DOCKER_IMAGE_TAG}
                                    ports:
                                    - containerPort: 80
                                    env:
                                    - name: API_URL
                                      value: "http://garden-web-app-api:5000"
                            ---
                            apiVersion: v1
                            kind: Service
                            metadata:
                              name: garden-web-app-web
                              namespace: garden-web-app
                            spec:
                              type: LoadBalancer
                              selector:
                                app: garden-web-app-web
                              ports:
                              - port: 80
                                targetPort: 80
                            EOF
                            kubectl apply -f web-deployment.yaml
                        """

                        // Deploy API
                        sh """
                            cat > api-deployment.yaml << EOF
                            apiVersion: apps/v1
                            kind: Deployment
                            metadata:
                              name: garden-web-app-api
                              namespace: garden-web-app
                            spec:
                              replicas: 2
                              selector:
                                matchLabels:
                                  app: garden-web-app-api
                              template:
                                metadata:
                                  labels:
                                    app: garden-web-app-api
                                spec:
                                  containers:
                                  - name: api
                                    image: ${env.ECR_REGISTRY}/garden-web-app-api:${env.DOCKER_IMAGE_TAG}
                                    ports:
                                    - containerPort: 5000
                                    env:
                                    - name: DATABASE_URL
                                      value: "postgresql://user:pass@rds-endpoint:5432/gardendb"
                            ---
                            apiVersion: v1
                            kind: Service
                            metadata:
                              name: garden-web-app-api
                              namespace: garden-web-app
                            spec:
                              type: ClusterIP
                              selector:
                                app: garden-web-app-api
                              ports:
                              - port: 5000
                                targetPort: 5000
                            EOF
                            kubectl apply -f api-deployment.yaml
                        """

                        // Wait for pods
                        sh """
                            echo "=== Waiting for pods to be ready ==="
                            kubectl wait --for=condition=ready pod -l app=garden-web-app-web -n garden-web-app --timeout=300s || true
                            kubectl wait --for=condition=ready pod -l app=garden-web-app-api -n garden-web-app --timeout=300s || true
                            kubectl get all -n garden-web-app
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            sh 'docker system prune -f'
            script {
                currentBuild.description = "Branch: ${env.BRANCH_NAME} | Commit: ${env.GIT_COMMIT.substring(0,7)}"
            }
            archiveArtifacts artifacts: 'trivy-report-*.html', allowEmptyArchive: true
        }
        success {
            script {
                def webService = sh(
                    script: "kubectl get svc garden-web-app-web -n garden-web-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo 'Not available yet'",
                    returnStdout: true
                ).trim()

                emailext(
                    subject: "✅ SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                    body: """
                    🎉 Build Success! 
                    
                    🌐 Web URL: http://${webService}
                    🌿 Branch: ${env.BRANCH_NAME}
                    🔗 Commit: ${env.GIT_COMMIT.substring(0,7)}
                    🔧 Build: ${env.BUILD_URL}

                    🐳 Docker Images:
                    - Web: ${env.ECR_REGISTRY}/garden-web-app-web:${env.DOCKER_IMAGE_TAG}
                    - API: ${env.ECR_REGISTRY}/garden-web-app-api:${env.DOCKER_IMAGE_TAG}
                    """,
                    to: "bedobedo387@gmail.com"
                )
            }
        }
        failure {
            emailext(
                subject: "❌ FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """
                Build failed!

                Branch: ${env.BRANCH_NAME}
                Commit: ${env.GIT_COMMIT.substring(0,7)}
                Build logs: ${env.BUILD_URL}
                """,
                to: "bedobedo387@gmail.com"
            )
        }
    }
}
