CardsDir=/path/to/managuide_images/cards
SetDir=$CardsDir/$1
BeforeFindResult=$(find $SetDir -name status.json | wc -l)

echo -n "Delete status files? [Y/n] "
read answer

if [ "$answer" != "${answer#[Yy]}" ] ;then
    find $SetDir -type f -name "status.*" -exec rm -fvr {} \;
fi

read -d '' command << EOF
/usr/local/bin/ManaGuide-maintainer \
  --host host \
  --port 5432 \
  --database database \
  --user user \
  --password password \
  --full-update true \
  --images-path $CardsDir \
  --set-name $1 && \
psql -h host -U user -w -c \
  "update cmset set is_images_redownloaded = true, date_updated = now() where code = '$1'" \
  database
EOF
eval " $command"
while [ $? -ne 0 ]; do
    eval " $command"
done

# delete temp files
rm /tmp/managuide-*

AfterFindResult=$(find $SetDir -name status.json | wc -l)
echo "Before: ${BeforeFindResult} status.json files"
echo "After:  ${AfterFindResult} status.json files"
