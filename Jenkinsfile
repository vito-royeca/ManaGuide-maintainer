pipeline {
    agent any

    stages {
        stage('Preparation') { // for display purposes
            steps {
                // Get some code from a GitHub repository
                git 'https://github.com/vito-royeca/ManaGuide-maintainer.git'
            }
        }
        stage('Build') {
            environment {
                SWIFT_PATH = '/opt/swiftlang-5.9.1-debian-12-release-arm64/usr/bin'
            }
            steps {
                
                echo 'Building..'
                sh '$SWIFT_PATH/swift build -c release'
            }
        }
        stage('Test') {
            environment {
                HOST = credentials('managuide-host')
                PORT = credentials('managuide-port')
                DATABASE = credentials('managuide-database')
                FULL_UPDATE = credentials('managuide-fullUpdate')
                IMAGES_PATH = credentials('managuide-imagesPath')
            }
            steps {
                echo 'Testing..'
                withCredentials([usernamePassword(credentialsId: 'managuide-user', usernameVariable: 'username', passwordVariable: 'password')]) {
                    sh "echo $username/$password"
                    sh "echo host=$HOST"
                    sh "echo port=$PORT"
                    sh "echo database=$DATABASE"
                    sh "echo fullUpdate=$FULL_UPDATE"
                    sh "echo imagesPath=$IMAGES_PATH"  
                }
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
    }
}
