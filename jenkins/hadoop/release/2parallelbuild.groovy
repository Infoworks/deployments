stage "init"

def BUILD_DBLORE = new Boolean("$dblore_buildflag")
def BUILD_REPLICATOR = new Boolean("$replicator_buildflag")
def BUILD_APRICOT_METEOR = new Boolean("$apricot_meteor_buildflag")
def BUILD_DF = new Boolean("$df_buildflag")
def BUILD_CUBE = new Boolean("$cube_buildflag")
def BUILD_SCHEDULER = new Boolean("$scheduler_buildflag")
def BUILD_SQOOP = new Boolean("$infoworks_sqoop_buildflag")
def BUILD_DOCS = new Boolean("$docs_buildflag")
def BUILD_INFOWORKS_CLOUD = new Boolean("$infoworks_cloud_buildflag")
def BUILD_PLATFORM = new Boolean("$platform_buildflag")
def BUILD_CUBE_HDP3 = new Boolean("$cube_hdp3_buildflag")

def parallel_steps_before_pre= [:]
parallel_steps_before_pre.failFast = true
def parallel_steps_0= [:]
parallel_steps_0.failFast = true
def parallel_steps_1= [:]
parallel_steps_1.failFast = true
def parallel_steps_3= [:]
parallel_steps_3.failFast = true
def parallel_steps_4= [:]
parallel_steps_4.failFast = true


parallel_steps_before_pre["step_dependencies"] = {
    node {

        if ( BUILD_DBLORE ) {
            echo "prebuilding dblore"
            build job: 'dblore-mvn-build-3.1.x', parameters: [string(name: 'branch', value: "${dblore_branch}"), booleanParam(name: 'mvn_skip_tests_flag', value: new Boolean("${skip_tests_flag}")), string(name: 'artifactory_url', value: "${artifactory_url}"), string(name: 'artifactory_dev_repo', value: "${artifactory_dev_repo}"), string(name: 'artifactory_ext_repo', value: "${artifactory_ext_repo}"), booleanParam(name: 'version_branchname', value: new Boolean("false")), string(name: 'git_tags', value: ""), string(name: 'version_in', value: "${version_in}"), booleanParam(name: 'tools_build_only', value: false), string(name: 'pom', value: "pom.xml")], propagate: false
        } else {
            echo "Skipping dblore prebuild"
        }

        if ( BUILD_PLATFORM ) {
            echo "Building platform"
            build job: 'platform-mvn-build-3.1.x', parameters: [string(name: 'branch', value: "${platform_branch}"), booleanParam(name: 'skip_tests_flag', value: new Boolean("${skip_tests_flag}")), string(name: 'artifactory_url', value: "${artifactory_url}"), string(name: 'artifactory_dev_repo', value: "${artifactory_dev_repo}"), string(name: 'artifactory_ext_repo', value: "${artifactory_ext_repo}"), booleanParam(name: 'version_branchname', value: new Boolean("${version_branchname}")), string(name: 'git_tags', value: "${git_tags}"), string(name: 'version_in', value: "${version_in}")]
        } else {
            echo "Skipping platform prebuild"
        }

        if ( BUILD_INFOWORKS_CLOUD ) {
            echo "prebuilding Infoworks Cloud"
            build job: 'infoworks-cloud-mvn-build-3.1.x', parameters: [string(name: 'branch', value: "${infoworks_cloud_branch}"), booleanParam(name: 'skip_tests_flag', value: new Boolean("${skip_tests_flag}")), string(name: 'artifactory_url', value: "${artifactory_url}"), string(name: 'artifactory_dev_repo', value: "${artifactory_dev_repo}"), string(name: 'artifactory_ext_repo', value: "${artifactory_ext_repo}"), booleanParam(name: 'version_branchname', value: new Boolean("false")), string(name: 'git_tags', value: ""), string(name: 'version_in', value: "${version_in}"),booleanParam(name: 'build_nimbus_only', value: false)]
        } else {
            echo "Skipping cloud prebuild"
        }
    }
}

