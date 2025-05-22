pipeline {
  agent {
    docker {
      image 'python:3.10-slim'
      args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
    }
  }

  environment {
    DOCKER_IMAGE = "shoaibismail18/django-k8s:${BUILD_NUMBER}"
    GIT_REPO_NAME = "django-k8s"
    GIT_USER_NAME = "shoaibismail18"
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'main', url: 'https://github.com/shoaibismail18/django-k8s.git'
      }
    }

    stage('Install Dependencies & Test') {
      steps {
        sh '''
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install pytest pytest-django
          pytest
        '''
      }
    }

    stage('Build and Push Docker Image') {
      steps {
        withCredentials([string(credentialsId: 'docker-hub-token', variable: 'DOCKER_TOKEN')]) {
          script {
            def dockerImage = "${DOCKER_IMAGE}"
            sh """
              docker build -t ${dockerImage} .
              echo "${DOCKER_TOKEN}" | docker login -u shoaibismail18 --password-stdin
              docker push ${dockerImage}
              docker logout
            """
          }
        }
      }
    }

    stage('Update Deployment File') {
      steps {
        withCredentials([string(credentialsId: 'github', variable: 'GITHUB_TOKEN')]) {
          sh '''
            git config user.email "shoaib@example.com"
            git config user.name "Shoaib Ismail"
            sed -i "s/replaceImageTag/${BUILD_NUMBER}/g" k8s/deployment.yml
            git add k8s/deployment.yml
            git commit -m "Update deployment image to version ${BUILD_NUMBER}" || echo "No changes to commit"
            git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:main
          '''
        }
      }
    }
  }
}
