pipeline {
    agent any

    parameters {
        string(name: 'host', defaultValue: 'localhost', description: 'Database hostname or IP address')
        string(name: 'port', defaultValue: '5432', description: 'Database port')
        string(name: 'database', defaultValue: 'database', description: 'Database name')
        booleanParam(name: 'isFullUpdate', defaultValue: false, description: 'Perform a full update or not')
        string(name: 'imagesPath', defaultValue: '/mnt/managuide_images/cards', description: 'Path to the card image files')
        string(name: 'imagesOwner', defaultValue: 'user', description: 'User who has RW access to the card image files')
    }

    stages {
        stage('Preparation') {
            steps {
                // Get some code from a GitHub repository
                git 'https://github.com/vito-royeca/ManaGuide-maintainer.git'
            }
        }
        stage('Build') {
            steps {
                echo 'Building..'
                sh '~/.local/share/swiftly/bin/swift build -c release'
            }
        }
        stage('Run') {
            steps {
                environment {
                    HOST = ${params.host}
                    PORT = ${params.port}
                    DATABASE = ${params.database}
                    FULL_UPDATE = ${params.isFullUpdate}
                    IMAGES_PATH = ${params.imagesPath}
                    IMAGES_OWNER = ${params.imagesOwner}
                }

                echo 'Running...'
                withCredentials([usernamePassword(credentialsId: 'managuide-user', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh '''
                        sudo -u $IMAGES_OWNER sh -c ".build/release/managuide \
                            --host $HOST \
                            --port $PORT \
                            --database $DATABASE \
                            --user $USERNAME \
                            --password $PASSWORD \
                            --full-update $FULL_UPDATE \
                            --images-path $IMAGES_PATH"
                    '''
                }
            }
        }
    }
}