parallel_steps_0["step_dblore"] = {
    node {
        if ( BUILD_DBLORE ) {
            echo "Building dblore"
            build job: 'dblore-mvn-build-3.1.x', parameters: [string(name: 'branch', value: "${dblore_branch}"), booleanParam(name: 'mvn_skip_tests_flag', value: new Boolean("${skip_tests_flag}")), string(name: 'artifactory_url', value: "${artifactory_url}"), string(name: 'artifactory_dev_repo', value: "${artifactory_dev_repo}"), string(name: 'artifactory_ext_repo', value: "${artifactory_ext_repo}"), booleanParam(name: 'version_branchname', value: new Boolean("${version_branchname}")), string(name: 'git_tags', value: "${git_tags}"), string(name: 'version_in', value: "${version_in}"), booleanParam(name: 'tools_build_only', value: false), string(name: 'pom', value: "pom.xml")]
        } else {
            echo "Skipping dblore"
        }
    }
}
parallel_steps_0["step_apricot_meteor"] = {
    node {
        if ( BUILD_APRICOT_METEOR ) {
            echo "Building apricot_meteor"
            build job: 'apricot-meteor-build-3.1.x', parameters: [string(name: 'branch', value: "${apricot_meteor_branch}"), booleanParam(name: 'skip_tests_flag', value: new Boolean("${skip_tests_flag}")), string(name: 'artifactory_url', value: "${artifactory_url}"), string(name: 'artifactory_dev_repo', value: "${artifactory_dev_repo}"), string(name: 'artifactory_ext_repo', value: "${artifactory_ext_repo}"), booleanParam(name: 'version_branchname', value: new Boolean("${version_branchname}")), string(name: 'git_tags', value: "${git_tags}"), string(name: 'version_in', value: "${version_in}")]
        } else {
            echo "Skipping apricot_meteor"
        }
    }
}
parallel_steps_1["step_sqoop-infoworks"] = {
    node {
        if ( BUILD_SQOOP ) {
            echo "Building infoworks-sqoop"
            build job: 'sqoop-mvn-build-3.1.x', parameters: [string(name: 'branch', value: "${infoworks_sqoop_branch}"), booleanParam(name: 'skip_tests_flag', value: new Boolean("${skip_tests_flag}")), string(name: 'artifactory_url', value: "${artifactory_url}"), string(name: 'artifactory_dev_repo', value: "${artifactory_dev_repo}"), string(name: 'artifactory_ext_repo', value: "${artifactory_ext_repo}"), booleanParam(name: 'version_branchname', value: new Boolean("${version_branchname}")), string(name: 'git_tags', value: "${git_tags}"), string(name: 'version_in', value: "${version_in}"), string(name: 'hdp_version', value: "2.x")]
        } else {
            echo "Skipping infoworks-sqoop"
        }
    }
}
parallel_steps_1["step_df"] = {
    node {
        if ( BUILD_DF ) {
            echo "Building df"
                // changing back from df-mvn-build-3.1.x to df-mvn-build job since df vertex is not ready for spark
                build job: 'dt-mvn-build-3.1.1x', parameters: [string(name: 'branch', value: "${df_branch}"), booleanParam(name: 'skip_tests_flag', value: new Boolean("${skip_tests_flag}")), booleanParam(name: 'build_extensions', value: true), string(name: 'artifactory_url', value: "${artifactory_url}"), string(name: 'artifactory_dev_repo', value: "${artifactory_dev_repo}"), string(name: 'artifactory_ext_repo', value: "${artifactory_ext_repo}"), booleanParam(name: 'version_branchname', value: new Boolean("${version_branchname}")), string(name: 'git_tags', value: "${git_tags}"), string(name: 'version_in', value: "${version_in}")]
        } else {
            echo "Skipping df"
        }
    }
}
parallel_steps_1["step_cube"] = {
    node {
        if ( BUILD_CUBE ) {
            echo "Building cube"
            build job: 'cube-mvn-build-3.1.x', parameters: [string(name: 'branch', value: "${cube_branch}"), booleanParam(name: 'skip_tests_flag', value: new Boolean("${skip_tests_flag}")), string(name: 'artifactory_url', value: "${artifactory_url}"), string(name: 'artifactory_dev_repo', value: "${artifactory_dev_repo}"), string(name: 'artifactory_ext_repo', value: "${artifactory_ext_repo}"), booleanParam(name: 'version_branchname', value: new Boolean("${version_branchname}")), string(name: 'git_tags', value: "${git_tags}"), string(name: 'version_in', value: "${version_in}")]
        } else {
            echo "Skipping cube"
        }
    }
}
parallel_steps_1["step_replicator"] = {
    node {
        if ( BUILD_REPLICATOR ) {
            echo "Building replicator"
            build job: 'replicator-mvn-build-3.1.x', parameters: [string(name: 'branch', value: "${replicator_branch}"), booleanParam(name: 'skip_tests_flag', value: new Boolean("${skip_tests_flag}")), string(name: 'artifactory_url', value: "${artifactory_url}"), string(name: 'artifactory_dev_repo', value: "${artifactory_dev_repo}"), string(name: 'artifactory_ext_repo', value: "${artifactory_ext_repo}"), booleanParam(name: 'version_branchname', value: new Boolean("${version_branchname}")), string(name: 'git_tags', value: "${git_tags}"), string(name: 'version_in', value: "${version_in}")]
        } else {
            echo "Skipping replicator"
        }
    }
}
parallel_steps_1["step_ignite"] = {
    node {
        if ( BUILD_PLATFORM ) {
            echo "Building ignite"
            build job: 'ignite_mvn_build-3.1.x', parameters: [string(name: 'branch', value: "${platform_branch}"), booleanParam(name: 'skip_tests_flag', value: new Boolean("${skip_tests_flag}")), string(name: 'artifactory_url', value: "${artifactory_url}"), string(name: 'artifactory_dev_repo', value: "${artifactory_dev_repo}"), string(name: 'artifactory_ext_repo', value: "${artifactory_ext_repo}"), booleanParam(name: 'version_branchname', value: new Boolean("${version_branchname}")), string(name: 'git_tags', value: "${git_tags}"), string(name: 'version_in', value: "${version_in}")]
            // when more of the platform components are required; add the jobs here

        } else {
            echo "Skipping platform"
        }
    }
}
parallel_steps_3["step_scheduler"] = {
    node {
        if ( BUILD_SCHEDULER ) {
            //echo "Building scheduler"
            //build job: 'scheduler-mvn-build-3.1.x', parameters: [string(name: 'branch', value: "${scheduler_branch}"), booleanParam(name: 'skip_tests_flag', value: new Boolean("${skip_tests_flag}")), string(name: 'artifactory_url', value: "${artifactory_url}"), string(name: 'artifactory_dev_repo', value: "${artifactory_dev_repo}"), string(name: 'artifactory_ext_repo', value: "${artifactory_ext_repo}"), booleanParam(name: 'version_branchname', value: new Boolean("${version_branchname}")), string(name: 'git_tags', value: "${git_tags}"), string(name: 'version_in', value: "${version_in}")]
            echo "Building scheduler repo is not required for 2.7.0 onwards"
        } else {
            echo "Skipping scheduler"
        }
    }
}
parallel_steps_3["step_docs"] = {
    node {
        if ( BUILD_DOCS ) {
            echo "Building docs"
            build job: 'iw-documentation-build-3.1.x', parameters: [string(name: 'branch', value: "${docs_branch}"), booleanParam(name: 'skip_tests_flag', value: new Boolean("${skip_tests_flag}")), string(name: 'artifactory_url', value: "${artifactory_url}"), string(name: 'artifactory_dev_repo', value: "${artifactory_dev_repo}"), string(name: 'artifactory_ext_repo', value: "${artifactory_ext_repo}"), booleanParam(name: 'version_branchname', value: new Boolean("${version_branchname}")), string(name: 'git_tags', value: "${git_tags}"), string(name: 'version_in', value: "${version_in}")]
        } else {
            echo "Skipping docs"
        }
    }
}
//parallel_steps_3["step_infoworks_cloud"] = {
//    node {
//        if ( BUILD_INFOWORKS_CLOUD ) {
//            echo "Building Infoworks Cloud"
//            build job: 'infoworks-cloud-mvn-build-3.1.x', parameters: [string(name: 'branch', value: "${infoworks_cloud_branch}"), booleanParam(name: 'skip_tests_flag', value: new Boolean("${skip_tests_flag}")), string(name: 'artifactory_url', value: "${artifactory_url}"), string(name: 'artifactory_dev_repo', value: "${artifactory_dev_repo}"), string(name: 'artifactory_ext_repo', value: "${artifactory_ext_repo}"), booleanParam(name: 'version_branchname', value: new Boolean("${version_branchname}")), string(name: 'git_tags', value: "${git_tags}"), string(name: 'version_in', value: "${version_in}")]
//        } else {
//            echo "Skipping docs"
//        }
//    }
//}

