pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'supriya9606/task-manager-api'
        K8S_NAMESPACE = 'task-manager'
        K8S_CONFIG = '/tmp/jenkins-kubeconfig'
    }

    stages {
        stage('Git Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Running Python tests...'
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    python -m pytest tests/ -v
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    env.IMAGE_TAG = "${BUILD_NUMBER}"
                }

                echo 'Building Docker image...'
                sh '''
                    docker build \
                      -t ${DOCKER_IMAGE}:${IMAGE_TAG} \
                      -t ${DOCKER_IMAGE}:latest .
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USER',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        set +x
                        echo "$DOCKERHUB_TOKEN" | docker login \
                          --username "$DOCKERHUB_USER" \
                          --password-stdin

                        docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
                        docker push ${DOCKER_IMAGE}:latest

                        docker logout
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    set -e

                    echo "Checking Kubernetes connection..."
                    kubectl get nodes --kubeconfig="${K8S_CONFIG}"

                    echo "Restarting Task Manager API deployment..."
                    kubectl rollout restart deployment/task-manager-api \
                      -n "${K8S_NAMESPACE}" \
                      --kubeconfig="${K8S_CONFIG}"

                    echo "Waiting for deployment rollout..."
                    kubectl rollout status deployment/task-manager-api \
                      -n "${K8S_NAMESPACE}" \
                      --timeout=120s \
                      --kubeconfig="${K8S_CONFIG}"

                    echo "Checking deployment status..."
                    kubectl get pods -n "${K8S_NAMESPACE}" \
                      --kubeconfig="${K8S_CONFIG}"

                    kubectl get services -n "${K8S_NAMESPACE}" \
                      --kubeconfig="${K8S_CONFIG}"
                '''
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution completed.'
        }

        success {
            echo 'CI/CD pipeline completed successfully!'
        }

        failure {
            echo 'Pipeline failed. Check Console Output for the failing stage.'
        }
    }
}
