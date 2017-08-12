#!/bin/bash
## This will download the lists

## Variables
script_dir=$(dirname $0)
SCRIPTVARSDIR="$script_dir"/scriptvars/
STATICVARS="$SCRIPTVARSDIR"variables.var
if
[[ -f $STATICVARS ]]
then
source $STATICVARS
else
echo "Vars File Missing, Exiting."
exit
fi

## Process Every .lst file within the List Directories
for f in $ALLSTFILES
do

printf "$blue"    "$DIVIDERBAR"
echo ""

BASEFILENAME=$(echo `basename $f | cut -f 1 -d '.'`)
DOWNLOADEDFILE="$DOWNLOADEDDIR""$BASEFILENAME".txt
COMPRESSEDTEMPTAR="$TEMPDIR""$BASEFILENAME".tar.gz
EXTRACTEDTARDIR="$TEMPDIR""$BASEFILENAME"/
EXTRACTEDDOMAINS="$EXTRACTEDTARDIR"domains

printf "$green"    "Processing $BASEFILENAME List."
echo "" 

## Process Every source within the .lst from above
for source in `cat $f`;
do

UPCHECK=`echo $source | awk -F/ '{print $3}'`

printf "$cyan"    "The Source In The File Is:"
printf "$yellow"    "$source"
echo "" 

## Check to see if source's host is online
if
[[ -n $UPCHECK ]]
then
SOURCEIPFETCH=`ping -c 1 $UPCHECK | gawk -F'[()]' '/PING/{print $2}'`
SOURCEIP=`echo $SOURCEIPFETCH`
elif
[[ -z $UPCHECK ]]
then
printf "$red"    "$BASEFILENAME Host Unavailable."
fi
if
[[ -n $SOURCEIP ]]
then
printf "$green"    "Ping Test Was A Success!"
elif
[[ -z $SOURCEIP ]]
then
printf "$red"    "Ping Test Failed."
PINGTESTFAILED=true
fi
echo ""

## Check if file is modified since last download
if 
[[ -f $DOWNLOADEDFILE && -z $PINGTESTFAILED ]]
then
SOURCEMODIFIEDLAST=$(curl --silent --head $source | awk -F: '/^Last-Modified/ { print $2 }')
SOURCEMODIFIEDTIME=$(date --date="$SOURCEMODIFIEDLAST" +%s)
LOCALFILEMODIFIEDLAST=$(stat -c %z "$DOWNLOADEDFILE")
LOCALFILEMODIFIEDTIME=$(date --date="$LOCALFILEMODIFIEDLAST" +%s)
DIDWECHECKONLINEFILE=true
fi

if
[[ -n $DIDWECHECKONLINEFILE && $LOCALFILEMODIFIEDTIME -lt $SOURCEMODIFIEDTIME ]]
then
printf "$yellow"    "File Has Changed Online."
elif
[[ -n $DIDWECHECKONLINEFILE && $LOCALFILEMODIFIEDTIME -ge $SOURCEMODIFIEDTIME ]]
then
FULLSKIPPARSING=true
printf "$green"    "File Not Updated Online. No Need To Process."
fi

if
[[ -z $FULLSKIPPARSING && $source == *.tar.gz && -n $SOURCEIP ]]
then
printf "$cyan"    "Fetching Tar List From $UPCHECK Located At The IP Of "$SOURCEIP"."
wget -q -O $COMPRESSEDTEMPTAR $source
tar -xavf $COMPRESSEDTEMPTAR -C "$TEMPDIR"
fi

if
[[ -z $FULLSKIPPARSING && -f $EXTRACTEDDOMAINS ]]
then
mv $EXTRACTEDDOMAINS $DOWNLOADEDFILE
fi

if
[[ -z $FULLSKIPPARSING && -f $COMPRESSEDTEMPTAR ]]
then
rm $COMPRESSEDTEMPTAR
fi

if
[[ -d "$EXTRACTEDTARDIR" ]]
then
rm -r $EXTRACTEDTARDIR
fi

if
[[ -z $FULLSKIPPARSING && -f $DOWNLOADEDFILE ]]
then
FETCHFILESIZE=$(stat -c%s "$DOWNLOADEDFILE")
HOWMANYLINES=$(echo -e "`wc -l $DOWNLOADEDFILE | cut -d " " -f 1`")
ENDCOMMENT="$HOWMANYLINES Lines After Download."
printf "$yellow"  "$ENDCOMMENT"
fi

if
[[ -z $FULLSKIPPARSING && $FETCHFILESIZE == 0 ]]
then
FILESIZEZERO=true
fi

if 
[[ -z $FULLSKIPPARSING && -n $FILESIZEZERO ]]
then
printf "$red"     "Not Creating Downloaded File. Nothing To Create!"
rm $DOWNLOADEDFILE
fi

done

printf "$magenta" "$DIVIDERBAR"
echo ""

unset FULLSKIPPARSING
unset FILESIZEZERO

done

printf "$green"   "Pushing Lists to Github"
timestamp=$(echo `date`)
git -C $REPODIR remote set-url origin $GITWHERETOPUSH
git -C $REPODIR add .
git -C $REPODIR commit -m "Update lists $timestamp"
git -C $REPODIR push -u origin master
