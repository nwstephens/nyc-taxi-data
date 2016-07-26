#!/bin/sh

# This scipt will output all tables from the nyc-taxi-data schema into csv files.

# Files output to the following directory structure:
#    ./csv/trips
#    ./csv/other
#    ./csv/analysis
#    ./csv/postgis

# Export the trips table (by month)

dbname=mydb

echo "Export trips tables to CSV"

DATE_BEG=2009-01-01
DATE_END=2009-02-01

for i in `seq 1 84`
do

   FILE_OUT=./csv/trips/nyc_taxi_trips_$(date +%Y-%m -d $DATE_BEG).csv
   echo "$i $(date) from $DATE_BEG to $DATE_END >> $FILE_OUT"

   psql nyc-taxi-data -h $dbname -c "\COPY ( \
	select id, cab_type_id, vendor_id,pickup_datetime, dropoff_datetime, store_and_fwd_flag, \
		rate_code_id, pickup_longitude, pickup_latitude, dropoff_longitude, dropoff_latitude, \
		passenger_count, round(trip_distance,2) as trip_distance, round(fare_amount,2) as fare_amount, extra, \
		mta_tax, round(tip_amount,2) as tip_amount, round(tolls_amount,2) as tolls_amount, ehail_fee, \
		improvement_surcharge, round(total_amount,2) as total_amount, payment_type, trip_type, \
		pickup_nyct2010_gid, dropoff_nyct2010_gid \
	from trips \
	where pickup_datetime >= '$DATE_BEG' and pickup_datetime < '$DATE_END') \
	To '$FILE_OUT' WITH CSV HEADER;"

   DATE_BEG=$(date +%Y-%m-%d -d "$DATE_BEG + 1 month")
   DATE_END=$(date +%Y-%m-%d -d "$DATE_END + 1 month")

done

# Export other tables in the NYC taxi schema

echo "Export other NYC taxi schema tables to CSV"
for tbl in uber_trips_2015 cab_types nyct2010 spatial_ref_sys; do
echo "$(date) $tbl"
psql nyc-taxi-data -h $dbname -c "\COPY $tbl To 'csv/other/$tbl.csv' WITH CSV HEADER;" 
done

echo "Export reference tables included in github repos to CSV"
psql nyc-taxi-data -h $dbname -c "\COPY (select * from central_park_weather_observations) To 'csv/other/central_park_weather_observations.csv' WITH CSV HEADER;" 
psql nyc-taxi-data -h $dbname -c "\COPY (select * from uber_taxi_zone_lookups) To 'csv/other/uber_taxi_zone_lookups.csv' WITH CSV HEADER;" 

# Export aggregated tables created in the analysis.sql file that do not require postgis joins

echo "Export analysis tables to CSV"
for tbl in hourly_pickups hourly_dropoffs hourly_uber_2015_pickups daily_pickups_by_borough_and_type daily_dropoffs_by_borough pickups_comparison census_tract_pickup_growth_2009_2015 pickups_and_weather trips_by_lat_long_cab_type dropoff_by_lat_long_cab_type census_tract_pickups_by_hour airport_trips airport_trips_summary airport_pickups airport_pickups_by_type bridge_and_tunnel northside_pickups northside_dropoffs payment_types; do
echo "$(date) $tbl"
psql nyc-taxi-data -h $dbname -c "\COPY $tbl To 'csv/analysis/$tbl.csv' WITH CSV HEADER;" 
done

# Export aggregated tables created in the analysis.sql file that require postgis joins

echo "Export analysis tables requiring postgis joins to CSV"
for tbl in nyct2010_centroids neighborhood_centroids custom_geometries goldman_sachs_dropoffs citigroup_dropoffs die_hard_3; do
echo "$(date) $tbl"
psql nyc-taxi-data -h $dbname -c "\COPY $tbl To 'csv/postgis/$tbl.csv' WITH CSV HEADER;" 
done

echo "done"


