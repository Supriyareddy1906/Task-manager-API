pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Run Tests') {
            agent {
                docker {
                    image 'python:3.12-slim'
                    reuseNode true
                }
            }

            environment {
                HOME = "${WORKSPACE}"
                PIP_CACHE_DIR = "${WORKSPACE}/.pip-cache"
            }

            steps {
                sh 'python --version'
                sh 'python -m pip install -r requirements.txt'
                sh 'python -m pytest tests/ -v'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t supriya9606/task-manager-api:latest .'
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        set +x
                        echo "$DOCKERHUB_TOKEN" | docker login \
                            -u "$DOCKERHUB_USERNAME" \
                            --password-stdin

                        docker push supriya9606/task-manager-api:latest

                        docker logout
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: Tests passed, Docker image built and pushed to Docker Hub!'
        }

        failure {
            echo 'FAILED: Check the Console Output for the error.'
        }

        always {
            echo 'Pipeline execution finished.'
        }
    }
}
