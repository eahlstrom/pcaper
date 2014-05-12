#!/bin/bash

files="tcpdump mergecap ra racluster lsof capinfos argus"
linkdir=`dirname $0`

for f in $files
do
  if [ -f "$linkdir/$f" ]; then
    continue
  fi
  fqn=`type -p $f`
  if [ $? -ne 0 ]; then
    echo "Cannot find required binary: \"$f\" (you need to install it and add it to your PATH)"
    exit 1
  fi

  echo "ln -s $fqn $linkdir"
  ln -s $fqn $linkdir
done
