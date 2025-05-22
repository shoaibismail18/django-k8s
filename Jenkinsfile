pipeline {
    agent {
        docker {
            image 'python:3.9-slim'
            args '-u root -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    
    environment {
        SONAR_HOST_URL = "http://172.26.143.43:9000"
        DOCKER_REGISTRY = "your-docker-registry"
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', 
                url: 'https://github.com/your-org/django-app.git',
                credentialsId: 'github'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                apt-get update && apt-get install -y curl unzip
                pip install --upgrade pip
                pip install -r requirements.txt
                pip install coverage
                '''
            }
        }

        stage('Run Tests with Coverage') {
            steps {
                sh '''
                coverage run --source=. manage.py test
                coverage xml
                '''
            }
        }

        stage('SonarQube Analysis') {
            environment {
                SCANNER_VERSION = "5.0.1.3006"
            }
            steps {
                withCredentials([string(credentialsId: 'sonarqube', variable: 'SONAR_TOKEN']) {
                    sh '''
                    # Install SonarScanner with Node.js dependency
                    curl -sSLo sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SCANNER_VERSION}-linux.zip
                    unzip -q sonar-scanner.zip
                    rm sonar-scanner.zip
                    
                    # Install Node.js for JavaScript analysis
                    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
                    apt-get install -y nodejs

                    # Run SonarScanner with correct parameters
                    ./sonar-scanner-${SCANNER_VERSION}-linux/bin/sonar-scanner \
                      -Dsonar.projectKey=django-k8s \
                      -Dsonar.sources=. \
                      -Dsonar.host.url=${SONAR_HOST_URL} \
                      -Dsonar.token=${SONAR_TOKEN} \
                      -Dsonar.coverageReportPaths=coverage.xml \
                      -Dsonar.exclusions=**/sonar-scanner-*,**/*.zip,**/jre/**/*
                    '''
                }
            }
        }

        stage('Build and Push Docker Image') {
            environment {
                DOCKER_IMAGE = "${env.DOCKER_REGISTRY}/django-app:${env.BUILD_NUMBER}"
            }
            steps {
                script {
                    docker.build("${env.DOCKER_IMAGE}") {
                        sh '''
                        python manage.py collectstatic --noinput
                        python manage.py migrate
                        '''
                    }
                    docker.withRegistry("https://${env.DOCKER_REGISTRY}", 'docker-creds') {
                        docker.image("${env.DOCKER_IMAGE}").push()
                    }
                }
            }
        }
    }
    
    post {
        always {
            sh 'docker system prune -f'
            cleanWs()
        }
        failure {
            slackSend channel: '#build-errors',
                     color: 'danger',
                     message: "Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
    }
}