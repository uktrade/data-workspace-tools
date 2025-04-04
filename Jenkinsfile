pipeline {
    agent none

    parameters {
        string(
            name: 'Branch',
            defaultValue: 'main',
            description: 'The name of the git branch or commit ID to deploy.',
            trim: true,
        )
        extendedChoice(
            name: 'Environment',
            defaultValue: 'analysisworkspace-dev',
            description: 'The environment to deploy to.',
            type: 'PT_RADIO',
            visibleItemCount: 3,
            value: '' +
                'analysisworkspace-dev,' +
                'data-workspace-staging,' +
                'jupyterhub',
            descriptionPropertyValue: '' +
                '<strong>🌱 dev</strong>: https://analysisworkspace.dev.uktrade.io/,' +
                '<strong>🎪 staging</strong>: https://data.trade.staging.uktrade.digital/,' +
                '<strong>🏆 production</strong>: https://data.trade.gov.uk/',
        )
        extendedChoice(
            name: 'Component',
            defaultValue: 'python-jupyterlab|jupyterlab-python|master',
            description: 'The component to deploy, matching the stage name of the Dockerfile.',
            type: 'PT_RADIO',
            visibleItemCount: 10,
            value: '' +
                'python-jupyterlab|jupyterlab-python|master,' +
                'python-theia|theia|master,' +
                'python-vscode|vscode|master,' +
                'python-visualisation|visualisation-base|python,' +
                'python-pgadmin|pgadmin|master,' +
                'rv4-cran-binary-mirror|mirrors-sync-cran-binary-rv4|master,' +
                'rv4-rstudio|rstudio-rv4|master,' +
                'rv4-visualisation|visualisation-base|rv4,' +
                'remote-desktop|remotedesktop|master,' +
                's3sync|s3sync|master,' +
                'metrics|metrics|master',
            descriptionPropertyValue: '' +
                '<strong>python-jupyterlab</strong>: JupyterLab,' +
                '<strong>python-theia</strong>: Theia,' +
                '<strong>python-vscode</strong>: VS-Code,' +
                '<strong>python-visualisation</strong>: Base for Python visualisations,' +
                '<strong>python-pgadmin</strong>: pgAdmin,' +
                '<strong>rv4-cran-binary-mirror</strong>: Image for CRAN binary mirror pipeline,' +
                '<strong>rv4-rstudio</strong>: RStudio (R version 4),' +
                '<strong>rv4-visualisation</strong>: Base for R version 4 visualisations,' +
                '<strong>remote-desktop</strong>: Remote desktop,' +
                '<strong>s3sync</strong>: Sidecar for syncing Your Files,' +
                '<strong>metrics</strong>: Sidecar for extracting metrics so tools automatically shut down'
        )
        extendedChoice(
            name: 'Caching',
            defaultValue: '',
            description: 'By default layers pushed in the 12 hours before a build are used as a cache.',
            type: 'PT_CHECKBOX',
            visibleItemCount: 1,
            value: 'skip',
            descriptionPropertyValue: 'Ignore any cached layers and force a rebuild from the top of the Dockerfile. If you\'re not sure, leave this unticked.',
        )
    }

    stages {
        stage('build') {
            agent {
                kubernetes {
                defaultContainer 'jnlp'
                yaml """
                    apiVersion: v1
                    kind: Pod
                    metadata:
                      labels:
                        job: ${env.JOB_NAME}
                        job_id: ${env.BUILD_NUMBER}
                    spec:
                      nodeSelector:
                        role: worker
                      containers:
                      - name: builder
                        image: gcr.io/kaniko-project/executor:debug
                        imagePullPolicy: Always
                        command:
                        - cat
                        tty: true
                        volumeMounts:
                        - name: jenkins-docker-cfg
                          mountPath: /kaniko/.docker
                      volumes:
                      - name: jenkins-docker-cfg
                        secret:
                          secretName: jenkins-data-workspace
                          items:
                          - key: config.json
                            path: config.json
                """
                }
            }
            steps {
                script {
                    (dockerTarget, dockerRepoSuffix, dockerTag) = params.Component.tokenize('|')
                    cacheTTL = params.Caching == 'skip' ? '0' : '12h'
                    def Map<String, String> envDescriptions = [
                        'analysisworkspace-dev': '🌱 dev',
                        'data-workspace-staging': '🎪 staging',
                        'jupyterhub': '🏆 production',
                    ]
                    currentBuild.displayName = envDescriptions[params.Environment] + "[${dockerTarget}]"
                    currentBuild.description = "Branch: ${params.Branch}"
                }
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: params.Branch]],
                    userRemoteConfigs: [[url: 'https://github.com/uktrade/data-workspace-tools.git']]
                ])
                container(name: 'builder', shell: '/busybox/sh') {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'DATASCIENCE_ECS_DEPLOY']]) {
                    withCredentials([string(credentialsId: 'DATA_INFRASTRUCTURE_PROD_ACCOUNT_ID', variable: 'DATA_INFRASTRUCTURE_PROD_ACCOUNT_ID')]) {
                    withEnv([
                        "PATH+EXTRA=/busybox:/kaniko",
                        "Environment=${params.Environment}",
                        "dockerTarget=${dockerTarget}",
                        "dockerRepoSuffix=${dockerRepoSuffix}",
                        "dockerTag=${dockerTag}",
                        "cacheTTL=${cacheTTL}",
                    ]) {
                        sh '''
                          #!/busybox/sh
                          /kaniko/executor \
                            --context ${WORKSPACE} \
                            --dockerfile ${WORKSPACE}/Dockerfile \
                            --target=${dockerTarget} \
                            --skip-unused-stages=true \
                            --cache=true \
                            --cache-ttl=${cacheTTL} \
                            --cache-copy-layers=true \
                            --cache-run-layers=true \
                            --cache-repo=${DATA_INFRASTRUCTURE_PROD_ACCOUNT_ID}.dkr.ecr.eu-west-2.amazonaws.com/${Environment}-${dockerRepoSuffix} \
                            --destination=${DATA_INFRASTRUCTURE_PROD_ACCOUNT_ID}.dkr.ecr.eu-west-2.amazonaws.com/${Environment}-${dockerRepoSuffix}:${dockerTag}
                        '''
                    }}}
                }
            }
        }
    }
}
