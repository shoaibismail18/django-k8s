pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "shoaibismail18/django-k8s:17"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: 'main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/shoaibismail18/django-k8s',
                        credentialsId: 'GitHub_credentials'
                    ]]
                ])
            }
        }

        stage('Install Dependencies & Test') {
            steps {
                script {
                    docker.image('python:3.10-slim').inside('-u root') {
                        sh 'python -m pip install --upgrade pip'
                        sh 'pip install -r requirements.txt pytest pytest-django'
                        sh 'pytest'
                    }
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-django-k8s', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
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
                sh '''
                    if [ -f deployment.yaml ]; then
                        sed -i 's|image: shoaibismail18/django-k8s:.*|image: ${DOCKER_IMAGE}|' deployment.yaml
                        echo "Updated deployment.yaml:"
                        cat deployment.yaml
                    else
                        echo "ERROR: deployment.yaml not found!"
                        exit 1
                    fi
                '''
            }
        }
    }
}
