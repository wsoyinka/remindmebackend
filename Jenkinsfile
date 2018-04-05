node {
    checkout scm
    
    try {
        stage 'Run unit/integration test'
        sh 'make test'
        
        stage 'Build application artifacts'
        sh 'make build'
        
        stage 'Create release env and run acceptance test'
        sh 'make release'
        
        stage 'Tag and publish release image'
        sh 'make tag latest \$(git rev-parse --short HEAD)  \$(git tag --points-at HEAD)'
        sh 'make buildtag master \$(git tag --points-at HEAD)'
        withEnv(["DOCKER)USER=${DOCKER_USER}",
                "DOCKER_PASSWORD=${DOCKER_PASSWORD}" ]) {
                    sh 'make login'
                }
        sh 'make publish'
    }
    
    finally {
        stage 'Collect test reports'
        step([$class: 'JUnitResultArchiver', testResults: '**/reports/*.xml'])
        
        stage 'Clean Up after ourselves'
        sh 'make clean'
        sh 'make logout'
    }
}
