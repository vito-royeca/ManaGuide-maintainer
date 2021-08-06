read -d '' command << EOF
/usr/local/bin/ManaGuide-maintainer \
  --host host \
  --port 5432 \
  --database database \
  --user user \
  --password password \
  --full-update true \
  --images-path /path/to/managuide_images/cards
EOF
eval " $command"
while [ $? -ne 0 ]; do
    eval " $command"
done

# delete temp files
rm /tmp/managuide-*
