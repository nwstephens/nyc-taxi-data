*This code has been forked from Todd Schneider's [NYC Taxi Data](https://github.com/toddwschneider/nyc-taxi-data). Use these scripts if you want to use the NYC taxi data with Apache Spark. I've added a few scripts to export the postgres tables into parquet files using [csv2parquey.py](https://github.com/redsymbol/csv2parquet). See the [Convert to Parquet](#convert-to-parquet) section for details below.*

# Unified New York City Taxi and Uber data

Code in support of this post: [Analyzing 1.1 Billion NYC Taxi and Uber Trips, with a Vengeance](http://toddwschneider.com/posts/analyzing-1-1-billion-nyc-taxi-and-uber-trips-with-a-vengeance/)

This repo provides scripts to download, process, and analyze data for over 1.1 billion taxi and Uber trips originating in New York City. The data is stored in a [PostgreSQL](http://www.postgresql.org/) database, and uses [PostGIS](http://postgis.net/) for spatial calculations, in particular mapping latitude/longitude coordinates to census tracts.

The [yellow and green taxi data](http://www.nyc.gov/html/tlc/html/about/trip_record_data.shtml) comes from the NYC Taxi & Limousine Commission, and [Uber data](https://github.com/fivethirtyeight/uber-tlc-foil-response) comes via FiveThirtyEight, who obtained it via a FOIL request.

## Instructions

Your mileage may vary, but on my MacBook Air, this process took about 3 days to complete. The unindexed database takes up 267 GB on disk. Adding indexes for improved query performance increases total disk usage to 375 GB.

##### 1. Install [PostgreSQL](http://www.postgresql.org/download/) and [PostGIS](http://postgis.net/install)

Both are available via [Homebrew](http://brew.sh/) on Mac OS X

##### 2. Download raw taxi data

`./download_raw_data.sh`

##### 3. Initialize database and set up schema

`./initialize_database.sh`

##### 4. Import taxi data into database and map to census tracts

`./import_trip_data.sh`

##### 5. Optional: download and import Uber data from FiveThirtyEight's GitHub repository

`./download_raw_uber_data.sh`
<br>
`./import_uber_trip_data.sh`

##### 6. Analysis

Additional Postgres and [R](https://www.r-project.org/) scripts for analysis are in the <code>analysis/</code> folder, or you can do your own!

## Schema

- `trips` table contains all yellow and green taxi trips, plus Uber pickups from April 2014 through September 2014. Each trip has a `cab_type_id`, which references the `cab_types` table and refers to one of `yellow`, `green`, or `uber`. Each trip maps to a census tract for pickup and dropoff
- `nyct2010` table contains NYC census tracts, plus a fake census tract for the Newark Airport. It also maps census tracts to NYC's official neighborhood tabulation areas
- `uber_trips_2015` table contains Uber pickups from January 2015 through June, 2015. These are kept in a separate table because they don't have specific latitude/longitude coordinates, only location IDs. The location IDs are stored in the `uber_taxi_zone_lookups` table, which also maps them (approximately) to neighborhood tabulation areas
- `central_park_weather_observations` has summary weather data by date

## Other data sources

These are bundled with the repository, so no need to download separately, but:

- Shapefile for NYC census tracts and neighborhood tabulation areas comes from [Bytes of the Big Apple](http://www.nyc.gov/html/dcp/html/bytes/districts_download_metadata.shtml)
- Central Park weather data comes from the [National Climatic Data Center](http://www.ncdc.noaa.gov/)

## Data issues encountered

- Remove carriage returns and empty lines from TLC data before passing to Postgres `COPY` command
- `green` taxi raw data files have extra columns with empty data, had to create dummy columns `junk1` and `junk2` to absorb them
- Two of the `yellow` taxi raw data files had a small number of rows containing extra columns. I discarded these rows
- The official NYC neighborhood tabulation areas (NTAs) included in the shapefile are not exactly what I would have expected. Some of them are bizarrely large and contain more than one neighborhood, e.g. "Hudson Yards-Chelsea-Flat Iron-Union Square", while others are confusingly named, e.g. "North Side-South Side" for what I'd call "Williamsburg", and "Williamsburg" for what I'd call "South Williamsburg". In a few instances I modified NTA names, but I kept the NTA geographic definitions
- The shapefile includes only NYC census tracts. Trips to New Jersey, Long Island, Westchester, and Connecticut are not mapped to census tracts, with the exception of the Newark Airport, for which I manually added a fake census tract
- The Uber 2015 data uses location IDs instead of latitude/longitude. The location IDs do not exactly overlap with the NYC neighborhood tabulation areas (NTAs) or census tracts, but I did my best to map Uber location IDs to NYC NTAs

## Why not use BigQuery or Redshift?

[Google BigQuery](https://cloud.google.com/bigquery/) and [Amazon Redshift](https://aws.amazon.com/redshift/) would probably provide significant performance improvements over PostgreSQL. A lot of the data is already available on BigQuery, but in scattered tables, and each trip has only by latitude and longitude coordinates, not census tracts and neighborhoods. PostGIS seemed like the easiest way to map coordinates to census tracts. Once the mapping is complete, it might make sense to load the data back into BigQuery or Redshift to make the analysis faster. Note that BigQuery and Redshift cost some amount of money, while PostgreSQL and PostGIS are free.

## TLC summary statistics

There's a Ruby script in the `tlc_statistics/` folder to import data from the TLC's [summary statistics reports](http://www.nyc.gov/html/tlc/html/about/statistics.shtml):

`ruby import_statistics_data.rb`

## Questions/issues/contact

todd@toddwschneider.com, or open a GitHub issue

***

# Convert to Parquet

Use these files if you're interested in using they NYC taxi data with Apache Spark.

## Overview

Parquet is the default data source in Apache Spark (unless otherwise configured). Parquet makes the advantages of compressed, efficient columnar data representation available to any project in the Hadoop ecosystem.

I have added three scipts that move the post joined NYC taxi data in postgres to S3 in the Apache Parquet format.

1. `export_psql_tables_to_csv.sh`. Export every table created in Todd Schneider's postgres implementation to csv files.
2. `convert_csv_files_to_parquet.sh`. Convert csv files to parquet with the help of `csv2parquet.py` (see details below). 
3. `transfer_files_to_S3.sh`. Load data into your S3 bucket.

Step 1 (exporting the tables to CSV) consumes about 220 GB of disk space and takes roughly 7 hours. There are 83 months in the trips table and every month takes about 5 minutes to export. 

Step 2 (converting csv to parquet) consumes about 83 GB of disk space and takes a few hours. I ran this script in interactive mode since I wasn't able to `csv2parquet` from within a shell script.

Step 3 (transferring files to S3) takes less than 30 minutes. Note that I transferred both csv and parquet files into S3.

## csv2parquet

This simple tool creates Parquet files from CSV input, using a minimal installation of Apache Drill. The tool requires that you install Oracle JDK version 7, Apache Drill, and Python 3.5 (or later).

You can install Drill in embedded mode or distributed mode. Since I ran the conversion on a single ec2 instance, I chose to install the embedded mode. At the time of this writing, Drill recommends you install Oracle JDK version 7.

The `csv2parquet` script recommends Python 3.5 (or later). I found that calling `python3.5` directly in my scripts avoided any confusion about what version of python I was running.

Finally, I added the following lines to my `~/.bash_profile`:

    PATH=$PATH:/opt/drill/apache-drill-1.7.0/bin
    export JAVA_HOME=/usr/lib/jvm/java-7-oracle

I encountered a few issues when trying to use csv2parquet on a large number of files.

* `csv2parquet` will not run in parallel either as the same user or as multiple users. Even in embedded mode, Drill runs in a stateful fashion. This script creates a whole parallel Drill installation under a temporary directory which is all cleaned up after the script exits. When you attempt to run multiple file conversions in parallel, the scripts will fail.
* `csv2parquet` will not complete if called from inside a shell script. `convert_csv_files_to_parquet.sh` should therefore be run in intereactive mode as opposed to be called as an executible. There is probably a good way around this, but I did not want to spend the time working through the code.

## Data issues

* As noted by [data issues encountered](#data-issues-encountered), two files (`nyc_taxi_trips_2010-02.csv` and `nyc_taxi_trips_2010-03.csv`) had a small number of rows containing extra columns. These records must manually be deleted before loading them into postgres. Refer to `fix_files_that_load_with_errors.Rmd` to see how.
* The `central_park_weather_observations` table in postgres had to be downloaded using the `\copy(select * from)` format. This modification has already been included and documented in the code, `export_psql_tables_to_csv.sh`.

## Questions/issues/contact

nwstephens@gmail.com, or open a GitHub issue.
