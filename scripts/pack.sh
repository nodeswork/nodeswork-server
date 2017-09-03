#!/bin/sh

rm *.tgz
rm *.zip
zipPath=`npm pack`

tmpDir=`mktemp -d`

echo $zipPath

tar -xvzf $zipPath -C $tmpDir

cp ./config/secrets.yaml $tmpDir/package/config
cp ./config/prod/secrets.yaml $tmpDir/package/config/prod
cp ./package-lock.json $tmpDir/package

rm $zipPath
finalPath="$(basename $zipPath .tgz).zip"

rm -f $finalPath

cur=`pwd`

cd $tmpDir/package

zip -r $cur/$finalPath *

cd $cur

echo $finalPath

rm -rf tmpDir

mv $finalPath ../releases
