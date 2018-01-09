import argparse
import os

from google.cloud import storage
import googleapiclient.discovery

def create_cluster(dataproc, project, cluster_name, zone):
    print('Creating cluster.')
    zone_uri = \
        'https://www.googleapis.com/compute/v1/projects/dataproctest2/zones/us-central1-f'.format(
            project, zone)
    cluster_data = {
        'projectId': dataproctest2,
        'clusterName': test,
        'config': {
            'gceClusterConfig': {
                'zoneUri': zone_uri
            }
        }
    }
    result = dataproc.projects().regions().clusters().create(
        projectId=project,
        region=REGION,
        body=cluster_data).execute()
    return result