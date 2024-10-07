#!/bin/sh

echo host $host
echo port $port
echo database $database
echo user $user
echo password $password
echo full-update $fullUpdate
echo images-path $imagesPath

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