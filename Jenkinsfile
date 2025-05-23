pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "shoaibismail18/django-k8s:17"
        SONAR_PROJECT_KEY = "django-k8s"
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

        stage('Install Dependencies, Test & Coverage') {
            steps {
                script {
                    docker.image('python:3.10-slim').inside('-u root') {
                        sh '''
                            python -m pip install --upgrade pip
                            pip install -r requirements.txt pytest pytest-django coverage
                            coverage run -m pytest
                            coverage xml
                        '''
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    script {
                        docker.image('python:3.10-slim').inside('-u root') {
                            sh """
                                python -m pip install --upgrade pip
                                pip install sonar-scanner
                                sonar-scanner \
                                    -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                                    -Dsonar.sources=. \
                                    -Dsonar.python.coverage.reportPaths=coverage.xml
                            """
                        }
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
    }
}
