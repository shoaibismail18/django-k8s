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
                    if [ -f k8s/deployment.yml ]; then
                        sed -i "s|image: shoaibismail18/django-k8s:.*|image: ${DOCKER_IMAGE}|" k8s/deployment.yml
                        echo "Updated k8s/deployment.yml:"
                        cat k8s/deployment.yml
                    else
                        echo "ERROR: k8s/deployment.yml not found!"
                        exit 1
                    fi
                '''
            }
        }

        stage('Commit and Push Changes') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'GitHub_credentials', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                    sh '''
                        git config user.email "jenkins@yourdomain.com"
                        git config user.name "Jenkins CI"
                        git add k8s/deployment.yml
                        git commit -m "Update image tag to ${DOCKER_IMAGE}" || echo "No changes to commit"
                        git push https://${GIT_USER}:${GIT_PASS}@github.com/shoaibismail18/django-k8s.git main
                    '''
                }
            }
        }
    }
}
