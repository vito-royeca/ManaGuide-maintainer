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
                APP_ENV = credentials('managuide-maintainer variables')
            }
            steps {
                echo 'Testing..'
                withCredentials([usernamePassword(credentialsId: 'managuide-maintainer-user', usernameVariable: 'username', passwordVariable: 'password')]) {
                    sh 'echo $username/$password'
  
                }
                // sh 'echo "APP_ENV is located at $APP_ENV"'
                // sh 'echo "host=$host"'
                // sh 'echo "port=$port"'
                // sh 'echo "database=$database"'
                // sh 'echo "user=$user"'
                // sh 'echo "password=$password"'
                // sh 'echo "fullUpdate=$fullUpdate"'
                // sh 'echo "imagesPath=$imagesPath"'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
    }
}
