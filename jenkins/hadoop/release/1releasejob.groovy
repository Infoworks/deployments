def VERSION
def FORCE_BUILD = new Boolean("$force_build")
def BUILD_DBLORE = new Boolean("$dblore_buildflag")
def BUILD_APRICOT_METEOR = new Boolean("$apricot_meteor_buildflag")
def BUILD_DF = new Boolean("$df_buildflag")
def BUILD_CUBE = new Boolean("$cube_buildflag")
def BUILD_CUBE_HDP3 = new Boolean("$cube_hdp3_buildflag")
def BUILD_SCHEDULER = new Boolean("$scheduler_buildflag")
def BUILD_SQOOP = new Boolean("$infoworks_sqoop_buildflag")
def BUILD_INFOWORKS_CLOUD = new Boolean("$infoworks_cloud_buildflag")
def BUILD_DOCS = new Boolean("$docs_buildflag")
def BUILD_REPLICATOR = new Boolean("$replicator_buildflag")
def BUILD_PLATFORM = new Boolean("$platform_buildflag")
def BUILD_RESOURCES = new Boolean("$build_resources")
def BUILD_SCRIPTS = new Boolean("$build_scripts")
def BUILD_LIB = new Boolean("$build_lib")
def GIT_TAGS = "${git_tags}"
def VERSION_BRANCHNAME = false
def ARTIFACTORY_DEV_REPO="$artifactory_dev_repo"
def ARTIFACTORY_EXT_REPO="$artifactory_ext_repo"
def TARGET_OS="$target_os"
def DISTRIBUTION="$distribution"

def PACKAGE_HOME='/tmp/infoworks'
def TARGET_IW_HOME='/opt/infoworks'

def ARTIFACTORY_HOST='172.30.0.211:8081'
def ARTIFACTORY_REPO='infoworks-dev-mvn'
def NOTIFICATION_MAIL

