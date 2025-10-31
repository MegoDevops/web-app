pipeline {
  agent any

  environment {
    AWS_CREDENTIALS = credentials('aws-creds')
    GITHUB_CREDS = credentials('github-token')
    SONAR_TOKEN = credentials('sonar-token')
    CLUSTER_NAME = "garden-web-app-cluster"
    REGION = "eu-west-3"
    ECR_API = "964711978492.dkr.ecr.eu-west-3.amazonaws.com/garden-web-app-api"
    ECR_WEB = "964711978492.dkr.ecr.eu-west-3.amazonaws.com/garden-web-app-web"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
        echo "✅ Source code checked out successfully."
      }
    }

    stage('SonarQube Analysis') {
      steps {
        dir('web-app-example') {
          withSonarQubeEnv('SonarQube') {
              sh '''
                  /opt/sonar-scanner/bin/sonar-scanner \
                    -Dsonar.projectKey=garden-web-app \
                    -Dsonar.sources=. \
                    -Dsonar.host.url=http://localhost:9000 \
                    -Dsonar.login=$SONAR_TOKEN
              '''
            }
          }
        }
      }
    

    stage('Quality Gate') {
      steps {
        timeout(time: 20, unit: 'MINUTES') {
          echo "Skipping Quality Gate check"
          // waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Build & Push Docker Images') {
      parallel {

        stage('API Image') {
          steps {
            dir('web-app-example/api') {
              sh '''
                echo "🔧 Building API image..."
                aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_API
                docker build -t $ECR_API:$BUILD_NUMBER .

                echo "🔧 Pushing API image to ECR..."
                docker push $ECR_API:$BUILD_NUMBER

                echo "🔧 Scanning API image with Trivy..."
                docker run --rm aquasec/trivy image --exit-code 0 --severity HIGH,CRITICAL $ECR_API:$BUILD_NUMBER

                echo "✅ API image pushed and scanned successfully."
              '''
            }
          }
        }

        stage('Web Image') {
          steps {
            dir('web-app-example/web') {
              sh '''
                  echo "🔧 Building Web image..."
                  aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_WEB
                  docker build -t $ECR_WEB:$BUILD_NUMBER .

                  echo "🔧 Pushing Web image to ECR..."
                  docker push $ECR_WEB:$BUILD_NUMBER

                  echo "🔧 Scanning Web image with Trivy..."
                  docker run --rm aquasec/trivy image --exit-code 0 --severity HIGH,CRITICAL $ECR_WEB:$BUILD_NUMBER

                   echo "✅ Web image pushed and scanned successfully."
              '''
            }
          }
        }
      }
    }
stage('Deploy to EKS (Helm)') {
  steps {
    dir('kubernetes/helm/garden-app') {
      sh '''
        echo "🚀 Deploying to EKS using Helm..."

        aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

        # Clean up any failed deployments first
        echo "Cleaning up any failed deployments..."
        helm uninstall api || true
        helm uninstall web || true
        kubectl delete deployment garden-api garden-web || true
        kubectl delete service garden-api-service garden-web-service || true

        # Wait for cleanup
        sleep 10

        echo "Deploying API (without web)..."
        helm upgrade --install api . \
          --set api.image.repository="$ECR_API" \
          --set api.image.tag="$BUILD_NUMBER" \
          --set web.image.repository="busybox" \
          --set web.image.tag="latest" \
          --timeout 10m \
          --debug

        echo "Waiting for API to be ready..."
        kubectl wait --for=condition=ready pod -l app=garden-api --timeout=300s

        echo "Deploying Web with correct image..."
        helm upgrade --install web . \
          --set api.image.repository="busybox" \
          --set api.image.tag="latest" \
          --set web.image.repository="$ECR_WEB" \
          --set web.image.tag="$BUILD_NUMBER" \
          --timeout 10m \
          --debug

        echo "Waiting for Web to be ready..."
        kubectl wait --for=condition=ready pod -l app=garden-web --timeout=300s

        echo "✅ Deployment completed successfully."
        
        # Final status
        echo "=== Final Status ==="
        helm list
        kubectl get pods,services
      '''
    }
  }
}
  }

  post {
    success {
      echo "✅ CI/CD completed successfully. Both API and Web deployed to EKS."
    }
    failure {
      echo "❌ Pipeline failed. Check Jenkins logs for details."
    }
  }
}
