pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-west-3'
        ECR_REGISTRY = '964711978492.dkr.ecr.eu-west-3.amazonaws.com'
        EKS_CLUSTER = 'nti-final-cluster'
        DOCKER_TAG = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}-${env.GIT_COMMIT.substring(0,7)}"
    }

    options {
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout scm
                sh 'ls -R web-app-example || true'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh '''
                        echo "=== Running SonarQube Analysis ==="
                        cd web-app-example
                        sonar-scanner \
                            -Dsonar.projectKey=nti-final-project \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=$SONAR_HOST_URL \
                            -Dsonar.login=$SONAR_AUTH_TOKEN
                    '''
                }
            }
        }

        stage('SonarQube Quality Gate') {
            steps {
                timeout(time: 3, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build & Push Docker Images') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    script {
                        sh """
                            echo "=== Logging into AWS ECR ==="
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        """

                        // WEB
                        sh """
                            echo "=== Building WEB Image ==="
                            cd web-app-example/web
                            docker build -t ${ECR_REGISTRY}/nti-web:${DOCKER_TAG} .
                            docker push ${ECR_REGISTRY}/nti-web:${DOCKER_TAG}
                            cd ../../
                        """

                        // API
                        sh """
                            echo "=== Building API Image ==="
                            cd web-app-example/api
                            docker build -t ${ECR_REGISTRY}/nti-api:${DOCKER_TAG} .
                            docker push ${ECR_REGISTRY}/nti-api:${DOCKER_TAG}
                            cd ../../
                        """
                    }
                }
            }
        }

        stage('Trivy Security Scan') {
            steps {
                sh """
                    echo "=== Security Scan with Trivy ==="
                    if ! command -v trivy &> /dev/null; then
                        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
                    fi
                    trivy image --exit-code 0 --severity HIGH,CRITICAL ${ECR_REGISTRY}/nti-web:${DOCKER_TAG}
                    trivy image --exit-code 0 --severity HIGH,CRITICAL ${ECR_REGISTRY}/nti-api:${DOCKER_TAG}
                """
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh """
                        echo "=== Updating kubeconfig ==="
                        aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER}

                        echo "=== Creating Namespace if not exists ==="
                        kubectl create namespace nti-final --dry-run=client -o yaml | kubectl apply -f -

                        echo "=== Deploying WEB App ==="
                        cat > web-deploy.yaml <<EOF
                        apiVersion: apps/v1
                        kind: Deployment
                        metadata:
                          name: nti-web
                          namespace: nti-final
                        spec:
                          replicas: 2
                          selector:
                            matchLabels:
                              app: nti-web
                          template:
                            metadata:
                              labels:
                                app: nti-web
                            spec:
                              containers:
                              - name: web
                                image: ${ECR_REGISTRY}/nti-web:${DOCKER_TAG}
                                ports:
                                - containerPort: 80
                                env:
                                - name: API_URL
                                  value: "http://nti-api:5000"
                        ---
                        apiVersion: v1
                        kind: Service
                        metadata:
                          name: nti-web
                          namespace: nti-final
                        spec:
                          type: LoadBalancer
                          selector:
                            app: nti-web
                          ports:
                          - port: 80
                            targetPort: 80
                        EOF

                        echo "=== Deploying API App ==="
                        cat > api-deploy.yaml <<EOF
                        apiVersion: apps/v1
                        kind: Deployment
                        metadata:
                          name: nti-api
                          namespace: nti-final
                        spec:
                          replicas: 2
                          selector:
                            matchLabels:
                              app: nti-api
                          template:
                            metadata:
                              labels:
                                app: nti-api
                            spec:
                              containers:
                              - name: api
                                image: ${ECR_REGISTRY}/nti-api:${DOCKER_TAG}
                                ports:
                                - containerPort: 5000
                                env:
                                - name: DATABASE_URL
                                  value: "postgresql://user:pass@rds-endpoint:5432/gardendb"
                        ---
                        apiVersion: v1
                        kind: Service
                        metadata:
                          name: nti-api
                          namespace: nti-final
                        spec:
                          type: ClusterIP
                          selector:
                            app: nti-api
                          ports:
                          - port: 5000
                            targetPort: 5000
                        EOF

                        echo "=== Applying Deployments ==="
                        kubectl apply -f web-deploy.yaml
                        kubectl apply -f api-deploy.yaml

                        echo "=== Checking Resources ==="
                        kubectl get pods -n nti-final
                        kubectl get svc -n nti-final
                    """
                }
            }
        }
    }

    post {
        always {
            sh 'docker system prune -f || true'
            echo "🧹 Cleaned up Docker environment"
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed — check Jenkins logs."
        }
    }
}
