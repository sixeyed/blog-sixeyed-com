---
title: Configure an HDInsight HBase cluster that doesn't keep going BANG! with 502s
date: '2015-09-14 08:54:35'
tags:
- hbase
- hdinsight
- powershell
---

Running a massively scalable NoSQL database in the cloud is super easy, but not cheap if you want to run it 24x7. The managed offering from Azure - a [dedicated HDInsight cluster type](https://azure.microsoft.com/en-us/documentation/articles/hdinsight-hbase-overview/) running [Apache HBase](https://hbase.apache.org/) - almost gives you the best of both worlds.

> The cluster uses Azure Blob Storage for its HDFS-compatible file system, so when you delete your cluster, the data is retained. Fire up a new cluster later on using the existing storage account, and you can carry on reading and writing from the same tables.

If you don't need your database running permanently (like if you have bursty incoming data, or you need to produce stats on a daily or weekly schedule, rather than realtime), you can save a lot of compute power and cloud spend by creating your HBase cluster just when you need to run your analysis, and deleting it afterwards.

The [HBase SDK for .NET](https://github.com/hdinsight/hbase-sdk-for-net) is a wrapper around the standard HBase REST API, and it has all the core features - for putting, getting and scanning cell values. You can insert/update a value in a column family with simple code like this:

    var set = new CellSet(); 
    var row = new CellSet.Row { key = rowKeyBytes }; 
    set.rows.Add(row);
    
    var value = new Cell 
    { 
      column = Encoding.UTF8.GetBytes(columnFamilyName + ":" + columnName), 
      data = BitConverter.GetBytes(increment) 
    }; 
    row.values.Add(value); 
    _client.StoreCells(TableName, set);

_StoreCells_ is the client equivalent of a PUT command, and HBase works out if it needs to create a column or a row, or update an existing value.

Super easy, but there's an issue with the current HBase deployment on HDInsight. The details are on Apache's Jira ticket [HADOOP-11693](https://issues.apache.org/jira/browse/HADOOP-11693), basically when HBase archives data it pushes Azure Blob Storage too hard and the storage account gets throttled. The impact is your HBase client calls fail with a 502 Bad Gateway exception and an ugly stack trace:

    System.Net.WebException: The remote server returned an error: (502) Bad Gateway. at System.Net.HttpWebRequest.EndGetResponse(IAsyncResult asyncResult) at System.Threading.Tasks.TaskFactory`1.FromAsyncCoreLogic(IAsyncResult iar, Func`2 endFunction, Action`1 endAction, Task`1 promise, Boolean requiresSynchronization)--- End of stack trace from previous location where exception was thrown --- at System.Runtime.CompilerServices.TaskAwaiter.ThrowForNonSuccess(Task task) at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task) at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult() at Microsoft.HBase.Client.WebRequesterSecure.<issuewebrequestasync>d__0.MoveNext()</issuewebrequestasync>

Until the proper fix comes into the next HDInsight release, the workaround is to configure HBase to use a more generous retry limit when it copies blobs (which it does as part of the archive routine). You need to set the property **fs.azure.io.copyblob.retry.max.retries** to the suggested value **30** in the main Hadoop config file, _core-site.xml_.

The workaround is suggested on MSDN here – [502 Error in HBase Cluster](https://social.msdn.microsoft.com/Forums/en-US/c6bd04e9-e69b-4e96-b2ef-fa8abcf3bbc3/502-error-in-hbase-cluster?forum=hdinsight) – but without explaining how to set it up, so here's a complete PowerShell script that does it for you, creating a 502-free HBase cluster on HDInsight in one go:

    #build secure credential for RDP access
    $securePassword = ConvertTo-SecureString 'myG00dP%$$W067' -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential('admin',$securePassword)  
    
    #custom config - fix HBase 502 errors
    $coreConfig = @{ "fs.azure.io.copyblob.retry.max.retries"="30"; }
    $clusterConfig = New-AzureHDInsightClusterConfig -ClusterSizeInNodes 4 -ClusterType HBase
    $clusterConfig = $clusterConfig | Add-AzureHDInsightConfigValues -Core $coreConfig 
    $clusterConfig = $clusterConfig | Set-AzureHDInsightDefaultStorage -StorageAccountName 'yourstorageaccount.blob.core.windows.net' -StorageAccountKey 'your-key' -StorageContainerName 'your-hbase-cluster-name'
    
    New-AzureHDInsightCluster `
      -Name 'your-hbase-cluster-name' `
      -Credential $credential `
      -Location 'North Europe' `
      -Config $clusterConfig `
      -Verbose `
      -ErrorAction Stop

The key part is the [Add-AzureHDInsightConfigValues](https://msdn.microsoft.com/en-us/library/dn593759.aspx) cmdlet, which lets you add custom settings to various Hadoop config files, Core being used for core-site.xml.

This script is repeatable too, so you can delete your cluster when processing finishes, then run this script again later to provision a new cluster which will have all your old data.

<!--kg-card-end: markdown-->