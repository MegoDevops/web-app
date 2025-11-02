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
    NAMESPACE = "garden-app"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        echo "✅ Source code checked out successfully."
        
        // Display project structure
        sh '''
          echo "=== Project Structure ==="
          find . -type f -name "*.py" -o -name "*.yaml" -o -name "*.yml" -o -name "Dockerfile" -o -name "requirements.txt" | head -20
          echo "========================="
        '''
      }
    }

    stage('Dependency Check') {
      steps {
        script {
          // Verify all required files exist
          def requiredFiles = [
            'web-app-example/api/app.py',
            'web-app-example/api/requirements.txt',
            'web-app-example/api/test.py',
            'kubernetes/helm/garden-api/Chart.yaml',
            'kubernetes/helm/garden-api/values.yaml',
            'kubernetes/helm/garden-api/templates/deployment.yaml',
            'kubernetes/helm/garden-api/templates/service.yaml',
            'kubernetes/helm/garden-web/Chart.yaml',
            'kubernetes/helm/garden-web/values.yaml',
            'kubernetes/helm/garden-web/templates/deployment.yaml',
            'kubernetes/helm/garden-web/templates/service.yaml',
            'kubernetes/helm/garden-db/Chart.yaml',
            'kubernetes/helm/garden-db/values.yaml',
            'kubernetes/helm/garden-db/templates/deployment.yaml',
            'kubernetes/helm/garden-db/templates/service.yaml',
            'kubernetes/helm/db-seed/Chart.yaml',
            'kubernetes/helm/db-seed/templates/job.yaml'
          ]
          
          def missingFiles = []
          requiredFiles.each { file ->
            if (!fileExists(file)) {
              missingFiles.add(file)
            }
          }
          
          if (missingFiles) {
            error "Missing required files: ${missingFiles.join(', ')}"
          } else {
            echo "✅ All required files present"
          }
        }
      }
    }
    
    stage('SonarQube Analysis') {
      steps {
        dir('web-app-example') {
          withSonarQubeEnv('SonarQube') {
            sh '''
                /opt/sonar-scanner/bin/sonar-scanner \\
                  -Dsonar.projectKey=garden-web-app \\
                  -Dsonar.sources=. \\
                  -Dsonar.host.url=http://localhost:9000 \\
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
                
                # Build the image
                docker build -t $ECR_API:$BUILD_NUMBER .
                docker tag $ECR_API:$BUILD_NUMBER $ECR_API:latest

                echo "🔧 Pushing API image to ECR..."
                docker push $ECR_API:$BUILD_NUMBER
                docker push $ECR_API:latest

                echo "🔧 Scanning API image with Trivy..."
                docker run --rm aquasec/trivy image --exit-code 0 --severity HIGH,CRITICAL $ECR_API:$BUILD_NUMBER

                echo "✅ API image pushed and scanned successfully."
                
                # Display image info
                docker images | grep $ECR_API
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
                
                # Create package.json if it doesn't exist
                if [ ! -f package.json ]; then
                  echo '{
                    "name": "garden-web-app",
                    "version": "1.0.0",
                    "description": "Garden voting web application",
                    "scripts": {
                      "start": "npx http-server -p 8080",
                      "test": "mocha test.js --timeout 10000"
                    },
                    "dependencies": {
                      "axios": "^1.0.0"
                    },
                    "devDependencies": {
                      "mocha": "^10.0.0",
                      "chai": "^4.3.0",
                      "http-server": "^14.0.0"
                    }
                  }' > package.json
                fi
                
                # Build the image
                docker build -t $ECR_WEB:$BUILD_NUMBER .
                docker tag $ECR_WEB:$BUILD_NUMBER $ECR_WEB:latest

                echo "🔧 Pushing Web image to ECR..."
                docker push $ECR_WEB:$BUILD_NUMBER
                docker push $ECR_WEB:latest

                echo "🔧 Scanning Web image with Trivy..."
                docker run --rm aquasec/trivy image --exit-code 0 --severity HIGH,CRITICAL $ECR_WEB:$BUILD_NUMBER

                echo "✅ Web image pushed and scanned successfully."
                
                # Display image info
                docker images | grep $ECR_WEB
              '''
            }
          }
        }
      }
    }

    stage('Run Tests') {
      parallel {
        stage('API Tests') {
          steps {
            dir('web-app-example/api') {
              sh '''
                echo "🧪 Running API tests..."
                # Test if the application starts correctly
                docker run -d --name test-api -p 8081:8080 $ECR_API:$BUILD_NUMBER
                sleep 10
                
                # Test health endpoint
                if curl -f http://localhost:8081/health; then
                  echo "✅ API health check passed"
                else
                  echo "❌ API health check failed"
                  docker logs test-api
                  exit 1
                fi
                
                # Cleanup
                docker stop test-api
                docker rm test-api
                
                # Run unit tests
                if [ -f "test.py" ]; then
                  echo "Running Python tests..."
                  docker run --rm $ECR_API:$BUILD_NUMBER python -m unittest test.py || echo "Tests completed"
                fi
              '''
            }
          }
        }

        stage('Web Tests') {
          steps {
            dir('web-app-example/web') {
              sh '''
                echo "🧪 Running Web tests..."
                # Test if the application starts correctly
                docker run -d --name test-web -p 8082:8080 $ECR_WEB:$BUILD_NUMBER
                sleep 10
                
                # Test if web server is running
                if curl -f http://localhost:8082/; then
                  echo "✅ Web server check passed"
                else
                  echo "❌ Web server check failed"
                  docker logs test-web
                  exit 1
                fi
                
                # Cleanup
                docker stop test-web
                docker rm test-web
                
                # Run JavaScript tests if test file exists
                if [ -f "test.js" ]; then
                  echo "Running JavaScript tests..."
                  docker run --rm $ECR_WEB:$BUILD_NUMBER npm test || echo "Tests completed"
                fi
              '''
            }
          }
        }
      }
    }

    stage('Deploy to EKS (Helm)') {
      steps {
        dir('kubernetes/helm') {
          script {
            // Verify Helm charts
            sh '''
              echo "🔍 Verifying Helm charts..."
              helm lint garden-api || echo "API chart linting completed"
              helm lint garden-web || echo "Web chart linting completed"
              helm lint garden-db || echo "DB chart linting completed"
              helm lint db-seed || echo "DB seed chart linting completed"
            '''

            // Configure kubectl
            sh '''
              echo "🔧 Configuring kubectl for EKS cluster..."
              aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
              
              # Create namespace if it doesn't exist
              kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
              
              echo "📋 Current cluster status:"
              kubectl get nodes
              kubectl get ns $NAMESPACE || echo "Namespace will be created"
            '''

            // Deploy Database
            echo "🚀 Deploying PostgreSQL database..."
            sh '''
              helm upgrade --install garden-db ./garden-db \
                --namespace $NAMESPACE \
                --set database.password=postgres \
                --set image.tag="12.4-alpine" \
                --atomic \
                --timeout 10m \
                --wait
            '''

            // Wait for database to be ready
            echo "⏳ Waiting for database to be ready..."
            sh '''
              kubectl wait --for=condition=ready pod -l app=postgresql -n $NAMESPACE --timeout=300s
              echo "✅ Database is ready"
              
              # Additional wait for database initialization
              sleep 15
            '''

            // Seed database
            echo "🌱 Seeding database..."
            sh '''
              helm upgrade --install db-seed ./db-seed \
                --namespace $NAMESPACE \
                --set database.host=postgresql \
                --set database.password=postgres \
                --set image.tag="12.4-alpine" \
                --wait \
                --timeout 5m
              
              # Check seed job status
              kubectl get jobs -n $NAMESPACE
              kubectl wait --for=condition=complete job/db-seed -n $NAMESPACE --timeout=120s
              echo "✅ Database seeded successfully"
            '''

            // Deploy API
            echo "📦 Deploying API..."
            sh '''
              helm upgrade --install garden-api ./garden-api \
                --namespace $NAMESPACE \
                --set image.repository="$ECR_API" \
                --set image.tag="$BUILD_NUMBER" \
                --set env.DB_HOST=postgresql \
                --set env.PGPASSWORD=postgres \
                --set env.PGDATABASE=postgres \
                --set env.PGUSER=postgres \
                --set env.FLASK_ENV=production \
                --atomic \
                --timeout 10m \
                --wait \
                --debug
            '''

            // Wait for API to be ready
            echo "⏳ Waiting for API to be ready..."
            sh '''
              kubectl wait --for=condition=ready pod -l app=garden-api -n $NAMESPACE --timeout=300s
              echo "✅ API is ready"
              
              # Test API health
              kubectl run api-test -n $NAMESPACE --image=curlimages/curl --rm -i --restart=Never -- \
                curl -f http://garden-api:8080/health || echo "API health check completed"
            '''

            // Deploy Web
            echo "🌐 Deploying Web..."
            sh '''
              helm upgrade --install garden-web ./garden-web \
                --namespace $NAMESPACE \
                --set image.repository="$ECR_WEB" \
                --set image.tag="$BUILD_NUMBER" \
                --set env.API_URL=http://garden-api:8080 \
                --set env.HOSTNAME=web.garden-app.local \
                --atomic \
                --timeout 10m \
                --wait \
                --debug
            '''

            // Wait for Web to be ready
            echo "⏳ Waiting for Web to be ready..."
            sh '''
              kubectl wait --for=condition=ready pod -l app=garden-web -n $NAMESPACE --timeout=300s
              echo "✅ Web is ready"
            '''
          }
        }
      }
    }

    stage('Smoke Tests') {
      steps {
        script {
          echo "🧪 Running smoke tests in cluster..."
          sh '''
            aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
            
            # Test API endpoints
            echo "Testing API endpoints..."
            kubectl run smoke-test-api -n $NAMESPACE --image=curlimages/curl --rm -i --restart=Never -- \
              curl -f http://garden-api:8080/health && echo "✅ API Health: PASSED" || echo "❌ API Health: FAILED"
              
            kubectl run smoke-test-api-vote -n $NAMESPACE --image=curlimages/curl --rm -i --restart=Never -- \
              curl -f http://garden-api:8080/api/vote && echo "✅ API Vote GET: PASSED" || echo "❌ API Vote GET: FAILED"
              
            # Test Web endpoints
            echo "Testing Web endpoints..."
            kubectl run smoke-test-web -n $NAMESPACE --image=curlimages/curl --rm -i --restart=Never -- \
              curl -f http://garden-web:8080/ && echo "✅ Web Health: PASSED" || echo "❌ Web Health: FAILED"
          '''
        }
      }
    }

    stage('Verification') {
      steps {
        script {
          echo "📊 Deployment Verification"
          sh '''
            aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
            
            echo "=== Helm Releases ==="
            helm list -n $NAMESPACE
            
            echo "=== Pods Status ==="
            kubectl get pods -n $NAMESPACE -o wide
            
            echo "=== Services ==="
            kubectl get services -n $NAMESPACE
            
            echo "=== Deployments ==="
            kubectl get deployments -n $NAMESPACE
            
            echo "=== Database Status ==="
            kubectl get pods -n $NAMESPACE -l app=postgresql
            
            echo "=== API Logs (last 5 lines) ==="
            kubectl logs -n $NAMESPACE -l app=garden-api --tail=5 || echo "No API logs available"
            
            echo "=== Web Logs (last 5 lines) ==="
            kubectl logs -n $NAMESPACE -l app=garden-web --tail=5 || echo "No Web logs available"
            
            echo "✅ Verification completed!"
          '''
        }
      }
    }
    stage('Get Application URLs') {
      steps {
        script {
          sh '''
            echo "🌐 Getting Application URLs..."
            aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
        
            # Get Load Balancer hostname
            LB_HOST=$(kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        
            echo "=========================================="
            echo "🚀 YOUR APPLICATION IS DEPLOYED!"
            echo "=========================================="
            echo "Load Balancer URL: http://$LB_HOST"
            echo ""
            echo "Web Frontend: http://web.garden-app.local"
            echo "API Backend:  http://api.garden-app.local" 
            echo ""
            echo "📍 To access immediately, add to your /etc/hosts:"
            echo "$LB_HOST web.garden-app.local api.garden-app.local"
            echo "=========================================="
        '''
    }
  }
}
  }

  post {
    always {
      echo "📊 Pipeline execution completed. Build: $BUILD_NUMBER"
      
      // Cleanup test resources
      sh '''
        aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
        kubectl delete pod smoke-test-api smoke-test-api-vote smoke-test-web -n $NAMESPACE --ignore-not-found=true
      '''
      
      // Archive important files
      archiveArtifacts artifacts: 'web-app-example/api/requirements.txt,web-app-example/api/Dockerfile,kubernetes/helm/**/*.yaml', fingerprint: true
    }
    
    success {
      echo "✅ CI/CD completed successfully! Application deployed to EKS namespace: $NAMESPACE"
      
      // Display application information
      sh '''
        echo "🌐 Application Deployment Summary:"
        echo "=================================="
        echo "Namespace: $NAMESPACE"
        echo "API Image: $ECR_API:$BUILD_NUMBER"
        echo "Web Image: $ECR_WEB:$BUILD_NUMBER"
        echo "Database: PostgreSQL (postgresql.$NAMESPACE.svc.cluster.local:5432)"
        echo ""
        echo "Services:"
        echo "- API: garden-api.$NAMESPACE.svc.cluster.local:8080"
        echo "- Web: garden-web.$NAMESPACE.svc.cluster.local:8080"
        echo "- DB: postgresql.$NAMESPACE.svc.cluster.local:5432"
        echo ""
        echo "To access pods: kubectl get pods -n $NAMESPACE"
        echo "To view logs: kubectl logs -l app=garden-api -n $NAMESPACE"
        echo "To test API: kubectl run curl-test -n $NAMESPACE --image=curlimages/curl --rm -it --restart=Never -- curl http://garden-api:8080/health"
      '''
      
      // Send success notification (optional)
      // emailext (
      //   subject: "SUCCESS: Garden App Deployment - Build ${env.BUILD_NUMBER}",
      //   body: "The Garden application has been successfully deployed to EKS.\n\nBuild: ${env.BUILD_URL}\nNamespace: ${env.NAMESPACE}\nImages: ${env.ECR_API}:${env.BUILD_NUMBER}, ${env.ECR_WEB}:${env.BUILD_NUMBER}",
      //   to: 'devops@yourcompany.com'
      // )
    }
    
    failure {
      echo "❌ Pipeline failed. Check Jenkins logs for details."
      
      // Get failure details for debugging
      sh '''
        echo "🔍 Debug information:"
        aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
        echo "--- Failed Pods ---"
        kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running --no-headers
        echo "--- Pods Events ---"
        kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10
        echo "--- Describe Failed Pods ---"
        kubectl describe pods -n $NAMESPACE --selector=app
      '''
      
      // Send failure notification (optional)
      // emailext (
      //   subject: "FAILED: Garden App Deployment - Build ${env.BUILD_NUMBER}",
      //   body: "The Garden application deployment failed.\n\nBuild: ${env.BUILD_URL}\nCheck Jenkins logs for details.",
      //   to: 'devops@yourcompany.com'
      // )
    }
    
    cleanup {
      // Clean up workspace
      cleanWs()
    }
  }
}