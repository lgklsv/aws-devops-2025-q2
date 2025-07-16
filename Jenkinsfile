pipeline {
    agent any // or specify a Docker agent, a specific node label, etc.

    stages {
        stage('Build') {
            steps {
                echo 'Building the application...'
                // Add your application build commands here
            }
        }
        stage('Test') {
            steps {
                echo 'Running unit tests...'
                // Add your unit test commands here
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying to Kubernetes...'
                // Add your deployment commands here
            }
        }
    }
}