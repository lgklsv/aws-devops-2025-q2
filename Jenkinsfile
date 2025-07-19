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
        - sleep
      args:
        - 99d
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent
    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      command:
        - sleep
      args:
        - 99d
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker
        - name: workspace-volume
          mountPath: /home/jenkins/agent
    - name: aws-cli
      image: amazon/aws-cli:latest
      command:
        - sleep
      args:
        - 99d
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker
    - name: kubectl
      image: alpine/k8s:1.30.14
      command:
        - sleep
      args:
        - 99d
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent
        - name: kubeconfig-volume
          mountPath: /home/jenkins/.kube
  volumes:
    - name: workspace-volume
      emptyDir: {}
    - name: docker-config
      emptyDir: {}
    - name: kubeconfig-volume
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
        KUBECONFIG_CONTENT_ID = 'k8s-cluster-kubeconfig'
        K8S_NAMESPACE = 'default' 
        HELM_CHART_PATH = 'flask-app-chart'
        HELM_CHART_NAME = 'flask-app-chart'
        HELM_RELEASE_NAME = 'flask-app-release'
        K8S_PULL_SECRET_NAME = 'ecr-registry-secret'
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

        // stage('SonarQube Analysis') {
        //     steps {
        //         withSonarQubeEnv(credentialsId: 'sonar-token-secret-id', installationName: 'SonarQube') {
        //             script {
        //                 echo 'Running SonarQube analysis for Python application...'

        //                 sh "${SONAR_SCANNER_HOME}/bin/sonar-scanner \
        //                     -Dsonar.projectKey=${DOCKER_IMAGE_NAME} \
        //                     -Dsonar.sources=${APP_DIR} \
        //                     -Dsonar.python.version=3.9 \
        //                     -Dsonar.host.url=${env.SONAR_HOST_URL} \
        //                     -Dsonar.login=${env.SONAR_AUTH_TOKEN} \
        //                     -Dsonar.tests=${APP_DIR}/tests \
        //                     -Dsonar.test.inclusions=${APP_DIR}/tests/** \
        //                     -Dsonar.junit.reportPaths=${APP_DIR}/report.xml"
        //             }
        //         }
        //     }
        // }

        stage('Build & Push Docker Image') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-account-id', variable: 'AWS_ACCOUNT_ID_SECRET'),
                    aws(credentialsId: 'aws-ecr-jenkins-credential')
                ]) {
                    script {
                        env.AWS_ACCOUNT_ID = AWS_ACCOUNT_ID_SECRET

                        def DOCKER_REGISTRY = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                        def IMAGE_FULL_TAG = "${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${APP_VERSION}"

                        echo "Authenticating with ECR for ${DOCKER_REGISTRY}"
                        container('aws-cli') {
                            sh """
                                TOKEN=\$(aws ecr get-login-password --region ${AWS_REGION})
                                echo "{ \\"auths\\": { \\"${DOCKER_REGISTRY}\\": { \\"username\\": \\"AWS\\", \\"password\\": \\"\${TOKEN}\\" } } }" > /kaniko/.docker/config.json
                            """
                            echo "ECR authentication config.json created."
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

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') { 
                    script {
                        echo 'Setting up Kubeconfig for deployment...'

                        withCredentials([string(credentialsId: KUBECONFIG_CONTENT_ID, variable: 'KUBECONFIG_CONTENT')]) {
                            sh "echo \"\$KUBECONFIG_CONTENT\" > /home/jenkins/.kube/config"
                            sh "chmod 600 /home/jenkins/.kube/config"
                        }

                        echo "Configuring kubectl with context: \$(kubectl config current-context)"

                        echo "Creating Kubernetes secret for ECR access..."
                        withCredentials([
                            string(credentialsId: 'aws-account-id', variable: 'AWS_ACCOUNT_ID_SECRET'),
                            aws(credentialsId: 'aws-ecr-jenkins-credential')
                        ]) {
                            env.AWS_ACCOUNT_ID = AWS_ACCOUNT_ID_SECRET
                            def DOCKER_REGISTRY = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                            def ecrToken = ''

                            container('aws-cli') {
                                ecrToken = sh(script: "aws ecr get-login-password --region ${AWS_REGION}", returnStdout: true).trim()
                            }

                            sh """
                                kubectl create secret docker-registry ${K8S_PULL_SECRET_NAME} \\
                                --namespace ${K8S_NAMESPACE} \\
                                --docker-server=${DOCKER_REGISTRY} \\
                                --docker-username=AWS \\
                                --docker-password='${ecrToken}' \\
                                --dry-run=client -o yaml | kubectl apply -f -
                            """
                            echo "Secret ${K8S_PULL_SECRET_NAME} created/updated."
                        }

                        echo "Deploying application to K8s with Helm using image tag: ${APP_VERSION}"
                        def DOCKER_REGISTRY = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                        sh """
                            helm upgrade --install ${HELM_RELEASE_NAME} ${HELM_CHART_PATH} \\
                               --namespace ${K8S_NAMESPACE} \\
                               --set image.repository=${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME} \\
                               --set image.tag=${APP_VERSION} \\
                               --set imagePullSecrets[0].name=${K8S_PULL_SECRET_NAME} \\
                               --wait --atomic
                        """

                        echo 'Helm deployment complete!'
                    }
                }
            }
        }

        stage('Verify Application') {
            steps {
                container('kubectl') {
                    script {
                        echo 'Performing application verification...'

                        def nodeIp = sh(returnStdout: true, script: "kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type==\"InternalIP\")].address}'").trim()
                        def nodePort = sh(returnStdout: true, script: "kubectl get service ${HELM_RELEASE_NAME}-${HELM_CHART_NAME} -n ${K8S_NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}'").trim()
                        def appUrl = "http://${nodeIp}:${nodePort}"

                        echo "Curling application at ${appUrl}..."
                        retry(10) {
                            timeout(time: 90, unit: 'SECONDS') {
                                sh "curl -f --max-time 10 ${appUrl}"

                                sh "curl -f ${appUrl} | grep 'Hello, World!'"
                            }
                        }
                        echo 'Application verification successful!'
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
            sh "rm -f /home/jenkins/.kube/config"
        }
        success {
            echo 'Pipeline succeeded! Sending success notification.'
            slackSend (
                color: 'good',
                message: "SUCCESS: Pipeline `${env.JOB_NAME}` build `${env.BUILD_NUMBER}` for `${env.DOCKER_IMAGE_NAME}` completed successfully. <${env.BUILD_URL}|Open Build>"
            )
        }
        failure {
            echo 'Pipeline failed! Sending failure notification.'
            slackSend (
                color: 'danger',
                message: "FAILURE: Pipeline `${env.JOB_NAME}` build `${env.BUILD_NUMBER}` for `${env.DOCKER_IMAGE_NAME}` *FAILED*. <${env.BUILD_URL}|Open Build>"
            )
        }
    }
}
