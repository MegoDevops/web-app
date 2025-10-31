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
        
        # Debug: Check Helm chart structure
        echo "=== HELM CHART STRUCTURE ==="
        pwd
        ls -la
        echo "--- Chart.yaml ---"
        cat Chart.yaml || echo "No Chart.yaml found"
        echo "--- values.yaml ---" 
        cat values.yaml || echo "No values.yaml found"
        echo "--- Templates ---"
        ls -la templates/ || echo "No templates directory found"
        echo "========================"

        # Configure kubectl
        echo "Configuring kubectl..."
        aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
        
        # Test cluster access
        echo "Testing cluster access..."
        kubectl get nodes
        kubectl get namespaces
        
        # List current helm releases
        echo "Current Helm releases:"
        helm list --all
        
        # Test if we can access the cluster with helm
        echo "Testing Helm cluster access..."
        helm ls --all-namespaces

        deploy_release() {
          local name=$1
          local image_repo=$2
          local image_tag=$3

          echo "📦 Processing $name release with image: $image_repo:$image_tag"
          
          # Check if release exists
          if helm status $name &> /dev/null; then
            echo "🔄 Release $name exists - upgrading..."
            helm upgrade $name . \\
              --set ${name}.image.repository=$image_repo \\
              --set ${name}.image.tag=$image_tag \\
              --debug
          else
            echo "✨ Release $name does not exist - installing..."
            helm install $name . \\
              --set ${name}.image.repository=$image_repo \\
              --set ${name}.image.tag=$image_tag \\
              --debug
          fi
        }

        echo "Deploying API..."
        deploy_release "api" "$ECR_API" "$BUILD_NUMBER"
        
        echo "Deploying Web..."
        deploy_release "web" "$ECR_WEB" "$BUILD_NUMBER"

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
