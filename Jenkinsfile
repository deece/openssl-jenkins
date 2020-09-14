def expandEnvAndAppend(fileIn, fileOut) {
    def uid = sh(returnStdout: true, script: 'echo $UID').trim()
    def gid = sh(returnStdout: true, script: 'id -G | awk \'{print $1}\'').trim()
    sh "JENKINS_UID=$uid JENKINS_GID=$gid" + ' perl -p -e \'s/\\$\\{([^}]+?)\\}/defined $ENV{$1} ? $ENV{$1} : $&/eg; s/\\$\\{([^}]+?)\\}//eg\'' + "< $fileIn >> $fileOut"
}

def stderrInRed(cmd) {
     sh 'bash -c \'' + cmd + ' 2> >(while read line; do echo -e "\\e[01;31m$line\\e[0m" >&2; done)\''
}


def build(platform) {
	checkout scm
            
	def prefix = 'openssl'
    stderrInRed('mkdir ' + prefix)
            
	if (platform == "x86_64") {
		sh "./Configure --prefix=`pwd`/" + prefix + ' -Wall -Wextra -pg linux-x86_64'            	                    
    }  else if (platform == "ppc64le") {
		sh "./Configure --prefix=`pwd`/" + prefix + ' -Wall -Wextra -pg linux-ppc64le'
    }

    stderrInRed('make -j$(nproc)')
    stderrInRed('make install')
    def tarballProfiled = 'openssl-' + platform + '-profiled.tbz'
	stderrInRed('tar jcf ' + tarballProfiled + ' ' + prefix)
	
	sh 'rm -rf ' + prefix
	
	if (platform == "x86_64") {
		sh "./Configure --prefix=`pwd`/" + prefix + ' linux-x86_64'            	                    
    } else if (platform == "ppc64le") {
		sh "./Configure --prefix=`pwd`/" + prefix + ' linux-ppc64le'
    }

    stderrInRed('make -j$(nproc)')
    stderrInRed('make install')
    def tarball = 'openssl-' + platform + '.tbz'
	stderrInRed('tar jcf ' + tarball + ' ' + prefix)

    archiveArtifacts fingerprint: true, artifacts: tarball
    archiveArtifacts fingerprint: true, artifacts: tarballProfiled
    stash name: tarballProfiled, includes: tarballProfiled
    stash name: tarball, includes: tarball
    
    try {
		stderrInRed('make test VF=1')
		// Todo: Parse test results
    } catch (ex) {
		unstable('tests failed');
    }

    recordIssues enabledForFailure: true, aggregatingResults: true, tools: [gcc(id: "${platform}_gcc")]
}

def buildInDocker(platform) {
    timeout(30) {
        ansiColor('xterm') {
            step([$class: 'WsCleanup'])

            def workspace = pwd()

            sh 'git clone --depth 1 https://github.com/deece/openssl-jenkins.git'

            def dockerContainer = 'openssl'
            expandEnvAndAppend('openssl-jenkins/Dockerfile.build', 'Dockerfile')
            docker.build dockerContainer

            docker.image(dockerContainer).inside {
            	build(platform)
            }
        } // ansicolor        
    } // timeout
    
    step([$class: 'WsCleanup'])
}

algs = [
// 		'nistp192',
//		'nistp224',
		'nistp256',
		'nistp384',
		'nistp521',
//		'nistk163',
//		'nistk233',
//		'nistk283',
//		'nistk409',
//		'nistk571',
//		'nistb163',
//		'nistb233',
//		'nistb283',
//		'nistb409',
//		'nistb571'
]
    
funcs = ['ecdsa', 'ecdh' ]

def benchmark(platform) {
	def tarballProfiled = 'openssl-' + platform + '-profiled.tbz'
	unstash tarballProfiled
	stderrInRed('tar jxf ' + tarballProfiled)
        
	dir('openssl') {
 		for (func in funcs) {
 			for (alg in algs) {
 				alg = alg.replace('nist', '');
				def combo = func + alg

    	    	sh 'LD_LIBRARY_PATH=lib bin/openssl speed \'' + combo + '\' | tee -a results.txt'
	
				def profile = 'openssl-' + platform + '-' + combo + '.gprof'
				sh 'gprof bin/openssl > ' + profile
				archiveArtifacts fingerprint: true, artifacts: profile
			}
		}

    	sh 'git clone --depth 1 https://github.com/deece/openssl-jenkins.git'        
    	stderrInRed('perl -n openssl-jenkins/benchmark-parser.pl results.txt > results.csv')
		sh 'cat results.csv'
			
//		perfReport 'results.csv'
	}
}

def benchmarkInDocker(platform) {
	try {
	    sh 'git clone --depth 1 https://github.com/deece/openssl-jenkins.git'
		def dockerContainer = 'openssl'
		expandEnvAndAppend('openssl-jenkins/Dockerfile.build', 'Dockerfile')
		docker.build dockerContainer

		docker.image(dockerContainer).inside {
			benchmark(platform)
		}
	} finally {
    	step([$class: 'WsCleanup'])
	}
}

def callgrind(platform) {
   	def tarball = 'openssl-' + platform + '.tbz'
	unstash tarball
	stderrInRed('tar jxf ' + tarball)
        
	dir('openssl') {
		for (func in funcs) {
			for (alg in algs) {
				alg = alg.replace('nist', '');
				def combo = func + alg

    	    	sh 'LD_LIBRARY_PATH=lib valgrind --tool=callgrind --cache-sim=yes bin/openssl speed \'' + combo + '\''
    			def cg = 'callgrind-' + platform + '-' + combo
				sh 'mv callgrind.out.* ' + cg
				sh 'callgrind_annotate ' + cg
				
				archiveArtifacts fingerprint: true, artifacts: cg
			}
	    }
    }
}

def callgrindInDocker(platform) {
	try {
	    sh 'git clone --depth 1 https://github.com/deece/openssl-jenkins.git'
		def dockerContainer = 'openssl'
		expandEnvAndAppend('openssl-jenkins/Dockerfile.build', 'Dockerfile')
		docker.build dockerContainer

		docker.image(dockerContainer).inside {
			callgrind(platform)
		}
	} finally {
    	step([$class: 'WsCleanup'])
	}
}

pipeline {
	agent any
	options {
		buildDiscarder(logRotator(numToKeepStr: '5'))
		timestamps()
	}
	stages {
		stage('build') {
		    parallel {
				stage('build on x86_64') {
					agent {
						label 'x86_64'
		       		}
   					steps {
						buildInDocker('x86_64')
   					}
                }
				stage('build on ppc64le') {
					agent {
						label 'ppc64le'
		       		}
   					steps {
						buildInDocker('ppc64le')
   					}
                }
		    }
		}
		stage('benchmark') {
		    parallel {
				stage('benchmark on x86_64') {
					agent {
						label 'x86_64'
		       		}
   					steps {
						benchmarkInDocker('x86_64')					    
   					}
                }
				stage('callgrind on x86_64') {
					agent {
						label 'x86_64'
		       		}
   					steps {
						callgrindInDocker('x86_64')					    
   					}
                }
				stage('benchmark on ppc64le') {
					agent {
						label 'ppc64le'           
		       		}
   					steps {
						benchmarkInDocker('ppc64le')					    
   					}
                }
				stage('callgrind on ppc64le') {
					agent {
						label 'ppc64le'      
		       		}
   					steps {
						callgrindInDocker('ppc64le')					    
   					}
                }                
		    }
		}
	}
}

