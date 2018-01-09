#!/usr/bin/env python

import argparse

from google.cloud import storage


def list_blobs(bucket_name, prefix=None, delimiter=None):
    blob_list = []
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(bucket_name)

    blobs = bucket.list_blobs(prefix=prefix, delimiter=delimiter)

    print
    print('Blobs:')
    for blob in blobs:
        print(blob.name)
        blob_list.append(blob.name)


    if delimiter:
        print
        print('Folders:')
        for prefix in blobs.prefixes:
            print(prefix)

    return blob_list


def download_blob(bucket_name, source_file_name, source_path, destination_path, delimiter):
    """Downloads a blob from the bucket."""
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(bucket_name)

    if not source_file_name:
        blob_list = list_blobs(bucket_name, source_path, delimiter)    
        for blob_name in blob_list:
            print blob_name
	    file_name = blob_name.split("/")[-1]
	
	    if file_name:
                blob = bucket.blob(blob_name)
                blob.download_to_filename(destination_path+file_name)
    else:
        source_path=source_file_name
	blob = bucket.blob(source_file_name)
        blob.download_to_filename(destination_path+source_file_name)
	
    print('Blob {} downloaded to {}'.format(
        source_path,
        destination_path))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('bucket_name', help='Your cloud storage bucket.')

    subparsers = parser.add_subparsers(dest='command')

    list_parser = subparsers.add_parser('list', help=list_blobs.__doc__)
    list_parser.add_argument('--source_path', default=None)
    list_parser.add_argument('--delimiter', default=None)

    download_parser = subparsers.add_parser(
        'download', help=download_blob.__doc__)
    download_parser.add_argument('--filename', default=None)
    download_parser.add_argument('--source_path', default=None)
    download_parser.add_argument('destination_path')
    download_parser.add_argument('--delimiter', default=None)
    
    args = parser.parse_args()

    if args.command == 'list':
	if (args.delimiter and args.source_path and not args.source_path.endswith('/')):
	    args.source_path = args.source_path+'/'

        list_blobs(args.bucket_name, args.source_path, args.delimiter)
    elif args.command == 'download':
	if (args.source_path and not args.source_path.endswith('/')):
	    args.source_path = args.source_path+'/'
	if (args.destination_path and not args.destination_path.endswith('/')):
	    args.destination_path = args.destination_path+'/'

        download_blob(
            args.bucket_name,
	    args.filename,
            args.source_path,
            args.destination_path,
	    args.delimiter)