pipeline {
    agent any

    stages {
        stage('Preparation') {
            steps {
                // Get some code from a GitHub repository
                git 'https://github.com/vito-royeca/ManaGuide-maintainer.git'
            }
        }
        stage('Build') {
            environment {
                SWIFTLY_HOME_DIR = '/mnt/datadrv/bin/swiftly'
                SWIFTLY_BIN_DIR = '/mnt/datadrv/bin/swiftly/bin'
            }
            steps {
                echo 'Building..'
                sh '$SWIFTLY_BIN_DIR/swift build -c release'
            }
        }
        stage('Run') {
            environment {
                HOST = credentials('managuide-host')
                PORT = credentials('managuide-port')
                DATABASE = credentials('managuide-database')
                FULL_UPDATE = credentials('managuide-fullUpdate')
                IMAGES_PATH = credentials('managuide-imagesPath')
                IMAGES_OWNER = credentials('managuide-imagesOwner')
            }
            steps {
                echo 'Running..'
                withCredentials([usernamePassword(credentialsId: 'managuide-user', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh 'sudo -u $IMAGES_OWNER sh -c ".build/release/managuide \
                        --host $HOST \
                        --port $PORT \
                        --database $DATABASE \
                        --user $USERNAME \
                        --password $PASSWORD \
                        --full-update $FULL_UPDATE \
                        --images-path $IMAGES_PATH"'
                }
            }
        }
    }
}
