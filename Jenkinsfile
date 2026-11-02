
pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'supriya9606/task-manager-api'
        DOCKER_TAG = 'latest'
        DOCKER_CREDENTIALS = 'dockerhub-credentials'
        ANSIBLE_INVENTORY = '/var/lib/jenkins/ansible-practice/inventory'
        ANSIBLE_KEY = '/var/lib/jenkins/.ssh/ansible-key.pem'
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
                echo 'Running tests with Python 3.12...'
                sh '''
                    docker run --rm \
                      -v "$WORKSPACE:/app" \
                      -w /app \
                      python:3.12-slim \
                      sh -c "pip install -r requirements.txt && python -m pytest tests/ -v"
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh '''
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo 'Pushing image to Docker Hub...'
                withCredentials([
                    usernamePassword(
                        credentialsId: "${DOCKER_CREDENTIALS}",
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login \
                          -u "$DOCKER_USER" --password-stdin

                        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}

                        docker logout
                    '''
                }
            }
        }

        stage('Deploy using Ansible') {
            steps {
                echo 'Deploying Task Manager API to EC2...'
                sh '''
                    ansible-playbook \
                      -i ${ANSIBLE_INVENTORY} \
                      deploy.yml \
                      --private-key=${ANSIBLE_KEY} \
                      -b
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                echo 'Checking API health...'
                sh '''
                    ansible webservers \
                      -i ${ANSIBLE_INVENTORY} \
                      -m uri \
                      -a "url=http://localhost:8000/health status_code=200" \
                      --private-key=${ANSIBLE_KEY} \
                      -b
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check Console Output.'
        }
        always {
            echo 'Pipeline execution completed.'
        }
    }
}
