pipeline {
    agent any

    parameters {
        string(name: 'host', defaultValue: 'localhost', description: 'Database hostname or IP address')
        string(name: 'port', defaultValue: '5432', description: 'Database port')
        string(name: 'databaseName', defaultValue: 'database', description: 'Database name')
        string(name: 'databaseUser', defaultValue: 'user', description: 'Database user')
        password(name: 'databasePassword', defaultValue: 'SECRET', description: 'Enter a password')
        booleanParam(name: 'isFullUpdate', defaultValue: false, description: 'Perform a full update or not')
        string(name: 'imagesPath', defaultValue: '/path/to/images/cards', description: 'Path to the card image files')
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
                echo 'Running..'
                sh 'sudo -u ${params.imagesOwner} sh -c ".build/release/managuide \
                    --host ${params.host} \
                    --port ${params.port} \
                    --database ${params.databaseName} \
                    --user ${params.databaseUser} \
                    --password ${params.databasePassword} \
                    --full-update ${params.isFullUpdate} \
                    --images-path ${params.imagesPath}"'
            }
        }
    }
}
