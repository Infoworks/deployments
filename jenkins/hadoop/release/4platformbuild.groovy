def BRANCH="$branch"
def MVN_SKIPTESTS=new Boolean("$skip_tests_flag")
def ARTIFACTORY_URL="$artifactory_url"
def ARTIFACTORY_DEV_REPO="$artifactory_dev_repo"
def ARTIFACTORY_EXT_REPO="$artifactory_ext_repo"
def VERSION_BRANCHNAME=new Boolean("$version_branchname")
def VERSION_IN="${version_in}"
def GIT_TAGS = "${git_tags}"

def VERSION

def dependenciesJson='integration/dependencies.json'


node {
    //Pre-build
    deleteDir()
    stage "pre"
    echo "executing pre script."
    def mvnHome=tool 'mvn3'

    //stage "checkout"
    git branch: BRANCH, changelog: false, credentialsId: 'krishna-git', poll: false, url: 'git@github.com:Infoworks/platform.git'
    def COMMIT = sh returnStdout: true, script: 'git rev-parse HEAD 2> /dev/null'
    COMMIT = COMMIT.trim()
    echo "Commit Hash: " + COMMIT

    //sh "mkdir ../movingscripts"
    sh "cp scripts/log-schedule.json ../movingscripts"
    sh "cp scripts/logrotate.template.conf ../movingscripts"
    //sh "cp scripts/migrate.py ../movingscripts"
    sh "if [ -f scripts/migrate.py ]; then cp scripts/migrate.py ../movingscripts; fi"
    sh "cp -r scripts/environment-checker-ansible ../movingscripts"
    sh "cp -r scripts/infoworks-filesync-ansible ../movingscripts"
    sh "cp -r scripts/infoworks-ha-ansible ../movingscripts"
    sh "cp -r scripts/infoworks-mongoha-reset-ansible ../movingscripts"
    sh "cp -r scripts/infoworks-mongoha-setup-ansible ../movingscripts"
    sh "cp -r scripts/workflow_migration_310.py ../movingscripts"
    sh "cp -r scripts/hdp3_classpath.properties ../movingscripts"

    //stage "extract-version"
    if (VERSION_BRANCHNAME) {
        VERSION = BRANCH + "-STAGING"
        sh mvnHome + "/bin/mvn versions:set -DnewVersion=" + VERSION
    } else {
        if (VERSION_IN) {
            VERSION = VERSION_IN
            sh mvnHome + "/bin/mvn versions:set -DnewVersion=" + VERSION
        } else {
            sh mvnHome + '/bin/mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | grep -v "\\[" > versionInfo'
            VERSION = readFile 'versionInfo'
            VERSION = VERSION.trim()
        }

    }
    echo 'got project version: ' + VERSION

    //stage "resource-allocate"
    echo "resource-allocate: nothing to do"
    sleep 1

    stage "build"
    //sh "env mvnHome=${mvnHome} mvnSkipTests=${MVN_SKIPTESTS} integration/build/build.sh"
    //sh "${mvnHome}/bin/mvn deploy -Dmaven.test.skip=${MVN_SKIPTESTS}"
    sh "${mvnHome}/bin/mvn -DaltDeploymentRepository=releaseRepository::default::http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/ clean test-compile install deploy -Dmaven.test.skip=${MVN_SKIPTESTS}"


    stage "test"
    echo "test: nothing to do"

    stage "package"
    sh "mkdir -p  platform"
    echo "package: copying default conf to platform directory"
    sh "cp -r conf platform/"

    echo "package: copying scripts"
    //sh "cp -af  artifacts/build/scripts/common.sh artifacts/build/scripts/configure.sh artifacts/build/scripts/infoworks_monitor.py artifacts/build/scripts/start-active.sh artifacts/build/scripts/start-passive.sh artifacts/build/scripts/start.sh artifacts/build/scripts/status.sh artifacts/build/scripts/stop.sh /opt/bDr/scripts; "
    sh "pushd artifacts/scripts/; curl -H 'X-JFrog-Art-Api: AKCp2V6dFLFfExVFqZL4QCGR95A2W14HW5zCQsr7y3BquKqyjtYNprspjEgrVHkqjFEjUR6vP' " +
    "-T generate_security_ini.py " +
    "\"http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/platform/generate_security_ini.py\"; popd"


    echo "package: consolidate dependencies"
    sh "mkdir -p platform/bin; " +
    "cp messaging-service/target/messaging-service-" + VERSION + ".jar platform/bin/messaging-service.jar;" +
    //"cp metadb-service/common/target/metadb-common-" + VERSION + ".jar platform/bin/metadb-common.jar;" +
    "cp metadb-service/core/target/metadb-core-" + VERSION + ".jar platform/bin/metadb-core.jar;" +
    "cp metadb-service/server/target/metadb-server-" + VERSION + ".jar platform/bin/metadb-server.jar;" +
    "cp notification-system/common/target/notification-common-" + VERSION + ".jar platform/bin/notification-common.jar;" +
    "cp notification-system/core/target/notification-core-" + VERSION + ".jar platform/bin/notification-core.jar;" +
    "cp notification-system/consumer/target/notification-consumer-" + VERSION + ".jar platform/bin/notification-consumer.jar;" +
    "cp notification-system/server/target/notification-server-" + VERSION + ".jar platform/bin/notification-server.jar;" +
    "cp platform-common/target/platform-common-" + VERSION + ".jar platform/bin/platform-common.jar;" +
    "cp platform-server/target/platform-server-" + VERSION + ".jar platform/bin/platform-server.jar;" +
    "cp config-service/server/target/config-service-server-" + VERSION + ".jar platform/bin/config-service-server.jar;" +
    "cp config-service/core/target/config-service-core-" + VERSION + ".jar platform/bin/config-service-core.jar;" +
    "cp config-service/common/target/config-service-common-" + VERSION + ".jar platform/bin/config-service-common.jar;" +
    "cp engagement-metrics-service/target/engagement-metrics-service-" + VERSION + ".jar platform/bin/engagement-metrics-service.jar;" +
    "cp utils/target/utils-" + VERSION + ".jar platform/bin/utils.jar;" +
    // as per IPD-7469 not using the fat jar for scheduler
    //"cp scheduler-service/target/scheduler-service-" + VERSION + "-fat.jar platform/bin/scheduler-service.jar;" +
    "cp scheduler-service/target/scheduler-service-" + VERSION + ".jar platform/bin/scheduler-service.jar;" +
    "cp security-service/target/security-service-" + VERSION + ".jar platform/bin/security-service.jar;" +
    // below line is required only for 2.7.1 and above
    "cp -r monitoring-service platform/iw_monitor;" +
    // as per IPD-7469 not using the artifactory libs
    //"pushd platform; wget http://172.30.0.211:8081/artifactory/resources/2.7.x/platform-lib-1.0.tar.gz -O platform-lib.tar.gz; tar zxf platform-lib.tar.gz; rm -f platform-lib.tar.gz; popd;" +
    "mkdir -p platform/lib; cp -rf lib/* platform/lib/; rm -f platform/lib/tools-1.0.jar; " +
    "tar czf platform-dir-"+ VERSION + ".tar.gz platform/;" +
    "curl -H 'X-JFrog-Art-Api: AKCp2V6dFLFfExVFqZL4QCGR95A2W14HW5zCQsr7y3BquKqyjtYNprspjEgrVHkqjFEjUR6vP' " +
    "-T platform-dir-"+ VERSION + ".tar.gz " +
    "\"http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/platform/" + VERSION + "/platform-dir-"+ VERSION + ".tar.gz\";"



    echo "package: copying default conf to conf_2.3"

    // below lines have been added for release 2.7.2+
    sh "if [ -f scripts/cloudera_classpath.properties ]; then cp -af  scripts/cloudera_classpath.properties /opt/bDr/conf_2.3/; fi"
    sh "if [ -f scripts/mapr_classpath.properties ]; then cp -af  scripts/mapr_classpath.properties /opt/bDr/conf_2.3/; fi"
    sh "if [ -f scripts/hdp_classpath.properties ]; then cp -af  scripts/hdp_classpath.properties /opt/bDr/conf_2.3/; fi"


    sh "cp -af scripts/conf.properties /opt/bDr/conf_2.3/conf.properties.default; "
    sh "if [ -f scripts/spark-export.conf ]; then cp -af scripts/spark-export.conf /opt/bDr/conf_2.3/spark-export.conf; fi"
    sh "if [ -f scripts/*.log4j.properties ]; then cp -af scripts/*.log4j.properties /opt/bDr/conf_2.3/; fi"
    sh "if [ -f scripts/error.conf.properties ]; then cp -af scripts/error.conf.properties /opt/bDr/conf_2.3/; fi"
    sh "if [ -d scripts/sparkconf ]; then cp -af scripts/sparkconf/ /opt/bDr/conf_2.3/; fi "
    sh "if [ -d scripts/cloud-confs  ]; then cp -af scripts/cloud-confs/ /opt/bDr/conf_2.3/; fi "
    sh "cp -af /opt/bDr/conf_2.3/cube.log4j.properties /opt/bDr/conf_2.3/cube-access-server.log4j.properties; "

    echo "package: copying scripts"
    sh "cp -af  scripts/common.sh scripts/configure.sh scripts/infoworks_monitor.py scripts/start-active.sh scripts/start-passive.sh scripts/start.sh scripts/status.sh scripts/stop.sh /opt/bDr/scripts; if [ -f scripts/change_ojdbc_jar.sh ]; then cp scripts/change_ojdbc_jar.sh /opt/bDr/scripts/; fi; if [ -f scripts/start-old.sh ]; then cp scripts/start-old.sh /opt/bDr/scripts/; fi;if [ -f scripts/stop-old.sh ]; then cp scripts/stop-old.sh /opt/bDr/scripts/; fi;"
    sh "if [ -f scripts/infoworks_configure.sh ]; then cp scripts/infoworks_configure.sh /opt/bDr/scripts/; fi"
    sh "if [ -f scripts/reset_incr_replicator.sh ]; then cp scripts/reset_incr_replicator* /opt/bDr/scripts/; fi"
    sh "if [ -f scripts/reset_ldap_auth.py ]; then cp scripts/reset_ldap_auth.py /opt/bDr/scripts/; fi"
    sh "if [ -f scripts/check_open_ports.sh ]; then cp scripts/check_open_ports.sh /opt/bDr/scripts/; fi"
    sh "if [ -f scripts/generate_platform_config.sh ]; then cp scripts/generate_platform_config.sh /opt/bDr/scripts/; fi"
    sh "if [ -d scripts/infoworks-ha-ansible ]; then cp -r scripts/infoworks-ha-ansible /opt/bDr/scripts/; fi"
    sh "if [ -d scripts/RestAPI ]; then cp -r scripts/RestAPI /opt/bDr/scripts/; fi"
    sh "cp -af  scripts/env.sh /opt/bDr/scripts/env.sh.default; "
    sh "if [ -f scripts/mongo-upgrade.sh ]; then cp -af  scripts/mongo-* /opt/bDr/scripts/; cp -af  scripts/mongo_s* /opt/bDr/scripts/; fi"
    //sh "if [ \"\$(ls -l mongo-*)\" ]; then cp -af  scripts/mongo-* /opt/bDr/scripts/; fi"
    sh "chmod +x /opt/bDr/scripts/mongo-*; "
    sh "if [ -f scripts/mongoha_start.sh ]; then cp -af  scripts/mongoha* /opt/bDr/scripts/; fi"
    sh "if [ -f scripts/iw-logrotate.sh ]; then cp -af  scripts/iw-logrotate* /opt/bDr/scripts/; fi"
    sh "if [ -f scripts/upgrade-orchestration-engine.sh ]; then cp -af  scripts/upgrade-orchestration-engine.sh /opt/bDr/scripts/; fi"

    sh "if [ -d scripts/infoworks-filesync-ansible ]; then cp -r scripts/infoworks-filesync-ansible /opt/bDr/scripts/; fi"
    sh "cp -r start-iw-services /opt/bDr/scripts/"
    sh "cp -r stop-iw-services /opt/bDr/scripts/"
    sh "cp -r status-iw-services /opt/bDr/scripts/"

    sh "rm -rf /opt/pipeline_script/*"

    sh "if [ -f scripts/pipeline_utils/pipeline_create.py ]; then cp scripts/pipeline_utils/pipeline_create.py /opt/pipeline_script/; fi"
    sh "if [ -f scripts/pipeline_utils/README ]; then cp scripts/pipeline_utils/README /opt/pipeline_script/; fi"
    sh "cp -r scripts/pipeline_utils/sample_input /opt/pipeline_script/"

    echo "package: copying migrations"
    sh "cp -af scripts/migrate/* /opt/bDr/migrate/ || echo \"unable to find scripts/migrate/ in platform, skipping\" "

    //3rd party dependencies
    echo "package: 3rd party dependencies"

    //stage 'manifest'
    echo 'Generating manifest for platform'
    echo 'Generating manifest entry for dependencies'
    def depsJSON = "{"

    depsJSON += "}"
    def manifest = """{
    "platform":
        {
          "branch": "$BRANCH",
          "commit": "$COMMIT",
          "version": "$VERSION",
          "dependencies": $depsJSON
        }
}"""
    echo "Manifest: " + manifest
    echo "Saving manifest file"
    writeFile file: 'manifest', text: manifest

    sh "curl -H 'X-JFrog-Art-Api: AKCp2V6dFLFfExVFqZL4QCGR95A2W14HW5zCQsr7y3BquKqyjtYNprspjEgrVHkqjFEjUR6vP' " +
    "-T manifest " +
    "\"http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/manifest/" + VERSION + "/platform-manifest-"+ VERSION + ".json\";"

    stage "post"
    echo "apply git tags(if any): ${GIT_TAGS}"
    if ( GIT_TAGS?.trim() ) {
        def tags = GIT_TAGS.split(",")
        for(int i=0; i<tags.size(); i++ ) {
            tag = tags[i].trim()
            sh "git tag ${tag}"
        }
        sh "git push --tags"
    }
    echo "Executing mvn clean"
    sh "${mvnHome}/bin/mvn clean"
}
