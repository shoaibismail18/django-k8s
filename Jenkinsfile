pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "shoaibismail18/django-k8s:${env.BUILD_NUMBER}"
        K8S_MANIFEST = "k8s/deployment.yml"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/shoaibismail18/django-k8s.git',
                    credentialsId: 'GitHub_credentials'
            }
        }

        stage('Install Dependencies & Test') {
            agent {
                docker {
                    image 'python:3.10-slim'
                    args '-u root'  // removed docker.sock since not used here
                }
            }
            steps {
                sh '''
                apt-get update && apt-get install -y curl
                pip install --upgrade pip
                pip install -r requirements.txt pytest pytest-django
                pytest
                '''
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'DockerHub_creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                    docker login -u $DOCKER_USER -p $DOCKER_PASS
                    docker build -t $DOCKER_IMAGE .
                    docker push $DOCKER_IMAGE
                    docker logout
                    '''
                }
            }
        }

        stage('Update K8s Manifest') {
            steps {
                sh """
                sed -i "s|image: shoaibismail18/django-k8s:.*|image: ${DOCKER_IMAGE}|" ${K8S_MANIFEST}
                """
            }
        }

        stage('Commit and Push Changes') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'GitHub_credentials',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_PASS'
                )]) {
                    sh '''
                    git config user.email "jenkins@yourdomain.com"
                    git config user.name "Jenkins CI"
                    git fetch origin main
                    git reset --hard origin/main

                    git add ${K8S_MANIFEST}
                    git commit -m "CI: Update image to ${DOCKER_IMAGE}" || echo "No changes to commit"
                    git push https://${GIT_USER}:${GIT_PASS}@github.com/shoaibismail18/django-k8s.git main
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        failure {
            slackSend channel: '#build-failures',
                      color: 'danger',
                      message: "Build ${env.BUILD_NUMBER} failed: ${env.BUILD_URL}"
        }
    }
}
