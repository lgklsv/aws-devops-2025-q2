pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: python
      image: python:3.9-slim-buster
      command:
        - cat
      tty: true
      resources:
        requests:
          memory: "256Mi"
          cpu: "250m"
        limits:
          memory: "512Mi"
          cpu: "500m"
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent
    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      command:
        - cat
      tty: true
      resources:
        requests:
          memory: "512Mi"
          cpu: "500m"
        limits:
          memory: "1Gi"
          cpu: "1000m"
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker
        - name: workspace-volume
          mountPath: /home/jenkins/agent
    - name: aws-cli
      image: amazon/aws-cli:latest
      command:
        - cat
      tty: true
      resources:
        requests:
          memory: "64Mi"
          cpu: "100m"
        limits:
          memory: "128Mi"
          cpu: "200m"
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker
  volumes:
    - name: workspace-volume
      emptyDir: {}
    - name: docker-config
      emptyDir: {}
'''
        }
    }

    environment {
        APP_DIR = 'flask_app'
        AWS_REGION = 'us-east-1'
        DOCKER_IMAGE_NAME = 'flask-app'  
        APP_VERSION = "${env.BUILD_NUMBER}"

        SONAR_SCANNER_HOME = tool 'SonarScanner'
        KUBECONFIG_CONTENT_ID = 'your-kubeconfig-secret-id' // TODO: change
        K8S_NAMESPACE = 'default' 
        HELM_CHART_PATH = 'flask-app-chart'
        HELM_RELEASE_NAME = 'flask-app-release'
    }

    stages {
        stage('Install Python Dependencies') {
            steps {
                container('python') {
                    script {
                        echo "Navigating to application directory: ${APP_DIR}"
                        dir("${APP_DIR}") { 
                            echo 'Installing Python dependencies...'
                            sh 'pip install --no-cache-dir -r requirements.txt'
                        }
                    }
                }
            }
        }

        stage('Run Unit Tests') {
            steps {
                container('python') {
                    script {
                        echo 'Running unit tests with pytest...'
                        dir("${APP_DIR}") {
                            sh 'pytest --junitxml=report.xml'
                        }
                    }   
                }
            }
            post {
                always {
                    junit "${APP_DIR}/report.xml"
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv(credentialsId: 'sonar-token-secret-id', installationName: 'SonarQube') {
                    script {
                        echo 'Running SonarQube analysis for Python application...'

                        sh "${SONAR_SCANNER_HOME}/bin/sonar-scanner \
                            -Dsonar.projectKey=${DOCKER_IMAGE_NAME} \
                            -Dsonar.sources=${APP_DIR} \
                            -Dsonar.python.version=3.9 \
                            -Dsonar.host.url=${env.SONAR_HOST_URL} \
                            -Dsonar.login=${env.SONAR_AUTH_TOKEN} \
                            -Dsonar.tests=${APP_DIR}/tests \
                            -Dsonar.test.inclusions=${APP_DIR}/tests/** \
                            -Dsonar.junit.reportPaths=${APP_DIR}/report.xml"
                    }
                }
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-account-id', variable: 'AWS_ACCOUNT_ID'),
                    aws(credentialsId: 'aws-ecr-jenkins-credential')
                ]) {
                    script {
                        def DOCKER_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                        def IMAGE_FULL_TAG = "${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${APP_VERSION}"

                        echo "Authenticating with ECR for ${DOCKER_REGISTRY}"
                        container('aws-cli') {
                            withAWS(credentials: 'aws-ecr-jenkins-credential', region: AWS_REGION) {
                                sh """
                                    TOKEN=\$(aws ecr get-login-password --region ${AWS_REGION})
                                    echo '{
                                      "auths": {
                                        "${DOCKER_REGISTRY}": {
                                          "username": "AWS",
                                          "password": "${TOKEN}"
                                        }
                                      }
                                    }' > /kaniko/.docker/config.json
                                """
                                echo "ECR authentication config.json created."
                            }
                        }

                        container('kaniko') {
                            echo "Building Docker image with Kaniko: ${IMAGE_FULL_TAG}"
                            sh """
                                /kaniko/executor \
                                    --dockerfile=${APP_DIR}/Dockerfile \
                                    --context=dir://${WORKSPACE}/${APP_DIR} \
                                    --destination=${IMAGE_FULL_TAG} \
                                    --skip-tls-verify=false
                            """
                            echo 'Docker image built and pushed successfully with Kaniko!'
                        }
                    }
                }
            }
        }

        // stage('Deploy to Kubernetes') {
        //     steps {
        //         script {
        //             echo 'Setting up Kubeconfig for deployment...'
        //             // Retrieve Kubeconfig content from Jenkins Secret and save to a temporary file
        //             // KUBECONFIG_CONTENT_ID refers to a 'Secret file' credential type in Jenkins
        //             // OR you can use 'Secret text' and echo it as shown in previous example.
        //             // Let's assume 'Secret text' for simplicity:
        //             withCredentials([string(credentialsId: KUBECONFIG_CONTENT_ID, variable: 'KUBECONFIG_CONTENT')]) {
        //                 sh "mkdir -p \${HOME}/.kube"
        //                 sh "echo \"\$KUBECONFIG_CONTENT\" > \${HOME}/.kube/config"
        //                 sh "chmod 600 \${HOME}/.kube/config"
        //             }

        //             // Ensure kubectl is configured
        //             sh "kubectl config use-context $(kubectl config current-context)" // Or specific context if you have multiple

        //             echo "Deploying application to K8s with Helm using image tag: ${APP_VERSION}"
        //             sh "helm upgrade --install ${HELM_RELEASE_NAME} ${HELM_CHART_PATH} \
        //                --namespace ${K8S_NAMESPACE} \
        //                --set image.repository=${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME} \
        //                --set image.tag=${APP_VERSION} \
        //                --wait --atomic"

        //             echo 'Helm deployment complete!'
        //         }
        //     }
        // }
        // stage('Verify Application') {
        //     steps {
        //         script {
        //             echo 'Performing application verification...'
        //             // This part is highly dependent on how your Flask app is exposed in K8s (Service type, Ingress).
        //             // For a simple NodePort service in K3s:
        //             // 1. Get the Node IP (your K3s node IP, e.g., 192.168.49.2 from earlier)
        //             // 2. Get the NodePort assigned to your service (e.g., 3xxxx)
        //             //    You can get this dynamically:
        //             def nodeIp = sh(returnStdout: true, script: "kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type==\"InternalIP\")].address}'").trim()
        //             def nodePort = sh(returnStdout: true, script: "kubectl get service ${HELM_RELEASE_NAME} -n ${K8S_NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}'").trim()
        //             def appUrl = "http://${nodeIp}:${nodePort}"

        //             echo "Curling application at ${appUrl}..."
        //             // Loop and retry for a few seconds as the service might take a moment to be ready
        //             retry(5) { // Retry up to 5 times
        //                 timeout(time: 60, unit: 'SECONDS') { // Timeout for each curl attempt
        //                     sh "curl -f --max-time 10 ${appUrl}"
        //                     // Add assertion if your "hello world" route returns specific text
        //                     // sh "curl -f ${appUrl} | grep 'Hello World'"
        //                 }
        //             }
        //             echo 'Application verification successful!'
        //         }
        //     }
        // }
    }

    post {
        always {
            echo 'Pipeline finished.'
            sh "rm -f \${HOME}/.kube/config"
        }
        success {
            echo 'Pipeline succeeded! Sending success notification.'
        }
        failure {
            echo 'Pipeline failed! Sending failure notification.'
        }
    }
}
