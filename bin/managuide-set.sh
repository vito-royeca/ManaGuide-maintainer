echo -n "Delete status.txt? [Y/n] "
read answer

if [ "$answer" != "${answer#[Y]}" ] ;then
    find /path/to/managuide_images/cards/$1 -type f -name "status.txt" -exec rm -fvr {} \;
fi

read -d '' command << EOF
/usr/local/bin/ManaGuide-maintainer \
  --host host \
  --port 5432 \
  --database database \
  --user user \
  --password password \
  --full-update true \
  --images-path /path/to/managuide_images/cards \
  --set-name $1 && \
psql -h host -U user -c \
  "update cmset set is_images_redownloaded = true, date_updated = now() where code = '$1'" \
  database
EOF
eval " $command"
while [ $? -ne 0 ]; do
    eval " $command"
done

# delete temp files
rm /tmp/managuide-*
