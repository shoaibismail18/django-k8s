pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "shoaibismail18/django-k8s:17"
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials-id'  // replace with your Jenkins Docker credentials ID
        GIT_CREDENTIALS_ID = 'GitHub_credentials'           // your GitHub credentials ID
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: 'main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/shoaibismail18/django-k8s',
                        credentialsId: "${GIT_CREDENTIALS_ID}"
                    ]]
                ])
            }
        }

        stage('Install Dependencies & Test') {
            steps {
                script {
                    docker.image('python:3.10-slim').inside {
                        sh 'python -m pip install --upgrade pip'
                        sh 'pip install -r requirements.txt pytest pytest-django'
                        sh 'pytest'
                    }
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker build -t ${DOCKER_IMAGE} .
                        docker push ${DOCKER_IMAGE}
                        docker logout
                    '''
                }
            }
        }

        stage('Update Deployment File') {
            steps {
                // Checkout again to ensure deployment.yaml is present
                checkout scm

                sh """
                   sed -i 's|image: shoaibismail18/django-k8s:.*|image: ${DOCKER_IMAGE}|' deployment.yaml
                """

                // Optional: show updated deployment.yaml contents
                sh 'cat deployment.yaml'
            }
        }
    }
}
