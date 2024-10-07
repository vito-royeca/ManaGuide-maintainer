pipeline {
    agent any

    environment {
        SWIFT_PATH = '/opt/swiftlang-5.9.1-debian-12-release-arm64/usr/bin'
    }

    stages {
        stage('Preparation') { // for display purposes
            steps {
                // Get some code from a GitHub repository
                git 'https://github.com/vito-royeca/ManaGuide-maintainer.git'
            }
        }
        stage('Build') {
            steps {
                sh '$SWIFT_PATH/swift build -c release'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
    }
}
