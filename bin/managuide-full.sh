source variables.txt

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