node {
try {
    stage "pre"

    echo "setting version for release"
    //stage "extract-version"
    if (VERSION_BRANCHNAME) {
        //VERSION = BRANCH + "-STAGING"
    } else {
        VERSION = "${release_version}"
    }


    //stage "checkout"
    git branch: "develop", changelog: false, credentialsId: 'krishna-git', poll: false, url: 'git@github.com:Infoworks/build.git'

    echo "create temp directory"
    sh "rm -rf temp/"
    sh "mkdir -p temp/infoworks temp/manifest temp/download"

    // stage "build"
    echo "checking status of artifacts"
    //get all artifact existance
    def artifact_exists=true
    def BUILD_FLAG=true
    echo "artifact_exists: " + artifact_exists
    echo "FORCE_BUILD: " + FORCE_BUILD
    if (artifact_exists && !FORCE_BUILD) {
        BUILD_FLAG=false
    }
    echo "BUILD_FLAG: " + BUILD_FLAG
    if (BUILD_FLAG) {
        echo "Build flag is true. Ruunning jobs in parallel."
        build job: 'parallel-build-pipeline-3.1.1+', parameters: [string(name: 'dblore_branch', value: "${dblore_branch}"), booleanParam(name: 'dblore_buildflag', value: new Boolean("${dblore_buildflag}")), string(name: 'apricot_meteor_branch', value: "${apricot_meteor_branch}"), booleanParam(name: 'apricot_meteor_buildflag', value: new Boolean("${apricot_meteor_buildflag}")), string(name: 'infoworks_sqoop_branch', value: "${infoworks_sqoop_branch}"), booleanParam(name: 'infoworks_sqoop_buildflag', value: new Boolean("${infoworks_sqoop_buildflag}")), string(name: 'df_branch', value: "${df_branch}"), booleanParam(name: 'df_buildflag', value: new Boolean("${df_buildflag}")), string(name: 'cube_branch', value: "${cube_branch}"), booleanParam(name: 'cube_buildflag', value: new Boolean("${cube_buildflag}")), string(name: 'scheduler_branch', value: "${scheduler_branch}"), booleanParam(name: 'scheduler_buildflag', value: new Boolean("${scheduler_buildflag}")), string(name: 'replicator_branch', value: "${replicator_branch}"), booleanParam(name: 'replicator_buildflag', value: new Boolean("${replicator_buildflag}")), string(name: 'infoworks_cloud_branch', value: "${infoworks_cloud_branch}"), booleanParam(name: 'infoworks_cloud_buildflag', value: new Boolean("${infoworks_cloud_buildflag}")), string(name: 'docs_branch', value: "${docs_branch}"), booleanParam(name: 'docs_buildflag', value: new Boolean("${docs_buildflag}")), booleanParam(name: 'skip_tests_flag', value: new Boolean("${skip_tests_flag}")), string(name: 'artifactory_url', value: "${artifactory_url}"), string(name: 'artifactory_dev_repo', value: "${artifactory_dev_repo}"), string(name: 'artifactory_ext_repo', value: "${artifactory_ext_repo}"), booleanParam(name: 'version_branchname', value: new Boolean("${VERSION_BRANCHNAME}")), string(name: 'git_tags', value: "${git_tags}"), string(name: 'version_in', value: "${release_version}"),string(name: 'platform_branch', value: "${platform_branch}"), booleanParam(name: 'platform_buildflag', value: new Boolean("${platform_buildflag}")), string(name: 'cube_hdp3_branch', value: "${cube_hdp3_branch}"), booleanParam(name: 'cube_hdp3_buildflag', value: new Boolean("${cube_hdp3_buildflag}"))], quietPeriod: 1
    } else {
        echo "Build flag is false. Skipping build jobs."
    }

    stage "package"

    //stage "versioning"
    echo "setting the product release version to ${VERSION}"

    //stage "manifest"
    echo "generating unified product manifest file"
    def manifest = ""
    def dblore_manifest
    def apricot_meteor_manifest
    def docs_manifest

    if ( BUILD_DBLORE ) {
        echo "Fetching manifest for dblore"
        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/manifest/${VERSION}/dblore-manifest-${VERSION}.json -O temp/manifest/dblore-manifest.json"
        dblore_manifest = readFile "temp/manifest/dblore-manifest.json"
    } else {
        echo "Skipping dblore"
        dblore_manifest = "{dblore:{}}"
    }
    if (manifest) {
        manifest += ","
    }
    manifest += dblore_manifest + System.getProperty("line.separator")

    if ( BUILD_APRICOT_METEOR ) {
        echo "Fetching manifest for apricot_meteor"
        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/manifest/${VERSION}/apricot-meteor-manifest-${VERSION}.json -O temp/manifest/apricot-meteor-manifest.json"
        apricot_meteor_manifest = readFile "temp/manifest/apricot-meteor-manifest.json"
    } else {
        echo "Skipping apricot_meteor"
        apricot_meteor_manifest = "{apricot_meteor:{}}"
    }
    if (manifest) {
        manifest += ","
    }
    manifest += apricot_meteor_manifest + System.getProperty("line.separator")

    if ( BUILD_SQOOP ) {
        echo "Fetching manifest for infoworks-sqoop"
        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/manifest/${VERSION}/infoworks-sqoop-manifest-${VERSION}.json -O temp/manifest/infoworks-sqoop-manifest.json"
        infoworks_sqoop_manifest = readFile "temp/manifest/infoworks-sqoop-manifest.json"
    } else {
        echo "Skipping infoworks-sqoop"
        infoworks_sqoop_manifest = "{infoworks-sqoop:{}}"
    }
    if (manifest) {
        manifest += ","
    }
    manifest += infoworks_sqoop_manifest + System.getProperty("line.separator")

    if ( BUILD_REPLICATOR ) {
        echo "Fetching manifest for replicator"
        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/manifest/${VERSION}/replicator-manifest-${VERSION}.json -O temp/manifest/replicator-manifest.json"
        replicator_manifest = readFile "temp/manifest/replicator-manifest.json"
    } else {
        echo "Skipping replicator"
        replicator_manifest = "{replicator:{}}"
    }
    if (manifest) {
        manifest += ","
    }
    manifest += replicator_manifest + System.getProperty("line.separator")

    if ( BUILD_PLATFORM ) {
        echo "Fetching manifest for platform"
        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/manifest/${VERSION}/ignite-cache-manifest-${VERSION}.json -O temp/manifest/ignite-cache-manifest.json"
        ignite_cache_manifest = readFile "temp/manifest/ignite-cache-manifest.json"
        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/manifest/${VERSION}/platform-manifest-${VERSION}.json -O temp/manifest/platform-manifest.json"
        platform_manifest = readFile "temp/manifest/platform-manifest.json"
    } else {
        echo "Skipping ignite-cache"
        ignite_cache_manifest = "{ignite-cache:{}}"
        platform_manifest = "{platform:{}}"
    }
    if (manifest) {
        manifest += ","
    }
    manifest += ignite_cache_manifest + System.getProperty("line.separator")
    manifest += platform_manifest + System.getProperty("line.separator")

    //if ( BUILD_SCHEDULER ) {
    //    echo "Fetching manifest for scheduler-service"
    //    sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/manifest/${VERSION}/scheduler-service-manifest-${VERSION}.json -O temp/manifest/scheduler-service-manifest.json"
    //    scheduler_service_manifest = readFile "temp/manifest/scheduler-service-manifest.json"
    //} else {
    //    echo "Skipping scheduler-service"
    //    scheduler_service_manifest = "{scheduler-service:{}}"
    //}
    //if (manifest) {
    //    manifest += ","
    //}
    //manifest += scheduler_service_manifest + System.getProperty("line.separator")

    if ( BUILD_INFOWORKS_CLOUD ) {
        echo "Fetching manifest for infoworks-cloud"
        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/manifest/${VERSION}/infoworks-cloud-manifest-${VERSION}.json -O temp/manifest/infoworks-cloud-manifest.json"
        infoworks_cloud_manifest = readFile "temp/manifest/infoworks-cloud-manifest.json"
    } else {
        echo "Skipping infoworks-cloud"
        infoworks_cloud_manifest = "{infoworks-cloud:{}}"
    }
    if (manifest) {
        manifest += ","
    }
    manifest += infoworks_cloud_manifest + System.getProperty("line.separator")

    if ( BUILD_DF ) {
        echo "Fetching manifest for df"
        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/manifest/${VERSION}/df-manifest-${VERSION}.json -O temp/manifest/df-manifest.json"
        df_manifest = readFile "temp/manifest/df-manifest.json"
    } else {
        echo "Skipping df"
        df_manifest = "{df:{}}"
    }
    if (manifest) {
        manifest += ","
    }
    manifest += df_manifest + System.getProperty("line.separator")

    if ( BUILD_CUBE ) {
        echo "Fetching manifest for cube"
        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/manifest/${VERSION}/cube-manifest-${VERSION}.json -O temp/manifest/cube-manifest.json"
        cube_manifest = readFile "temp/manifest/cube-manifest.json"
    } else {
        echo "Skipping cube"
        cube_manifest = "{cube:{}}"
    }
    if (manifest) {
        manifest += ","
    }
    manifest += cube_manifest + System.getProperty("line.separator")

    if ( BUILD_CUBE_HDP3 ) {
        echo "Fetching manifest for cube"
        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/manifest/${VERSION}/cube-hdp3-manifest-${VERSION}.json -O temp/manifest/cube-manifest.json"
        cube_hdp3_manifest = readFile "temp/manifest/cube-manifest.json"
    } else {
        echo "Skipping cube"
        cube_manifest = "{cube:{}}"
    }
    if (manifest) {
        manifest += ","
    }
    manifest += cube_hdp3_manifest + System.getProperty("line.separator")

    if ( BUILD_DOCS ) {
        echo "Fetching manifest for docs"
        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/manifest/${VERSION}/docs-manifest-${VERSION}.json -O temp/manifest/docs-manifest.json"
        docs_manifest = readFile "temp/manifest/docs-manifest.json"
    } else {
        echo "Skipping docs"
        docs_manifest = "{docs:{}}"
    }
    if (manifest) {
        manifest += ","
    }
    manifest += docs_manifest + System.getProperty("line.separator")



    manifest = "[" + System.getProperty("line.separator") + manifest + System.getProperty("line.separator") + "]"
    echo "combined maifest: " + manifest
    writeFile file: 'temp/infoworks/manifest.json', text: manifest

    //stage "binary-collect"
    echo "pulling the corresponding binaries from the artifactory"
    sh "mkdir temp/infoworks/bin; "


    sh "mkdir temp/infoworks/examples/"
    //sh "mv temp/infoworks/sample temp/infoworks/examples/"

    if ( BUILD_DBLORE ) {
        echo "Fetching binaries for dblore"
        sh "mkdir -p temp/download/dblore temp/download/dblore-lib"
        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/io/infoworks/tools/${VERSION}/tools-${VERSION}.jar -O temp/download/dblore/tools.jar; " +
        "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/io/infoworks/discovery/${VERSION}/discovery-${VERSION}.jar -O temp/download/dblore/discovery.jar; " +
        "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/io/infoworks/QueryDriver/${VERSION}/QueryDriver-${VERSION}.jar -O temp/download/dblore/QueryDriver.jar; " +
        "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/io/infoworks/datacube/${VERSION}/datacube-${VERSION}.jar -O temp/download/dblore/datacube.jar; " +
        "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/io/infoworks/server/${VERSION}/server-${VERSION}.jar -O temp/download/dblore/server.jar; " +
        "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/io/infoworks/SparkStream/${VERSION}/SparkStream-${VERSION}.jar -O temp/download/dblore/SparkStream.jar; " +
        "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/io/infoworks/VertxQueryService/${VERSION}/VertxQueryService-${VERSION}.jar -O temp/download/dblore/VertxQueryService.jar ; "


        //"wget http://54.221.70.148:8081/artifactory/resources/2.6.x/lib-9.0${DISTRIBUTION}.tar.gz -O temp/download/dblore-lib/dblore-libs.tar.gz;"
        // changing to lib-10.0 to support cobol copybook
        //"wget http://54.221.70.148:8081/artifactory/resources/2.6.x/lib-10.0${DISTRIBUTION}.tar.gz -O temp/download/dblore-lib/dblore-libs.tar.gz;"
        // changing to lib-11.0 to support fixed width univocity jar

        // changing source of lib jars from artifactory to github

        //"wget http://54.221.70.148:8081/artifactory/resources/2.7.x/lib-13.0${DISTRIBUTION}.tar.gz -O temp/download/dblore-lib/dblore-libs.tar.gz;"
        //sh "pushd temp/download/dblore-lib/; tar xzf dblore-libs.tar.gz; popd;"

        dir('temp/download/dblore-lib/') {
            git branch: "${dblore_branch}", changelog: false, credentialsId: 'krishna-git', poll: false, url: 'git@github.com:Infoworks/dblore.git'
            def JARS_COMMIT = sh returnStdout: true, script: 'git rev-parse HEAD 2> /dev/null'
            JARS_COMMIT = JARS_COMMIT.trim()
            echo "Commit Hash for dblore for lib jars: " + JARS_COMMIT
        }

        sh "cp temp/download/dblore/* temp/infoworks/bin; cp -r temp/download/dblore-lib/lib temp/infoworks"
        sh "mkdir -p temp/infoworks/lib/extras"
        sh "mkdir -p temp/infoworks/lib/extras/dt"
        sh "mkdir -p temp/infoworks/lib/extras/ingestion"
        sh "mkdir -p temp/infoworks/lib/extras/streaming"
        sh "mkdir -p temp/infoworks/lib/extras/export"
        sh "mkdir -p temp/infoworks/lib/extras/hive-crawl"
        sh "mkdir -p temp/infoworks/lib/extras/cloud"
        sh "mkdir -p temp/infoworks/extensions"

        sh "mkdir -p temp/infoworks/temp/tpt/logs"
        sh "mkdir -p temp/infoworks/temp/tpt/scripts"
        sh "mkdir -p temp/infoworks/temp/tpt/checkpoints"

        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/io/infoworks/metadata/${VERSION}/metadata-${VERSION}.jar -O temp/infoworks/lib/shared/metadata.jar"
    } else {
        echo "Skipping dblore"
    }

    if ( BUILD_APRICOT_METEOR ) {
        echo "Fetching binaries for apricot_meteor"
        sh "mkdir temp/download/apricot-meteor"
        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/apricot-meteor/${VERSION}/apricot-meteor-${VERSION}.tar.gz -O temp/download/apricot-meteor.tar.gz"
        sh "tar xzf temp/download/apricot-meteor.tar.gz -C temp/download; cp -r temp/download/apricot-meteor temp/infoworks"

    } else {
        echo "Skipping apricot_meteor"
    }

    if ( BUILD_SQOOP ) {
        echo "Fetching binaries for infoworks-sqoop"
        sh "mkdir -p temp/infoworks/lib"
        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/sqoop/${VERSION}/sqoop-${VERSION}.jar -O temp/download/sqoop-1.4.6.jar"
        sh "cp temp/download/sqoop-1.4.6.jar temp/infoworks/lib/shared"
    } else {
        echo "Skipping infoworks-sqoop"
    }

    if ( BUILD_REPLICATOR ) {
        echo "Fetching binaries for replicator"
        sh "mkdir -p temp/download/replicator"
        sh "rm -rf temp/download/replicatorconf"
        sh "mkdir -p temp/download/replicatorconf"

        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/infoworks/replicator/infoworks-replicator-auditor/${VERSION}/infoworks-replicator-auditor-${VERSION}.jar -O temp/download/replicator/infoworks-replicator-auditor.jar; " +
        "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/infoworks/replicator/infoworks-replicator-core/${VERSION}/infoworks-replicator-core-${VERSION}.jar -O temp/download/replicator/infoworks-replicator-core.jar; " +
        "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/infoworks/replicator/infoworks-sentry-migration/${VERSION}/infoworks-sentry-migration-${VERSION}.jar -O temp/download/replicator/infoworks-sentry-migration.jar; " +
        "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/infoworks/replicator/scripts/${VERSION}/scripts-${VERSION}.tar.gz -O scripts.tar.gz; tar zxf scripts.tar.gz; rm scripts.tar.gz; mv scripts temp/download/replicator/; " +
        "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/infoworks/replicator/replicatorconf/${VERSION}/replicatorconf-${VERSION}.tar.gz -O replicatorconf.tar.gz; mkdir -p r_conf; tar zxf replicatorconf.tar.gz -C r_conf; rm replicatorconf.tar.gz; mv r_conf/conf temp/download/replicatorconf/"

        sh "cp -r temp/download/replicator/* temp/infoworks/bin"
        sh "mkdir -p temp/infoworks/replicatorconf"
        sh "cp -r temp/download/replicatorconf/conf/* temp/infoworks/replicatorconf"
    } else {
        echo "Skipping replicator"
    }

    if ( BUILD_PLATFORM ) {
        echo "Fetching binaries for platform"
        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/io/infoworks/IgniteCacheStore/${VERSION}/IgniteCacheStore-${VERSION}.jar -O temp/infoworks/bin/cacheStore.jar; "
        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/platform/" + VERSION + "/platform-dir-"+ VERSION + ".tar.gz -O temp/infoworks/platform-dir.tar.gz; pushd temp/infoworks/; tar zxf platform-dir.tar.gz; rm platform-dir.tar.gz; popd"
    } else {
        echo "Skipping platform"
    }

    if ( BUILD_INFOWORKS_CLOUD ) {
        PACKAGE_HOME="${WORKSPACE}/temp/infoworks"
        TARGET_IW_HOME='/opt/infoworks'

        ARTIFACTORY_HOST='172.30.0.211:8081'
        ARTIFACTORY_REPO='infoworks-dev-mvn'

        sh "mkdir temp/infoworks-cloud-repo"
        dir('temp/infoworks-cloud-repo') {
            git branch: "${infoworks_cloud_branch}", changelog: false, credentialsId: '${git-credential}', poll: false, url: 'git@github.com:Infoworks/infoworks-cloud.git'
        }

        withEnv(["TARGET_VERSION=$VERSION",
        "PACKAGE_HOME=$PACKAGE_HOME",
        "TARGET_HOSTNAME=localhost",
        "IW_HOME=$TARGET_IW_HOME",
        "USE_ARTIFACTORY=true",
        "ARTIFACTORY_HOST=$ARTIFACTORY_HOST",
        "ARTIFACTORY_REPO=$ARTIFACTORY_REPO"]) {
            //For backwards compatibility
            //Pre-2.5.0 versions will not have build/ecb dir
            sh  '''
            ls -laRt
            pwd
            #if available, use new build files
            if [ -d temp/infoworks-cloud-repo/build/infoworks-cloud/steps ] || [ -d temp/infoworks-cloud-repo/build/infoworks-cloud/scripts ]; then
                pushd temp/infoworks-cloud-repo
                ls -lart
                pwd
                if [ -d build/infoworks-cloud/steps ]; then
                    #This is the current main dir, rest are for back-compat
                    pushd build/infoworks-cloud/steps/package
                else
                    pushd build/infoworks-cloud/scripts/package
                fi
                ./package.sh
                popd
                popd
            else
                mkdir -p temp/infoworks/lib/cloud temp/download/infoworks-cloud;
                wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/io/infoworks/nimbus/${TARGET_VERSION}/nimbus-${TARGET_VERSION}.jar -O temp/download/infoworks-cloud/nimbus.jar;
                wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/io/infoworks/lib/${TARGET_VERSION}/nimbus-lib-${TARGET_VERSION}.tar.gz -O temp/download/infoworks-cloud/nimbus-lib.tar.gz;
                tar xzf temp/download/infoworks-cloud/nimbus-lib.tar.gz -C temp/download/infoworks-cloud;
                cp temp/download/infoworks-cloud/nimbus.jar temp/download/infoworks-cloud/lib/* temp/infoworks/lib/cloud;
            fi
            '''
        }
    } else {
        echo "Skipping infoworks-cloud"
    }

    if ( BUILD_DF ) {

        echo "Fetching DT binaries"
        sh "cp -r /mnt/disk1/workspace/dt-mvn-build-3.1.1x/packaging/target/dt-package/conf/* temp/infoworks/conf/"
        sh "mkdir temp/infoworks/lib/dt"
        sh "cp -r /mnt/disk1/workspace/dt-mvn-build-3.1.1x/packaging/target/dt-package/lib/*  temp/infoworks/lib/dt/"
        //sh "mkdir temp/infoworks/examples"
        sh "cp -r /mnt/disk1/workspace/dt-mvn-build-3.1.1x/packaging/target/dt-package/examples/*  temp/infoworks/examples/"
        sh "mkdir temp/infoworks/lib/dt/udfs"
        sh "cp -r /mnt/disk1/workspace/dt-mvn-build-3.1.1x/packaging/target/dt-package/dt/udfs/* temp/infoworks/lib/dt/udfs/"
        sh "mkdir temp/infoworks/dt"
        sh "mkdir temp/infoworks/dt/udfs"
        sh "cp -r /mnt/disk1/workspace/dt-mvn-build-3.1.1x/packaging/target/dt-package/dt/udfs/* temp/infoworks/dt/udfs/"
    } else {
        echo "Skipping df"
    }

    if ( BUILD_CUBE ) {
        echo "Fetching binaries for cube"
        sh "mkdir -p temp/download/; " +
        "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/cube/${VERSION}/cube-${VERSION}.tar.gz -O temp/download/cube-package.tar.gz; " +
        // "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/access-server/${VERSION}/access-server-${VERSION}.jar -O temp/download/access-server.jar; " +
        "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/io/infoworks/access-server/1.0/access-server-1.0.jar -O temp/download/access-server.jar; " +
        "tar xzf temp/download/cube-package.tar.gz -C temp/download; " +
        "mv temp/download/apache-kylin-${VERSION}-bin temp/infoworks/cube-engine; " +
        "mv temp/download/access-server.jar temp/infoworks/bin; "
    } else {
        echo "Skipping cube"
    }

    if ( BUILD_SCHEDULER ) {
        echo "Fetching binaries for scheduler"
        //sh "mkdir -p temp/download/scheduler; " +
        //"wget http://54.221.70.148:8081/artifactory/infoworks-dev-generic/io/infoworks/scheduler/3.0/scheduler-3.0.tar.gz -O temp/download/scheduler-package.tar.gz; " +
        //"wget http://54.221.70.148:8081/artifactory/infoworks-dev-generic/io/infoworks/scheduler/4.0/scheduler-4.0.tar.gz -O temp/download/scheduler-package.tar.gz; " +
        // changing to scheduler 5.0 to support cobol copybook
        //"wget http://54.221.70.148:8081/artifactory/infoworks-dev-generic/io/infoworks/scheduler/5.0/scheduler-5.0.tar.gz -O temp/download/scheduler-package.tar.gz; " +
        // changing to scheduler 6.0 which has jtds jar in the libs
        //"wget http://54.221.70.148:8081/artifactory/infoworks-dev-generic/io/infoworks/scheduler/6.0/scheduler-6.0.tar.gz -O temp/download/scheduler-package.tar.gz; " +

        // changing to scheduler 7.0 which has generic restapi jar in the libs
        //"wget http://54.221.70.148:8081/artifactory/infoworks-dev-generic/io/infoworks/scheduler/7.0/scheduler-7.0.tar.gz -O temp/download/scheduler-package.tar.gz; " +
        //"tar xzf temp/download/scheduler-package.tar.gz -C temp/download/scheduler; cp -r temp/download/scheduler/RestAPI temp/infoworks; "
        //sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/io/infoworks/QueryService/1.0/QueryService-1.0.war  -O temp/infoworks/RestAPI/apache-tomcat-7.0.63/webapps/QueryService.war; "

        // Commenting download of notification war, since it is deprecated from 2.7.1 onwards
        //sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/io/infoworks/NotificationService/1.0/NotificationService-1.0.war  -O temp/infoworks/RestAPI/apache-tomcat-7.0.63/webapps/NotificationService.war; "

        // Not copying the scheduler war file anymore..from 2.7.0 onwards, scheduler is part of platform
        //sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/scheduler-service/${VERSION}/scheduler-service-${VERSION}.war  -O temp/infoworks/RestAPI/apache-tomcat-7.0.63/webapps/scheduler.war; "
        //sh "rm -f temp/infoworks/RestAPI/apache-tomcat-7.0.63/webapps/scheduler.war; "

        // should comment the below line for 2.7.1 and above
        //sh "rm -f temp/infoworks/RestAPI/apache-tomcat-7.0.63/webapps/NotificationService.war; "
    } else {
        echo "Skipping scheduler"
    }

    if ( BUILD_DOCS ) {
        echo "Fetching binaries for docs"
        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/docs/${VERSION}/iw_docs-${VERSION}.tar.gz -O temp/download/docs.tar.gz"
        sh "tar xzf temp/download/docs.tar.gz -C temp/download; cp -r temp/download/iw_docs temp/infoworks/docs"

    } else {
        echo "Skipping docs"
    }

    echo "adding licences"
    // sh "pushd temp/infoworks; wget https://s3.amazonaws.com/infoworks-setup/licences_2.6.x.tar.gz && tar xzf licences_2.6.x.tar.gz && rm licences_2.6.x.tar.gz; popd"
    // sh "pushd temp/infoworks; wget https://s3.amazonaws.com/infoworks-setup/licences_2.6.4%2B.tar.gz && tar xzf licences_2.6.4+.tar.gz && rm licences_2.6.4+.tar.gz; popd"
    // changed for 2.7.2 onwards
    sh "pushd temp/infoworks; wget https://infoworks-setup.s3.amazonaws.com/licences_2.9.0.tar.gz && tar xzf licences_2.9.0.tar.gz && rm licences_2.9.0.tar.gz; popd"

    if ( BUILD_RESOURCES ) {
        echo "adding resources"
        sh "pushd temp/infoworks; wget http://172.30.0.211:8081/artifactory/resources/${TARGET_OS}/resources-orchestrator-2.9.1.tar.gz && tar xzf resources-orchestrator-2.9.1.tar.gz && rm resources-orchestrator-2.9.1.tar.gz; popd"
        sh "wget https://infoworks-setup.s3.amazonaws.com/platform.conf.template"
        sh "cp platform.conf.template temp/infoworks/resources/nginx-portable/conf/infoworks/"
    }

    if ( BUILD_SCRIPTS ) {
        echo "adding migration scripts"
        sh "mkdir -p temp/infoworks/bin"
        //sh "cp -r /opt/bDr/migrate/ temp/infoworks/bin"
        //sh "pushd temp/infoworks/bin; wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/apricot-meteor/" + VERSION + "/migration-${VERSION}.tar.gz; tar zxf migration-${VERSION}.tar.gz; rm -f migration-${VERSION}.tar.gz; popd"
        sh "mkdir -p temp/infoworks/bin/migrate; cp -r /opt/bDr/migrate/* temp/infoworks/bin/migrate/"
        sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/apricot-meteor/" + VERSION + "/migration-${VERSION}.tar.gz; tar zxf migration-${VERSION}.tar.gz; rm -f migration-${VERSION}.tar.gz; cp -rf migrate/* temp/infoworks/bin/migrate/;"

        sh "mkdir temp/infoworks/bin/migrate/migration_support_spark_pipelines"
        sh "wget http://54.221.70.148:8081/artifactory/resources/migration_support_spark_pipelines/support_spark_pipelines.sh -O temp/infoworks/bin/migrate/migration_support_spark_pipelines/support_spark_pipelines.sh"
        sh "wget http://54.221.70.148:8081/artifactory/resources/migration_support_spark_pipelines/support_orc_pipelines-0.0.1-SNAPSHOT.jar -O temp/infoworks/bin/migrate/migration_support_spark_pipelines/support_orc_pipelines-0.0.1-SNAPSHOT.jar"

        echo "copying scripts"
        //sh "if [ -f /opt/bDr/scripts/RestAPI/catalina.sh ]; then cp -f /opt/bDr/scripts/RestAPI/catalina.sh temp/infoworks/RestAPI/apache-tomcat-7.0.63/bin/; rm -rf /opt/bDr/scripts/RestAPI; fi"
        sh "cp -r /opt/bDr/scripts/* temp/infoworks/bin"
        //sh "if [ -d /opt/bDr/scripts/infoworks-ha-ansible ]; then cp -r /opt/bDr/scripts/infoworks-ha-ansible temp/infoworks/bin; fi"

        sh "mkdir -p temp/infoworks/utils; cd temp/infoworks/utils; wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/lib/" + VERSION + "/infoworks-ignite-ansible-" + VERSION + ".tar.gz; tar zxf infoworks-ignite-ansible-" + VERSION + ".tar.gz; rm -f infoworks-ignite-ansible-" + VERSION + ".tar.gz;"

        // generate_security_ini.py is required for 2.7.0 onwards
        sh "mkdir -p temp/infoworks/scripts; pushd temp/infoworks/scripts; wget http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/platform/generate_security_ini.py; popd;"

        // this is required for 2.7.1 and above only
        build job: 'update_scripts_upload', parameters: [string(name: 'branch', value: "${platform_branch}"), booleanParam(name: 'skip_tests_flag', value: true), credentials(description: '', name: 'git-credential', value: '7367371d-0a73-4af2-9fa0-a4804a551133'), string(name: 'artifactory_url', value: 'http://54.221.70.148:8081/artifactory/api/storage/'), string(name: 'artifactory_dev_repo', value: 'libs-release-local'), string(name: 'artifactory_ext_repo', value: 'ext-dependency'), booleanParam(name: 'version_branchname', value: true), string(name: 'git_tags', value: ''), string(name: 'version_in', value: "${release_version}"), string(name: 'release_version_two_bits', value: '3.1')]

    }

    echo "adding confs"
    sh "mkdir -p temp/infoworks/conf"
    sh "cp -r /opt/bDr/conf_2.3/* temp/infoworks/conf "
    sh "if [ -f temp/infoworks/conf/OracleUDA.txt ]; then cp temp/infoworks/conf/OracleUDA.txt temp/infoworks/resources/; fi"
    sh "mv temp/infoworks/replicatorconf/* temp/infoworks/conf/ "
    sh "rm -rf temp/infoworks/replicatorconf "
    sh "cp ../movingscripts/log-schedule.json  temp/infoworks/conf"
    sh "cp ../movingscripts/logrotate.template.conf  temp/infoworks/conf"
    sh "cp ../movingscripts/migrate.py temp/infoworks/scripts"
    sh "cp ../movingscripts/workflow_migration_310.py temp/infoworks/scripts/workflow_migration_310.py"

    echo "adding cube keys"
    sh "cp -r /opt/bDr/cube-keys/ temp/infoworks/ "

    echo "creating initial log folder structure"
    sh "cp -r /opt/bDr/logs/ temp/infoworks/ "

    echo "creating initial temp folder structure"
    sh "cp -r /opt/bDr/temp/ temp/infoworks/ "

    echo "creating version file"
    sh "echo '${VERSION}' > temp/infoworks/version;"

    //stage "package"
    echo "preparing the product release tarball"

    echo "node build apricot-meteor"
    sh "if [ -d temp/infoworks/apricot-meteor ] && [ -d temp/infoworks/resources/nodejs ]; then echo \"both apricot-meteor and resorces/nodejs folders exist\"; source temp/infoworks/bin/env.sh.default && ./temp/infoworks/apricot-meteor/scripts/startup_may2017.sh; else echo \"both apricot-meteor and resorces/nodejs folders dont exist; skipping\"; fi"

    if ( !BUILD_LIB ) {
        echo "BUILD_LIBS is false, removing lib directory"
        sh "rm -rf temp/infoworks/lib"
    }

    //Adding BigQuery Jars
    sh "wget https://infoworks-setup.s3.amazonaws.com/bq-jars/spark-bigquery-latest.jar -O temp/infoworks/lib/cloud/spark-bigquery-latest.jar"
    sh "wget https://infoworks-setup.s3.amazonaws.com/bq-spark-submit.sh -O temp/infoworks/bin/bq-spark-submit.sh"
    sh "chmod +x temp/infoworks/bin/bq-spark-submit.sh"
    sh "mkdir temp/infoworks/lib/cloud/gcp"
    sh "mkdir temp/infoworks/lib/cloud/gcp/spark"
    sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/io/infoworks/lib/${release_version}/gcp-spark-${release_version}.jar -O temp/infoworks/lib/cloud/gcp/spark/gcp-spark-1.0.jar"
    sh "wget http://172.30.0.211:8081/artifactory/infoworks-dev-mvn/io/infoworks/lib/${release_version}/gcp-spark-${release_version}.jar -O temp/infoworks/lib/cloud/gcp-spark-1.0.jar"

    //adding bigquery jars
    sh "wget https://infoworks-setup.s3.amazonaws.com/bq-jars/BigQueryjars.zip -O temp/BigQueryjars.zip"
    sh "unzip temp/BigQueryjars.zip -d temp/infoworks/lib/shared/bigquery"

    //sh "wget https://infoworks-setup.s3.amazonaws.com/bq-jars/BigQuery42JDBC.tar.gz -O temp/BigQuery42JDBC.tar.gz"
    //sh "tar -xvzf temp/BigQuery42JDBC.tar.gz -C temp/infoworks/lib/shared/bigquery"

    //Adding HA Scripts
    sh "cp -r ../movingscripts/environment-checker-ansible temp/infoworks/bin"
    sh "cp -r ../movingscripts/infoworks-filesync-ansible temp/infoworks/bin"
    sh "cp -r ../movingscripts/infoworks-ha-ansible temp/infoworks/bin"
    sh "cp -r ../movingscripts/infoworks-mongoha-reset-ansible temp/infoworks/bin"
    sh "cp -r ../movingscripts/infoworks-mongoha-setup-ansible temp/infoworks/bin"

    //Removing Jersy Jars
    //sh "rm temp/infoworks/platform/lib/notification-client/jersey-core-*.jar"
    //sh "rm temp/infoworks/platform/lib/notification-client/jersey-client-*.jar"

    //adding python scripts from awb to df python scripts
    //sh "mkdir -p temp/infoworks/df/python_scripts"
    //sh "cp -a ../awb-python-scripts/python-driver/python_api/dist/api-1.0.egg temp/infoworks/df/python_scripts/"
    //sh "cp -a ../awb-python-scripts/python-driver/driver/python_translator_driver.py temp/infoworks/df/python_scripts/"
    //sh "cp -a ../awb-python-scripts/python-driver/python_api/example/custom_transformation_example.py temp/infoworks/examples/pipeline-extensions/"
    //sh "cp -a ../awb-python-scripts/python-driver/python_api/example/custom_target_example.py temp/infoworks/examples/pipeline-extensions/"

    //adding pipeline utlity scripts
    sh "mkdir -p temp/infoworks/scripts/pipeline"
    sh "mv /opt/pipeline_script/* temp/infoworks/scripts/pipeline"

    //Removing DF dependency
    sh "rm -rf temp/infoworks/lib/df"
    sh "rm temp/infoworks/conf/df.driver.log4j.properties"
    sh "rm temp/infoworks/conf/df_executor_configs.yaml"
    //sh "rm temp/infoworks/df_spark_defaults.conf"
    sh "cp temp/infoworks/conf/sparkconf/df_spark_cdh.conf temp/infoworks/conf/sparkconf/dt_spark_cdh.conf"
    sh "cp temp/infoworks/conf/sparkconf/df_spark.conf temp/infoworks/conf/sparkconf/dt_spark.conf"
    sh "cp temp/infoworks/conf/sparkconf/df_spark_mapr.conf temp/infoworks/conf/sparkconf/dt_spark_mapr.conf"
    sh "cp temp/infoworks/conf/sparkconf/df_spark_hdp.conf temp/infoworks/conf/sparkconf/dt_spark_hdp.conf"
    sh "rm -rf temp/infoworks/logs/df"

    sh "chmod 777 temp/infoworks/bin/migrate/iw_migration.sh"
    sh "cp /mnt/disk1/workspace/platform-mvn-build-3.1.x/scripts/upgrade-migrations.sh temp/infoworks/bin/migrate/"
    sh "cp /mnt/disk1/workspace/platform-mvn-build-3.1.x/scripts/migrate_airflow_configs.py temp/infoworks/bin/"

    sh "rm temp/infoworks/lib/shared/bigquery/guava-26.0-android.jar"

    def ARTIFACT_NAME = "infoworks-${VERSION}.tar.gz"
    sh "tar -C temp/ -czf ${ARTIFACT_NAME} infoworks/"

    sh "curl -H 'X-JFrog-Art-Api: AKCp2V6dFLFfExVFqZL4QCGR95A2W14HW5zCQsr7y3BquKqyjtYNprspjEgrVHkqjFEjUR6vP' " +
    "-T $ARTIFACT_NAME " +
    "\"http://172.30.0.211:8081/artifactory/infoworks-release/io/infoworks/release/" + VERSION + "/$ARTIFACT_NAME\";"

    stage "test"
    echo "executing integration tests"

    def ARTIFACT_ALIAS_NAME = "infoworks-${VERSION}-rhel6.tar.gz"
    sh "cp $ARTIFACT_NAME $ARTIFACT_ALIAS_NAME;"
    //sh "cp $ARTIFACT_NAME $ARTIFACT_ALIAS_NAME; curl -H 'X-JFrog-Art-Api: AKCp2V6dFLFfExVFqZL4QCGR95A2W14HW5zCQsr7y3BquKqyjtYNprspjEgrVHkqjFEjUR6vP' " +
    //"-T $ARTIFACT_ALIAS_NAME " +
    //"\"http://172.30.0.211:8081/artifactory/infoworks-release/io/infoworks/release/" + VERSION + "/$ARTIFACT_ALIAS_NAME\";"

    //sh "aws s3 cp $ARTIFACT_NAME s3://infoworks-setup/2.7/ --acl public-read"
    //sh "aws s3 cp $ARTIFACT_ALIAS_NAME s3://infoworks-setup/2.7/ --acl public-read"

    sh "mv ${ARTIFACT_NAME} /mnt/disk1/packages/"
    sh "mv ${ARTIFACT_ALIAS_NAME} /mnt/disk1/packages/"
    build job: 'nginx-conf-change', parameters: [string(name: 'VERSIONNUMBER', value: "${release_version}"), booleanParam(name: 'upload_to_S3', value: false), booleanParam(name: 'use_local_copy', value: true)]

    build job: 'create_hdp_3_packages_3.1.x', parameters: [string(name: 'VERSIONNUMBER', value: "${release_version}"), booleanParam(name: 'upload_to_S3', value: false), booleanParam(name: 'use_local_copy', value: true)]

    build job: 'cloud_packages_3.1.1+', parameters: [string(name: 'version', value: "${release_version}"), booleanParam(name: 'upload_to_S3', value: false), booleanParam(name: 'use_local_copy', value: true)]
    //build job: 'cloud_packages_emr_310', parameters: [string(name: 'version', value: "${release_version}"), booleanParam(name: 'upload_to_S3', value: false), booleanParam(name: 'use_local_copy', value: true)]



    build job: 'upload_to_S3', parameters: [string(name: 's3_bucket', value: 'infoworks-setup'), string(name: 'version', value: '3.1'), string(name: 'file_name', value: "${ARTIFACT_NAME}")]
    build job: 'upload_to_S3', parameters: [string(name: 's3_bucket', value: 'infoworks-setup'), string(name: 'version', value: '3.1'), string(name: 'file_name', value: "${ARTIFACT_ALIAS_NAME}")]
    build job: 'upload_to_S3', parameters: [string(name: 's3_bucket', value: 'infoworks-setup'), string(name: 'version', value: '3.1'), string(name: 'file_name', value: "infoworks-${VERSION}-rhel7.tar.gz")]
    build job: 'upload_to_S3', parameters: [string(name: 's3_bucket', value: 'infoworks-setup'), string(name: 'version', value: '3.1'), string(name: 'file_name', value: "infoworks-${VERSION}-ubuntu16.tar.gz")]
    build job: 'upload_to_S3', parameters: [string(name: 's3_bucket', value: 'infoworks-setup'), string(name: 'version', value: '3.1'), string(name: 'file_name', value: "infoworks-${VERSION}-azure.tar.gz")]
    build job: 'upload_to_S3', parameters: [string(name: 's3_bucket', value: 'infoworks-setup'), string(name: 'version', value: '3.1'), string(name: 'file_name', value: "infoworks-${VERSION}-emr.tar.gz")]
    build job: 'upload_to_S3', parameters: [string(name: 's3_bucket', value: 'infoworks-setup'), string(name: 'version', value: '3.1'), string(name: 'file_name', value: "infoworks-${VERSION}-gcp.tar.gz")]
    build job: 'upload_to_S3', parameters: [string(name: 's3_bucket', value: 'infoworks-setup'), string(name: 'version', value: '3.1'), string(name: 'file_name', value: "infoworks-${VERSION}-hdp-rhel6.tar.gz")]
    build job: 'upload_to_S3', parameters: [string(name: 's3_bucket', value: 'infoworks-setup'), string(name: 'version', value: '3.1'), string(name: 'file_name', value: "infoworks-${VERSION}-hdp-rhel7.tar.gz")]

    '''
    parallel firstBranch: {

        build job: 'upload_to_S3', parameters: [string(name: 's3_bucket', value: 'infoworks-setup'), string(name: 'version', value: '3.1'), string(name: 'file_name', value: "${ARTIFACT_NAME}")]
        //sh "rm /mnt/disk1/packages/${ARTIFACT_NAME}"
    }, secondBranch: {

        build job: 'upload_to_S3', parameters: [string(name: 's3_bucket', value: 'infoworks-setup'), string(name: 'version', value: '3.1'), string(name: 'file_name', value: "${ARTIFACT_ALIAS_NAME}")]
        //sh "rm /mnt/disk1/packages/${ARTIFACT_ALIAS_NAME}"
    }, thirdBranch: {
        build job: 'upload_to_S3', parameters: [string(name: 's3_bucket', value: 'infoworks-setup'), string(name: 'version', value: '3.1'), string(name: 'file_name', value: "infoworks-${VERSION}-rhel7.tar.gz")]
        //sh "rm /mnt/disk1/packages/infoworks-${VERSION}-rhel7.tar.gz"
    }, fourthBranch: {
        build job: 'upload_to_S3', parameters: [string(name: 's3_bucket', value: 'infoworks-setup'), string(name: 'version', value: '3.1'), string(name: 'file_name', value: "infoworks-${VERSION}-ubuntu16.tar.gz")]

    }, fifthBranch: {
        build job: 'upload_to_S3', parameters: [string(name: 's3_bucket', value: 'infoworks-setup'), string(name: 'version', value: '3.1'), string(name: 'file_name', value: "infoworks-${VERSION}-azure.tar.gz")]

    }, sixthBranch: {
        build job: 'upload_to_S3', parameters: [string(name: 's3_bucket', value: 'infoworks-setup'), string(name: 'version', value: '3.1'), string(name: 'file_name', value: "infoworks-${VERSION}-emr.tar.gz")]

    }, seventhBranch: {
        build job: 'upload_to_S3', parameters: [string(name: 's3_bucket', value: 'infoworks-setup'), string(name: 'version', value: '3.1'), string(name: 'file_name', value: "infoworks-${VERSION}-gcp.tar.gz")]
    }, eighthBranch: {
        build job: 'upload_to_S3', parameters: [string(name: 's3_bucket', value: 'infoworks-setup'), string(name: 'version', value: '3.1'), string(name: 'file_name', value: "infoworks-${VERSION}-hdp-rhel6.tar.gz")]
    }, ninthBranch: {
        build job: 'upload_to_S3', parameters: [string(name: 's3_bucket', value: 'infoworks-setup'), string(name: 'version', value: '3.1'), string(name: 'file_name', value: "infoworks-${VERSION}-hdp-rhel7.tar.gz")]
    },
    failFast: true
    '''

    stage "post"
    echo "executing cleanup"
    sh "rm -rf temp/"
    sh "rm -rf /mnt/disk1/packages/*"

    //build job: 'auto_deploy', parameters: [string(name: 'release_version', value: "${release_version}")], quietPeriod: 1



    NOTIFICATION_MAIL = "Created new package infoworks-${release_version} from branch: ${dblore_branch}, infoworks links can be refered from: https://docs.google.com/spreadsheets/d/1_wUhqmdkQEGcTwHyORCV2q-93r__DQxBgQ8Rt_THdTE/edit?usp=sharing"
    currentBuild.result = 'SUCCESS'
} catch (error) {
    NOTIFICATION_MAIL="Creating package failed: ${BUILD_URL}"
    currentBuild.result = 'FAILURE'
} finally {
    mail bcc: '', body: "$NOTIFICATION_MAIL", cc: '', from: '', replyTo: '', subject: "Jenkins Job: release-pipeline-3.1.x | Package: infoworks-${release_version}.tar.gz | ${currentBuild.result}", to: 'roopa.k@infoworks.io'
}
}
