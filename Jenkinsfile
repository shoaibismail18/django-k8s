pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "shoaibismail18/django-k8s:${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies & Test') {
            agent {
                docker {
                    image 'python:3.10-slim'
                    args '--user root'
                }
            }
            steps {
                sh '''
                    python -m pip install --upgrade pip
                    pip install -r requirements.txt pytest pytest-django
                    pytest
                '''
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                withCredentials([string(credentialsId: 'docker-hub-token', variable: 'DOCKER_TOKEN')]) {
                    sh '''
                        echo "$DOCKER_TOKEN" | docker login -u shoaibismail18 --password-stdin
                        docker build -t $DOCKER_IMAGE .
                        docker push $DOCKER_IMAGE
                        docker logout
                    '''
                }
            }
        }

        stage('Update Deployment File') {
            steps {
                // Replace the image tag in deployment.yaml with the new Docker image
                sh """
                    sed -i 's|image: shoaibismail18/django-k8s:.*|image: $DOCKER_IMAGE|' deployment.yaml
                """
                // Optional: Show the updated deployment.yaml for confirmation
                sh "cat deployment.yaml"
            }
        }
    }
}
