pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "shoaibismail18/django-k8s:${BUILD_NUMBER}"
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
            environment {
                GIT_REPO_NAME = "django-k8s"
                GIT_USER_NAME = "shoaibismail18"
            }
            steps {
                withCredentials([string(credentialsId: 'github', variable: 'GITHUB_TOKEN')]) {
                    sh '''
                        git config user.email "shoaibismail18@gmail.com"
                        git config user.name "Shoaib Ismail"
                        git checkout main
                        sed -i "s/replaceImageTag/${BUILD_NUMBER}/g" k8s/deployment.yml
                        git add k8s/deployment.yml
                        git commit -m "Update deployment image to version ${BUILD_NUMBER}" || echo "No changes to commit"
                        git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME}.git HEAD:main
                    '''
                }
            }
        }
    }
}
