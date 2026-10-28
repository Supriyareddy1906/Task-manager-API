pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Run Tests with Python 3.12') {
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
    }

    post {
        success {
            echo 'Task Manager API pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check the Console Output.'
        }
        always {
            echo 'Pipeline execution finished.'
        }
    }
}