parallel_steps_3["step_dblore_hdp3"] = {
    node {
        if ( BUILD_DBLORE ) {
            echo "Building dblore hdp3"
            build job: 'dblore-mvn-build-3.1.x', parameters: [string(name: 'branch', value: "${dblore_branch}"), booleanParam(name: 'mvn_skip_tests_flag', value: new Boolean("${skip_tests_flag}")), string(name: 'artifactory_url', value: "${artifactory_url}"), string(name: 'artifactory_dev_repo', value: "${artifactory_dev_repo}"), string(name: 'artifactory_ext_repo', value: "${artifactory_ext_repo}"), booleanParam(name: 'version_branchname', value: new Boolean("false")), string(name: 'git_tags', value: ""), string(name: 'version_in', value: "${version_in}"), booleanParam(name: 'tools_build_only', value: false), string(name: 'pom', value: "pom_hdp3.xml")], propagate: false
        } else {
            echo "Skipping dblore hdp3 build"
        }
    }
}
parallel_steps_4["step_sqoop-infoworks_hdp3"] = {
    node {
        if ( BUILD_SQOOP ) {
            echo "Building infoworks-sqoop"
            build job: 'sqoop-mvn-build-3.1.x', parameters: [string(name: 'branch', value: "${infoworks_sqoop_branch}"), booleanParam(name: 'skip_tests_flag', value: new Boolean("${skip_tests_flag}")), string(name: 'artifactory_url', value: "${artifactory_url}"), string(name: 'artifactory_dev_repo', value: "${artifactory_dev_repo}"), string(name: 'artifactory_ext_repo', value: "${artifactory_ext_repo}"), booleanParam(name: 'version_branchname', value: new Boolean("${version_branchname}")), string(name: 'git_tags', value: "${git_tags}"), string(name: 'version_in', value: "${version_in}"), string(name: 'hdp_version', value: "3.x")]
        } else {
            echo "Skipping infoworks-sqoop"
        }
    }
}

node {
    if ( BUILD_CUBE_HDP3 ) {
        echo "Building cube"
        build job: 'cube-mvn-build-hdp3-3.1.x', parameters: [string(name: 'branch', value: "${cube_hdp3_branch}"), booleanParam(name: 'skip_tests_flag', value: new Boolean("${skip_tests_flag}")), string(name: 'artifactory_url', value: "${artifactory_url}"), string(name: 'artifactory_dev_repo', value: "${artifactory_dev_repo}"), string(name: 'artifactory_ext_repo', value: "${artifactory_ext_repo}"), booleanParam(name: 'version_branchname', value: new Boolean("${version_branchname}")), string(name: 'git_tags', value: "${git_tags}"), string(name: 'version_in', value: "${version_in}")]
    } else {
        echo "Skipping cube"
    }
}

stage "parallel-build"
parallel parallel_steps_before_pre
parallel parallel_steps_0
parallel parallel_steps_1
parallel parallel_steps_3
parallel parallel_steps_4
