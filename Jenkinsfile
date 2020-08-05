def expandEnvAndAppend(fileIn, fileOut) {
    def uid = sh(returnStdout: true, script: 'echo $UID').trim()
    def gid = sh(returnStdout: true, script: 'id -G | awk \'{print $1}\'').trim()
    sh "JENKINS_UID=$uid JENKINS_GID=$gid" + ' perl -p -e \'s/\\$\\{([^}]+?)\\}/defined $ENV{$1} ? $ENV{$1} : $&/eg; s/\\$\\{([^}]+?)\\}//eg\'' + "< $fileIn >> $fileOut"
}

def build(platform, compiler) {
    node (platform) { timeout(30) {
        try { timestamps { ansiColor('xterm') {
            step([$class: 'WsCleanup'])

            def workspace = pwd()

            sh 'git clone --recursive git://gitlab.ozlabs.ibm.com/jenkins-ci/openssl-build-script.git'

            dockerContainer = 'openssl'
            expandEnvAndAppend('openssl-build-script/ubuntu-20.04.docker', 'Dockerfile')
            docker.build dockerContainer

            docker.image(dockerContainer).inside {
                checkout scm

                sh "cd openssl && PREFIX=openssl make -j\$(nproc) all install"

                sh "cd openssl && tar jcf ../openssl.tbz openssl"
                archiveArtifacts fingerprint: true, artifacts: 'openssl.tbz'

                warnings canComputeNew: false, canResolveRelativePaths: false, consoleParsers: [[parserName: 'GNU Make + GNU C Compiler (gcc)']], defaultEncoding: '', excludePattern: '', healthy: '', includePattern: '', messagesPattern: '', unHealthy: ''
            }
        }}} // wrap, timestamps, try
        finally {
//            step([$class: 'WsCleanup'])
        }
    }} // timeout, node
}


def configs = []
configs.add('x86_64');

def builds = [:]
for (config in configs) {
    builds['build-' + config] = {build(config)}
}

stage('build') {
    parallel builds
}
