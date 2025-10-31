pipeline {
  agent any

  environment {
    AWS_CREDENTIALS = credentials('aws-creds')
    GITHUB_CREDS = credentials('c8a0bac6-514c-4906-93a4-eb61dbea091a')
    SONAR_TOKEN = credentials('sonarqube-token')
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
              sh """
                sonar-scanner \
                 -Dsonar.projectKey=garden-web-app \
                 -Dsonar.sources=. \
                 -Dsonar.host.url=http://localhost:9000 \
                 -Dsonar.login=${SONAR_TOKEN}
              """
            }
          }
        }
      }
    }

    stage('Quality Gate') {
      steps {
        timeout(time: 2, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Build & Push Docker Images') {
      parallel {

        stage('API Image') {
          steps {
            dir('web-app-example/api') {
              sh '''
                echo "🔧 Building and pushing API image..."
                aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_API
                docker build -t $ECR_API:$BUILD_NUMBER .
                docker run --rm aquasec/trivy image --exit-code 0 --severity HIGH,CRITICAL $ECR_API:$BUILD_NUMBER
                docker push $ECR_API:$BUILD_NUMBER
                echo "✅ API image pushed successfully."
              '''
            }
          }
        }

        stage('Web Image') {
          steps {
            dir('web-app-example/web') {
              sh '''
                echo "🔧 Building and pushing Web image..."
                aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_WEB
                docker build -t $ECR_WEB:$BUILD_NUMBER .
                docker run --rm aquasec/trivy image --exit-code 0 --severity HIGH,CRITICAL $ECR_WEB:$BUILD_NUMBER
                docker push $ECR_WEB:$BUILD_NUMBER
                echo "✅ Web image pushed successfully."
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
            helm upgrade --install api ./ --set api.image.repository=$ECR_API --set api.image.tag=$BUILD_NUMBER
            helm upgrade --install web ./ --set web.image.repository=$ECR_WEB --set web.image.tag=$BUILD_NUMBER
            echo "✅ Deployment completed successfully."
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
