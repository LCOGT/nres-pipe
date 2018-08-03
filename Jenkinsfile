#!/usr/bin/env groovy

@Library('lco-shared-libs@0.0.9') _

pipeline {
	agent any
	environment {
		dockerImage = null
		PROJ_NAME = projName()
		GIT_DESCRIPTION = gitDescribe()
		DOCKER_IMG = dockerImageName("${LCO_DOCK_REG}", "${PROJ_NAME}", "${GIT_DESCRIPTION}")
		RANCHERDEV_CREDS = credentials('rancher-cli-dev')
		SSH_CREDS = credentials('jenkins-rancher-ssh-userpass')
		ARCHIVE_UID = credentials('archive-userid')
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

			steps {
				script {
					withCredentials([usernamePassword(
							credentialsId: 'rabbit-mq',
							usernameVariable: 'RABBITMQ_USER',
							passwordVariable: 'RABBITMQ_PASSWORD')]) {
						sh('rancher -c ${RANCHERDEV_CREDS} rm --stop --type stack NRESPipelineTest || true')
						sh('rancher -c ${RANCHERDEV_CREDS} up --stack NRESPipelineTest --force-upgrade --confirm-upgrade -d')
					}
					CONTAINER_ID = getContainerId('NRESPipelineTest-NRESPipelineTest-1')
					CONTAINER_HOST = getContainerHostName('NRESPipelineTest-NRESPipelineTest-1')
				}
			}
		}
		stage('Test-Bias-Ingestion') {
			when {
				anyOf {
					branch 'PR-*'
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
					sshagent(credentials: ['jenkins-rancher-ssh']) {
						executeOnRancher('pytest --durations=0 --junitxml=/nres/code/pytest-bias-ingestion.xml ' +
								'-m bias_ingestion /nres/code/',
						    CONTAINER_HOST, CONTAINER_ID, ARCHIVE_UID)
					}
				}
			}
			post {
				always {
					script{
						sshagent(credentials: ['jenkins-rancher-ssh']) {
							copyFromRancherContainer('/nres/code/pytest-bias-ingestion.xml', '.', CONTAINER_HOST, CONTAINER_ID)
						}
						junit 'pytest-bias-ingestion.xml'
					}
				}
			}
		}
		stage('Test-Master-Bias-Creation') {
			when {
				anyOf {
					branch 'PR-*'
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
					sshagent(credentials: ['jenkins-rancher-ssh']) {
						executeOnRancher('pytest --durations=0 --junitxml=/nres/code/pytest-master-bias.xml ' +
								'-m master_bias /nres/code/',
								CONTAINER_HOST, CONTAINER_ID, ARCHIVE_UID)
					}
				}
			}
			post {
				always {
					script{
						sshagent(credentials: ['jenkins-rancher-ssh']) {
							copyFromRancherContainer('/nres/code/pytest-master-bias.xml', '.', CONTAINER_HOST, CONTAINER_ID)
						}
						junit 'pytest-master-bias.xml'
					}
				}
			}
		}
		stage('Test-Dark-Ingestion') {
			when {
				anyOf {
					branch 'PR-*'
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
					sshagent(credentials: ['jenkins-rancher-ssh']) {
						executeOnRancher('pytest --durations=0 --junitxml=/nres/code/pytest-dark-ingestion.xml ' +
								'-m dark_ingestion /nres/code/',
								CONTAINER_HOST, CONTAINER_ID, ARCHIVE_UID)
					}
				}
			}
			post {
				always {
					script{
						sshagent(credentials: ['jenkins-rancher-ssh']) {
							copyFromRancherContainer('/nres/code/pytest-dark-ingestion.xml', '.', CONTAINER_HOST, CONTAINER_ID)
						}
						junit 'pytest-dark-ingestion.xml'
					}
				}
			}
		}
		stage('Test-Master-Dark-Creation') {
			when {
				anyOf {
					branch 'PR-*'
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
					sshagent(credentials: ['jenkins-rancher-ssh']) {
						executeOnRancher('pytest --durations=0 --junitxml=/nres/code/pytest-master-dark.xml ' +
								'-m master_dark /nres/code/',
								CONTAINER_HOST, CONTAINER_ID, ARCHIVE_UID)
					}
				}
			}
			post {
				always {
					script{
						sshagent(credentials: ['jenkins-rancher-ssh']) {
							copyFromRancherContainer('/nres/code/pytest-master-dark.xml', '.', CONTAINER_HOST, CONTAINER_ID)
						}
						junit 'pytest-master-dark.xml'
					}
				}
			}
		}
		stage('Test-Flat-Ingestion') {
			when {
				anyOf {
					branch 'PR-*'
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
					sshagent(credentials: ['jenkins-rancher-ssh']) {
						executeOnRancher('pytest --durations=0 --junitxml=/nres/code/pytest-flat-ingestion.xml ' +
								'-m flat_ingestion /nres/code/',
								CONTAINER_HOST, CONTAINER_ID, ARCHIVE_UID)
					}
				}
			}
			post {
				always {
					script{
						sshagent(credentials: ['jenkins-rancher-ssh']) {
							copyFromRancherContainer('/nres/code/pytest-flat-ingestion.xml', '.', CONTAINER_HOST, CONTAINER_ID)
						}
						junit 'pytest-flat-ingestion.xml'
					}
				}
			}
		}
		stage('Test-Master-Flat-Creation') {
			when {
				anyOf {
					branch 'PR-*'
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
					sshagent(credentials: ['jenkins-rancher-ssh']) {
						executeOnRancher('pytest --durations=0 --junitxml=/nres/code/pytest-master-flat.xml ' +
								'-m master_flat /nres/code/',
								CONTAINER_HOST, CONTAINER_ID, ARCHIVE_UID)
					}
				}
			}
			post {
				always {
					script{
						sshagent(credentials: ['jenkins-rancher-ssh']) {
							copyFromRancherContainer('/nres/code/pytest-master-flat.xml', '.', CONTAINER_HOST, CONTAINER_ID)
						}
						junit 'pytest-master-flat.xml'
					}
				}
			}
		}
		stage('Test-Arc-Ingestion') {
			when {
				anyOf {
					branch 'PR-*'
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
					sshagent(credentials: ['jenkins-rancher-ssh']) {
						executeOnRancher('pytest --durations=0 --junitxml=/nres/code/pytest-arc-ingestion.xml ' +
								'-m arc_ingestion /nres/code/',
								CONTAINER_HOST, CONTAINER_ID, ARCHIVE_UID)
					}
				}
			}
			post {
				always {
					script{
						sshagent(credentials: ['jenkins-rancher-ssh']) {
							copyFromRancherContainer('/nres/code/pytest-arc-ingestion.xml', '.', CONTAINER_HOST, CONTAINER_ID)
						}
						junit 'pytest-arc-ingestion.xml'
					}
				}
			}
		}
		stage('Test-Master-Arc-Creation') {
			when {
				anyOf {
					branch 'PR-*'
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
					sshagent(credentials: ['jenkins-rancher-ssh']) {
						executeOnRancher('pytest --durations=0 --junitxml=/nres/code/pytest-master-arc.xml ' +
								'-m master_arc /nres/code/',
								CONTAINER_HOST, CONTAINER_ID, ARCHIVE_UID)
					}
				}
			}
			post {
				always {
					script{
						sshagent(credentials: ['jenkins-rancher-ssh']) {
							copyFromRancherContainer('/nres/code/pytest-master-arc.xml', '.', CONTAINER_HOST, CONTAINER_ID)
						}
						junit 'pytest-master-arc.xml'
					}
				}
			}
		}
		stage('Test-Zero-File-Creation') {
			when {
				anyOf {
					branch 'PR-*'
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
					sshagent(credentials: ['jenkins-rancher-ssh']) {
						executeOnRancher('pytest --durations=0 --junitxml=/nres/code/pytest-zero-file.xml ' +
								'-m zero_file /nres/code/',
								CONTAINER_HOST, CONTAINER_ID, ARCHIVE_UID)
					}
				}
			}
			post {
				always {
					script{
						sshagent(credentials: ['jenkins-rancher-ssh']) {
							copyFromRancherContainer('/nres/code/pytest-zero-file.xml', '.', CONTAINER_HOST, CONTAINER_ID)
						}
						junit 'pytest-zero-file.xml'
					}
				}
			}
		}
		stage('Test-Science-File-Creation') {
			when {
				anyOf {
					branch 'PR-*'
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
					sshagent(credentials: ['jenkins-rancher-ssh']) {
						executeOnRancher('pytest --durations=0 --junitxml=/nres/code/pytest-science-files.xml ' +
								'-m science_files /nres/code/',
								CONTAINER_HOST, CONTAINER_ID, ARCHIVE_UID)
					}
				}
			}
			post {
				always {
					script{
						sshagent(credentials: ['jenkins-rancher-ssh']) {
							copyFromRancherContainer('/nres/code/pytest-science-files.xml', '.', CONTAINER_HOST, CONTAINER_ID)
						}
						junit 'pytest-science-files.xml'
					}
				}
				success {
					script {
						sh('rancher -c ${RANCHERDEV_CREDS} rm --stop --type stack NRESPipelineTest')
					}
				}
			}
		}
	}
}
