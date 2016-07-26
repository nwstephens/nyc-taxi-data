#!/bin/sh

# Transfer CSV files to S3 (220 GB)
# Transfer parquet files to S3 (83 GB)

s3bucket=spark-nyc-taxi-data

echo "Transfer csv files to S3"
aws s3 cp csv s3://$s3bucket/csv/ --recursive

echo "Transfer parquet files to S3"
aws s3 cp parquet s3://$s3bucket/parquet/ --recursive

#Transfer individal files to S3
#for file_path in psqldata/trips/*.csv; do
#  file_name=$(basename "$file_path")
#  echo "$(date) $file_path"
#  aws s3 cp $file_path s3://$s3bucket/csv/trips/$file_name
#done
