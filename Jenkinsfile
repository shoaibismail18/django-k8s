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
                        sh 'pip install -r requirements.txt pytest pytest-django pytest-cov'

                        // Create reports directory
                        sh 'mkdir -p reports'

                        // Run tests with junit xml report and coverage xml report
                        sh 'pytest --junitxml=reports/pytest-results.xml --cov=. --cov-report=xml:reports/coverage.xml'
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            environment {
                SONAR_SCANNER_OPTS = """
                    -Dsonar.projectKey=django-k8s \
                    -Dsonar.sources=. \
                    -Dsonar.python.version=3.10 \
                    -Dsonar.python.xunit.reportPath=reports/pytest-results.xml \
                    -Dsonar.python.coverage.reportPath=reports/coverage.xml
                """
            }
            steps {
                withSonarQubeEnv('sonarscanner') {
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        sh "/opt/sonar-scanner/bin/sonar-scanner -Dsonar.login=$SONAR_TOKEN $SONAR_SCANNER_OPTS"
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
