pipeline {
    agent any

    environment {
        REGISTRY = "docker.io/haritharavichandran" // Docker Hub username
        DOCKER_CREDS = credentials('dockerhub-creds') // Jenkins credentials ID for Docker Hub
        GIT_COMMIT_SHORT = '' // Will be populated dynamically
    }

    stages {

        stage('Get Short Commit Hash') {
            steps {
                script {
                    def commitHash = bat(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.GIT_COMMIT_SHORT = commitHash
                    echo "Short commit hash: ${env.GIT_COMMIT_SHORT}"
                }
            }
        }

        stage('Detect Changed Services') {
            steps {
                script {
                    // Fetch the origin branch to compare against
                    bat 'git fetch origin'

                    // Use git diff against origin/main
                    def changedFilesRaw = bat(script: 'git diff --name-only origin/main...HEAD', returnStdout: true).trim()
                    echo "Raw changed files:\n${changedFilesRaw}"

                    def changedFiles = changedFilesRaw.tokenize('\r\n')
                    def changedServices = changedFiles
                        .findAll { it.startsWith("services/") }
                        .collect { it.split("/")[1] }
                        .unique()

                    env.CHANGED_SERVICES = changedServices.join(',')
                    echo "Changed services: ${env.CHANGED_SERVICES}"
                }
            }
        }

        stage('Build and Push Images') {
            when {
                expression { env.CHANGED_SERVICES && env.CHANGED_SERVICES != '' }
            }
            steps {
                script {
                    def services = env.CHANGED_SERVICES.tokenize(',')

                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_HUB_USER', passwordVariable: 'DOCKER_HUB_PSW')]) {
                        // Login to Docker
                        bat """
                            echo %DOCKER_HUB_PSW% | docker login -u %DOCKER_HUB_USER% --password-stdin
                        """

                        // Loop through changed services
                        services.each { service ->
                            def imageName = "${env.REGISTRY}/${service}:${env.GIT_COMMIT_SHORT}"
                            echo "Building and pushing image for service: ${service}"

                            bat """
                                docker build -t ${imageName} .\\services\\${service}
                                docker push ${imageName}
                            """
                        }

                        // Logout
                        bat "docker logout"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when {
                expression { env.CHANGED_SERVICES && env.CHANGED_SERVICES != '' }
            }
            steps {
                script {
                    def services = env.CHANGED_SERVICES.tokenize(',')
                    services.each { service ->
                        echo "Deploying ${service} using Helm"

                        bat """
                            helm upgrade --install ${service} .\\helm\\${service} ^
                            --set image.repository=${env.REGISTRY}/${service} ^
                            --set image.tag=${env.GIT_COMMIT_SHORT}
                        """
                    }
                }
            }
        }
    }
}
