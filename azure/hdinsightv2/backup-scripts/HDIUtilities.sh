function download_file
{
    srcurl=$1;
    destfile=$2;
    overwrite=$3;

    if [ "$overwrite" = false ] && [ -e $destfile ]; then
        return;
    fi

    wget -O $destfile -q $srcurl;
}

function untar_file
{
    zippedfile=$1;
    unzipdir=$2;

    if [ -e $zippedfile ]; then
        tar -xf $zippedfile -C $unzipdir;
    fi
}

function test_is_headnode
{
    shorthostname=`hostname -s`
    if [[  $shorthostname == headnode* || $shorthostname == hn* ]]; then
        echo 1;
    else
        echo 0;
    fi
}

function test_is_datanode
{
    shorthostname=`hostname -s`
    if [[ $shorthostname == workernode* || $shorthostname == wn* ]]; then
        echo 1;
    else
        echo 0;
    fi
}

function test_is_zookeepernode
{
    shorthostname=`hostname -s`
    if [[ $shorthostname == zookeepernode* || $shorthostname == zk* ]]; then
        echo 1;
    else
        echo 0;
    fi
}

function test_is_first_datanode
{
    shorthostname=`hostname -s`
    if [[ $shorthostname == workernode0 || $shorthostname == wn0-* ]]; then
        echo 1;
    else
        echo 0;
    fi
}

#following functions are used to determine headnodes.
#Returns fully qualified headnode names separated by comma by inspecting hdfs-site.xml.
#Returns empty string in case of errors.
function get_headnodes
{
    hdfssitepath=/etc/hadoop/conf/hdfs-site.xml
    nn1=$(sed -n '/<name>dfs.namenode.http-address.mycluster.nn1/,/<\/value>/p' $hdfssitepath)
    nn2=$(sed -n '/<name>dfs.namenode.http-address.mycluster.nn2/,/<\/value>/p' $hdfssitepath)

    nn1host=$(sed -n -e 's/.*<value>\(.*\)<\/value>.*/\1/p' <<< $nn1 | cut -d ':' -f 1)
    nn2host=$(sed -n -e 's/.*<value>\(.*\)<\/value>.*/\1/p' <<< $nn2 | cut -d ':' -f 1)

    nn1hostnumber=$(sed -n -e 's/hn\(.*\)-.*/\1/p' <<< $nn1host)
    nn2hostnumber=$(sed -n -e 's/hn\(.*\)-.*/\1/p' <<< $nn2host)

    #only if both headnode hostnames could be retrieved, hostnames will be returned
    #else nothing is returned
    if [[ ! -z $nn1host && ! -z $nn2host ]]
    then
        if (( $nn1hostnumber < $nn2hostnumber )); then
                        echo "$nn1host,$nn2host"
        else
                        echo "$nn2host,$nn1host"
        fi
    fi
}

function get_primary_headnode
{
        headnodes=`get_headnodes`
        echo "`(echo $headnodes | cut -d ',' -f 1)`"
}

function get_secondary_headnode
{
        headnodes=`get_headnodes`
        echo "`(echo $headnodes | cut -d ',' -f 2)`"
}

function get_primary_headnode_number
{
        primaryhn=`get_primary_headnode`
        echo "`(sed -n -e 's/hn\(.*\)-.*/\1/p' <<< $primaryhn)`"
}

function get_secondary_headnode_number
{
        secondaryhn=`get_secondary_headnode`
        echo "`(sed -n -e 's/hn\(.*\)-.*/\1/p' <<< $secondaryhn)`"
}

function is_security_enabled
{
	is_security_enabled=$(echo -e "import hdinsight_common.ClusterManifestParser as ClusterManifestParser\nprint ClusterManifestParser.parse_local_manifest().settings.get('enable_security') == 'true'" | python)
}

function security_features
{
  for domain_info in LDAP_USER LDAP_CLUSTER_ADMIN LDAP_DOMAIN
  do
    temp_key=$(echo -e "import hdinsight_common.ClusterManifestParser as ClusterManifestParser\nfrom hdinsight_common import Constants\nprint ClusterManifestParser.parse_local_manifest().settings[Constants.$domain_info].split('@')[0]" | python)
    if [ "$domain_info" == "LDAP_DOMAIN" ]; then
      temp_key=$(echo "$temp_key" | tr '[:lower:]' '[:upper:]')
    fi
    export $domain_info=$temp_key
  done
}
function secured_password
{
  LDAP_PASSWORD=$(echo -e "import hdinsight_common.ClusterManifestParser as ClusterManifestParser\nfrom hdinsight_common import Constants\nprint ClusterManifestParser.parse_local_manifest().settings[Constants.LDAP_PASSWORD]" | python)
}

function ClusterName
{
  CLUSTERNAME=$(echo -e "import hdinsight_common.ClusterManifestParser as ClusterManifestParser\nprint ClusterManifestParser.parse_local_manifest().deployment.cluster_name" | python)
  if [ $? -ne 0 ]; then
    echo "[ERROR] Cannot determine cluster name. Exiting!"
    exit 133
  fi
}

function ClusterType
{
  CLUSTERTYPE=$(echo -e "import hdinsight_common.ClusterManifestParser as ClusterManifestParser\nfrom hdinsight_common import Constants\nprint ClusterManifestParser.parse_local_manifest().settings[Constants.CLUSTER_TYPE]" | python)
  if [ $? -ne 0 ]; then
    echo "[ERROR] Cannot determine cluster Type. Exiting!"
    exit 134
  fi
}

function create_user
{

    echo "[$(date +"%m-%d-%Y %T")] Creating user $username"
    {
        #check whether the cmd is run by root
        if [ $(whoami) = "root" ]; then
            egrep "^$username" /etc/passwd >/dev/null
            if [ $? -eq 0 ]; then
                echo "$username exists!"
            else
                pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
                useradd -m -p $pass $username
                [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
            fi
            usermod -aG sudo $username || echo "Could not give sudo permission to $username"

        else
            echo "Only root may add a user to the system"
            return 1
        fi

    } || {
        echo 'Could not add user $username' && exit 111
    }
}

echo "${BASH_SOURCE[0]}" > /root/HDIFunc.txt
temp_loc=$(cat /root/HDIFunc.txt)
file_read=$(ls $temp_loc)
cat $file_read | head -n -4 > /tmp/HDIUtilities.sh
