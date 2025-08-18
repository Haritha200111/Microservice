pipeline {
    agent any

    environment {
        REGISTRY = "docker.io/haritharavichandran"
        DOCKER_CREDS = credentials('dockerhub-creds')
        GIT_COMMIT_SHORT = ''
        CHANGED_SERVICES = ''
    }

    stages {
        stage('Checkout SCM') {
            steps {
                // Checkout with full clone (disable shallow clone)
                checkout([$class: 'GitSCM',
                    branches: [[name: env.BRANCH_NAME]],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [[$class: 'CloneOption', noTags: false, shallow: false, depth: 0]],
                    userRemoteConfigs: [[url: 'your-repo-url']]
                ])
            }
        }

        stage('Get short commit hash') {
            steps {
                script {
                    GIT_COMMIT_SHORT = bat(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.GIT_COMMIT_SHORT = GIT_COMMIT_SHORT
                    echo "Short commit hash: ${GIT_COMMIT_SHORT}"
                }
            }
        }

        stage('Detect Changed Services') {
            steps {
                script {
                    // Fetch latest main branch to compare against
                    bat 'git fetch origin main'

                    // Get list of changed files compared to main branch
                    def changedFilesStr = bat(script: 'git diff --name-only origin/main...HEAD', returnStdout: true).trim()
                    def changedFiles = changedFilesStr ? changedFilesStr.split("\r\n") : []

                    echo "Changed files: ${changedFiles}"

                    // Extract changed services from paths
                    def changedServices = changedFiles
                        .findAll { it.startsWith("services/") }
                        .collect { it.split('/')[1] }
                        .unique()

                    CHANGED_SERVICES = changedServices.join(',')
                    env.CHANGED_SERVICES = CHANGED_SERVICES
                    echo "Changed services: ${CHANGED_SERVICES}"
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
                        bat """
                            echo %DOCKER_HUB_PSW% | docker login -u %DOCKER_HUB_USER% --password-stdin
                        """

                        services.each { service ->
                            def imageName = "${env.REGISTRY}/${service}:${env.GIT_COMMIT_SHORT}"
                            bat """
                                docker build -t ${imageName} .\\services\\${service}
                                docker push ${imageName}
                            """
                        }

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
