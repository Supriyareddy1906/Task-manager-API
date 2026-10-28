
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

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'k8s-deployer-token',
                        variable: 'K8S_TOKEN'
                    )
                ]) {
                    sh '''
                        set +x

                        kubectl \
                          --kubeconfig=/var/jenkins_home/.kube/config \
                          --namespace=task-manager \
                          get deployment task-manager-api

                        kubectl \
                          --kubeconfig=/var/jenkins_home/.kube/config \
                          --namespace=task-manager \
                          set image deployment/task-manager-api \
                          task-manager-api=supriya9606/task-manager-api:latest

                        kubectl \
                          --kubeconfig=/var/jenkins_home/.kube/config \
                          --namespace=task-manager \
                          rollout status deployment/task-manager-api \
                          --timeout=180s
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: Tests passed, image pushed, and Kubernetes deployment completed!'
        }

        failure {
            echo 'FAILED: Check the Console Output for the error.'
        }

        always {
            echo 'Pipeline execution finished.'
        }
    }
}
