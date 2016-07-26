# This scipt will convert all csv files from the nyc-taxi-data schema into parquet files.
# This script depends on csv2parquet.py (script https://github.com/redsymbol/csv2parquet).
# Make sure you install python 3.5 and Apache Drill (embeded mode) first.

# Warning: csv2parquet.py will not run in parallel either as the same user or multiple users.
# Warning: csv2parquet.py will not run from within a shell script; you must run these commands in interactive mode.

# Files output to the following directory structure:
#    ./parquet/trips
#    ./parquet/other
#    ./parquet/analysis
#    ./parquet/postgis


for file_path in parquet/analysis/*.csv; do
  file_name=$(basename "$file_path")
  file_name="${file_name%.*}"
  echo "$(date) $file_path"
  python3.5 ./csv2parquet.py $file_path parquet/analysis/$file_name
done

for file_path in parquet/other/*.csv; do
  file_name=$(basename "$file_path")
  file_name="${file_name%.*}"
  echo "$(date) $file_path"
  python3.5 ./csv2parquet.py $file_path parquet/other/$file_name
done

for file_path in parquet/postgis/*.csv; do
  file_name=$(basename "$file_path")
  file_name="${file_name%.*}"
  echo "$(date) $file_path"
  python3.5 ./csv2parquet.py $file_path parquet/postgis/$file_name
done

for file_path in parquet/trips/*.csv; do
  file_name=$(basename "$file_path")
  file_name="${file_name%.*}"
  echo "$(date) $file_path"
  python3.5 ./csv2parquet.py $file_path parquet/trips/$file_name
done

