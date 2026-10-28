pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'supriya9606/task-manager-api'
        K8S_NAMESPACE = 'task-manager'
        K8S_DEPLOYMENT = 'task-manager-api'
        K8S_CONTAINER = 'task-manager-api'
        KUBECONFIG_FILE = '/var/jenkins_home/.kube/deploy-config'
    }

    stages {

        stage('Git Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                    set -eu

                    echo "Checking project files..."
                    ls -l requirements.txt
                    ls -ld tests

                    docker run --rm \
                      --mount type=bind,source="$WORKSPACE",target=/app \
                      --workdir /app \
                      --entrypoint sh \
                      python:3.12-slim \
                      -c 'ls -l requirements.txt && pip install --no-cache-dir -r requirements.txt && python -m pytest tests/ -v'
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -eu

                    docker build \
                      -t "$DOCKER_IMAGE:$BUILD_NUMBER" \
                      -t "$DOCKER_IMAGE:latest" .
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        set +x
                        set -eu

                        echo "$DOCKER_PASSWORD" | docker login \
                          --username "$DOCKER_USER" \
                          --password-stdin

                        docker push "$DOCKER_IMAGE:$BUILD_NUMBER"
                        docker push "$DOCKER_IMAGE:latest"

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
                        set -eu

                        kubectl --kubeconfig="$KUBECONFIG_FILE" \
                          config set-credentials jenkins-deployer \
                          --token="$K8S_TOKEN"

                        echo "Checking Kubernetes connection..."

                        kubectl --kubeconfig="$KUBECONFIG_FILE" \
                          get deployment "$K8S_DEPLOYMENT" \
                          -n "$K8S_NAMESPACE"

                        echo "Deploying image..."

                        kubectl --kubeconfig="$KUBECONFIG_FILE" \
                          set image deployment/"$K8S_DEPLOYMENT" \
                          "$K8S_CONTAINER=$DOCKER_IMAGE:$BUILD_NUMBER" \
                          -n "$K8S_NAMESPACE"

                        echo "Waiting for rollout..."

                        kubectl --kubeconfig="$KUBECONFIG_FILE" \
                          rollout status deployment/"$K8S_DEPLOYMENT" \
                          -n "$K8S_NAMESPACE" \
                          --timeout=180s

                        echo "Deployment completed successfully."
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }

        failure {
            echo 'Pipeline failed. Check the failed stage in the console output.'
        }

        always {
            echo 'Pipeline execution finished.'
        }
    }
}