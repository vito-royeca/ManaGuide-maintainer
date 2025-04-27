#! /bin/bash

. .config

read -d '' command << EOF
/usr/local/bin/managuide \
  --host $host \
  --port $port \
  --database $database \
  --user $user \
  --password $password \
  --full-update $full_update \
  --images-path $images_path
EOF
eval " $command"
while [ $? -ne 0 ]; do
    eval " $command"
done

# delete temp files
find /tmp -name "managuide-*" -exec rm -fv {} \;
