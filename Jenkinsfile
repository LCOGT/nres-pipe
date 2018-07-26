#!/usr/bin/env groovy

@Library('lco-shared-libs@feature/docker_cp') _

pipeline {
	agent any
	environment {
		dockerImage = null
		PROJ_NAME = projName()
		GIT_DESCRIPTION = gitDescribe()
		DOCKER_IMG = dockerImageName("${LCO_DOCK_REG}", "${PROJ_NAME}", "${GIT_DESCRIPTION}")
	}
	options {
		timeout(time: 12, unit: 'HOURS')
		lock resource: 'IDLLock'
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
		stage('DeployTestStack') {
			when {
				anyOf {
					branch 'PR-*'
					expression { return params.forceEndToEnd }
				}
			}
			environment {
				RANCHERDEV_CREDS = credentials('rancher-cli-dev')
			}
			steps {
				script {
					withCredentials([usernamePassword(
							credentialsId: 'rabbit-mq',
							usernameVariable: 'RABBITMQ_USER',
							passwordVariable: 'RABBITMQ_PASSWORD')]) {
						sh('rancher -c ${RANCHERDEV_CREDS} rm --stop --type stack NRESPipelineTest ')
						sh('rancher -c ${RANCHERDEV_CREDS} up --stack NRESPipelineTest --force-upgrade --confirm-upgrade -d')
					}
				}
			}
		}
		stage('Test') {
			when {
				anyOf {
					branch 'PR-*'
					expression { return params.forceEndToEnd }
				}
			}
			environment {
				RANCHERDEV_CREDS = credentials('rancher-cli-dev')
				SSH_CREDS = credentials('jenkins-rancher-ssh-userpass')
				CONTAINER_ID = getContainerId('NRESPipelineTest-NRESPipelineTest-1')
				CONTAINER_HOST = getContainerHostName('NRESPipelineTest-NRESPipelineTest-1')
				ARCHIVE_UID = credentials('archive-userid')
			}
			steps {
				script {
					sshagent(credentials: ['jenkins-rancher-ssh']) {
						executeOnRancher('pytest --durations=0 --junitxml=/nres/code/pytest.xml -m e2e /nres/code/',
						    CONTAINER_HOST, CONTAINER_ID, ARCHIVE_UID)
					    copyFromRancherContainer('/nres/code/pytest.xml', 'pytest.xml', CONTAINER_HOST, CONTAINER_ID)
					}
				}
			}
			post {
                always { junit 'pytest.xml' }
				success {
					script {
						sh('rancher -c ${RANCHERDEV_CREDS} rm --stop --type stack NRESPipelineTest ')
					}
				}
			}
		}
	}
}
