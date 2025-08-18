pipeline {
    agent any

    environment {
        REGISTRY = "docker.io/haritharavichandran"
    }

    stages {
stage('Get short commit hash') {
    steps {
        script {
            def raw = bat(
                script: "git rev-parse --short HEAD",
                returnStdout: true
            ).trim()

            // On Windows bat, output includes the command itself on the first line
            def lines = raw.readLines()
            GIT_COMMIT_SHORT = lines[-1].trim()   // ✅ take only the last line

            echo "Short commit hash: ${GIT_COMMIT_SHORT}"
        }
    }
}


        stage('Detect Changed Services') {
            steps {
                script {
                    def changedFiles = []
                    for (changeLogSet in currentBuild.changeSets) {
                        for (entry in changeLogSet.items) {
                            for (file in entry.affectedFiles) {
                                changedFiles << file.path
                            }
                        }
                    }

                    echo "Changed files: ${changedFiles}"

                    def changedServices = changedFiles
                        .findAll { it.startsWith("services/") }
                        .collect { it.split('/')[1] }
                        .unique()

                    CHANGED_SERVICES = changedServices.join(',')
                    echo "Changed services: ${CHANGED_SERVICES}"
                }
            }
        }

stage('Build and Push Images') {
    when {
        expression { return CHANGED_SERVICES?.trim() }
    }
    steps {
        script {
            def services = CHANGED_SERVICES.tokenize(',')
            withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_HUB_USER', passwordVariable: 'DOCKER_HUB_PSW')]) {
                bat "docker login -u %DOCKER_HUB_USER% -p %DOCKER_HUB_PSW%"
                services.each { service ->
                    def imageName = "${REGISTRY}/${service}:${GIT_COMMIT_SHORT}"
                    echo "Building image: ${imageName}"
                    bat "docker build -t ${imageName} services\\${service}"
                    bat "docker push ${imageName}"
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
            echo "CHANGED_SERVICES: '${env.CHANGED_SERVICES}'"
            def services = env.CHANGED_SERVICES.tokenize(',')
            echo "Parsed services: ${services}"

            services.each { service ->
                echo "Deploying service: ${service}"
                bat """
                    helm upgrade --install ${service} .\\services\\helm\\${service} ^
                    --set image.repository=${REGISTRY}/${service} ^
                    --set image.tag=${GIT_COMMIT_SHORT}
                """
            }
        }
    }
}

    }
}

def GIT_COMMIT_SHORT = ''
def CHANGED_SERVICES = ''
