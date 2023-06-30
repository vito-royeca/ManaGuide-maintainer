/usr/local/bin/managuide \
  --host host \
  --port 5432 \
  --database database \
  --user user \
  --password password \
  --full-update false \
  --images-path /path/to/managuide_images/cards

# delete temp files
find /tmp -name "managuide-*" -exec rm -fv {} \;
