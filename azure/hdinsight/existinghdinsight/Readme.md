# Deploy an empty edge node to a HDInsight cluster.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FInfoworks%2Fdeployments%2Fmaster%2Fazure%2Fhdinsight%2Fexistinghdinsight%2FmainTemplate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

This template allows you to add an empty edge node to an existing HDInsight cluster . An empty edge node is a Linux virtual machine with the same client tools installed and configured as in the headnodes. You can use the edge node for accessing the cluster, testing your client applications, and hosting your client applications.

The empty edge node virtual machine size must meet the worker node vm size requirements. The worker node vm size requirements are different from region to region. For more information, see Create HDInsight clusters.

The template uses a simple script to simulate infoworks application installation and prepare edgenode and attach it to the cluster.
