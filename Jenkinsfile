#!/usr/bin/env groovy

@Library('lco-shared-libs@0.0.2') _

def runRancherCommand(String serviceName, String command) {

    def DEV_CREDS = credentials('rancher-cli-dev')
    String container_json = sh(script: 'rancher -c '+ DEV_CREDS + ' inspect --format json ' + serviceName, returnStdout: true).trim()
    JsonSlurper slurper = new JsonSlurper()
    def container_info = slurper.parseText(container_json)
    def hostId = container_info.hostId
    String host_json = sh(script: 'rancher -c ${DEV_CREDS} inspect --format json --type host ' + hostId, returnStdout: true).trim()
    def host_info = slurper.parseText(host_json)
    def hostname = host_info.hostname

    sh('ssh ' + hostname + ' docker exec -i ' + container_info.externalID + ' ' + command)
}

pipeline {
	agent any
	environment {
		dockerImage = null
		PROJ_NAME = projName("${JOB_NAME}")
		GIT_DESCRIPTION = gitDescription()
		DOCKER_IMG = dockerImageName("${LCO_DOCK_REG}", "${PROJ_NAME}", "${GIT_DESCRIPTION}")
	}
	options {
		timeout(time: 3, unit: 'HOURS')
	}
	stages {
		stage('Build image') {
			steps {
				script {
					dockerImage = docker.build("${DOCKER_IMG}")
				}
			}
		}
		stage('Push image') {
			steps {
				script {
					dockerImage.push("${GIT_DESCRIPTION}")
				}
			}
		}
		stage('Deploy') {
			when {
				anyOf {
					branch 'PR-*'
					expression { return params.forceEndToEnd }
				}
			}
			environment {
				DEV_CREDS = credentials('rancher-cli-dev')
			}
			steps {
				script {
					withCredentials([usernamePassword(
							credentialsId: 'rabbit-mq',
							usernameVariable: 'RABBITMQ_USER',
							passwordVariable: 'RABBITMQ_PASSWORD')]) {
						sh('rancher -c ${DEV_CREDS} up --stack NRESPipelineTest --force-upgrade --confirm-upgrade -d')
						sh('echo "Got here".')
					}
				}
			}
		}
	    stage('Test'){
			when {
				anyOf {
					branch 'PR-*'
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {

					sshagent(credentials: ['jenkins-rancher-ssh']) {
						runRancherCommand('NRESPipelineTest', '/bin/true')
					}

				}
			}
	    }
	}
}
