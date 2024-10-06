for ARGUMENT in "$@"
do
   KEY=$(echo $ARGUMENT | cut -f1 -d=)

   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+1}"

   export "$KEY"="$VALUE"
done

.build/release/managuide \
  --host $host \
  --port $port \
  --database $database \
  --user $user \
  --password $password \
  --full-update $fullUpdate \
  --images-path $imagesPath

# delete temp files
find /tmp -name "managuide-*" -exec rm -fv {} \;
find /tmp -name "*.json" -exec rm -fv {} \;
