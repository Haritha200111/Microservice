pipeline {
    agent any

    environment {
        REGISTRY = "docker.io/haritharavichandran" // Docker Hub username
        DOCKER_CREDS = credentials('dockerhub-creds') // Jenkins Docker Hub credentials ID
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
    }

    stages {
        stage('Detect Changed Services') {
            steps {
                script {
                    changedFiles = sh(script: "git diff --name-only HEAD~1 HEAD", returnStdout: true).trim().split("\n")
                    changedServices = changedFiles
                        .findAll { it.startsWith("services/") }
                        .collect { it.split("/")[1] }
                        .unique()
                    echo "Changed services: ${changedServices}"
                }
            }
        }

        stage('Build and Push Images') {
            when {
                expression { changedServices && changedServices.size() > 0 }
            }
            steps {
                script {
                    docker.withRegistry("https://${REGISTRY}", "${DOCKER_CREDS}") {
                        changedServices.each { service ->
                            sh """
                                docker build -t ${REGISTRY}/${service}:${GIT_COMMIT_SHORT} ./services/${service}
                                docker push ${REGISTRY}/${service}:${GIT_COMMIT_SHORT}
                            """
                        }
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when {
                expression { changedServices && changedServices.size() > 0 }
            }
            steps {
                script {
                    changedServices.each { service ->
                        sh """
                            helm upgrade --install ${service} ./helm/${service} \
                            --set image.repository=${REGISTRY}/${service} \
                            --set image.tag=${GIT_COMMIT_SHORT}
                        """
                    }
                }
            }
        }
    }
}
