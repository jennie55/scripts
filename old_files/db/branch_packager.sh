#!/bin/bash

#
#  bash script only for the REL_2016.R10 branch in SVN
#  just edit the TOP_REV and BOTTOM_REV and run the script
#  output file is patch.tar
#
#
#
#

BRANCH=REL_2016.R10
TOP_REV=57106
BOTTOM_REV=57099

# adding audit log output
echo "This lists the detected changes between the two revisions, and states whether they were included or not" > auditlog
echo "===========================================" >> auditlog
echo "BRANCH=$BRANCH" >> auditlog
echo "NEW_BRANCH=$NEW_BRANCH" >> auditlog
echo "TOP_REV=$TOP_REV" >> auditlog
echo "BOTTOM_REV=$BOTTOM_REV" >> auditlog
echo "===========================================" >> auditlog


OP=tmp
DIRS=(1_OLTP 2_DW 3_Scoop 4_DevSupport 5_ERD UNIX)

count=0
rejectCount=0
rejectLog="_reject_list.txt"
# clear out the content and only leaving the xml header
echo '<?xml version="1.0"?>' >| ${rejectLog}
echo '<logs>' >> ${rejectLog}

# Remove previous
rm -fr 1_* 2_* 3_* 4_*
rm -fr x_*

# clean slate
rm -fr $OP
mkdir $OP

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

# For each top level 
for P in ${DIRS[@]} 
do
    echo $P

    #svn --quiet checkout -r $TOP_REV https://svn.networkfleet.com/repos/ted3/nwf_db/$P/trunk $P
    svn --quiet checkout -r $TOP_REV https://svn.networkfleet.com/repos/ted3/nwf_db/$P/branches/REL_2016.R10 $P
    #svn --quiet checkout -r $BOTTOM_REV https://svn.networkfleet.com/repos/ted3/nwf_db/$P/trunk x_$P
    svn --quiet checkout -r $BOTTOM_REV https://svn.networkfleet.com/repos/ted3/nwf_db/$P/branches/REL_2016.R10 x_$P
    # 
    diff -q -r $P/ x_$P/ | grep -v ".svn" > differences
    cp differences $P-differences

    while read LINE
    do
       flag=0
       echo "++" $LINE "++"
       FW=$(echo $LINE | cut -d ' ' -f 1)
       echo $FW
       if [ $FW == "Files" ] ; then
          # Files 1_OLTP/3_NCOWN/3_PACKAGE/1_SPEC/ncown.t3_fence_pkg.pks and x_1_OLTP/3_NCOWN/3_PACKAGE/1_SPEC/ncown.t3_fence_pkg.pks differ
          FN=$(echo $LINE | cut -d ' ' -f 2)
          flag=1
       fi
       if [ $FW == "Only" ] ; then
          # Only in 2_DW/3_NCOWN/4_PROCEDURE: ncown.p_new_unit_status_v1.prc
          FP=$(echo $LINE | cut -d ' ' -f 3 | cut -d ':' -f 1)
          FN=$(echo $LINE | cut -d ' ' -f 4-)
          FN="$FP/$FN"
          #echo $LINE
          flag=1
       fi
       if [ "$flag" == "1" ] ; then
          svn_msg=$(svn log -v -l 1 --xml "${FN}"| grep -oP '(?<=\<msg\>).*')
          svn_rev=$(svn log -v -l 1 --xml "${FN}"|grep -oP '(?<=revision=").*?(?=">)')
          echo "SVN msg for ${FN} : ${svn_msg}"
          echo ":: Confirm svn message matched branch: ${BRANCH} :: Copying '${FN}' to $OP"
	  echo "r$svn_rev included: $FN $svn_msg" >> auditlog_temp
          ((count++))
          cp --parents "${FN}" $OP
       fi

    done  < differences

done

echo '</logs>' >> ${rejectLog}
echo ":: For ${NEW_BRANCH} found ${count} files matched"
echo ":: Rejected: ${rejectCount} files. Please see log: ${rejectLog}"
echo ""

CWD=$(pwd)
# importing
for P in ${DIRS[@]}
do
    cd $OP
    if [ -d "$P" ] ; then
        # svn import . https://svn.networkfleet.com/repos/ted3/nwf_db/2_DW/branches/REL_3.45  -m 'Creating branch REL_3.45'
        # svn import . https://svn.networkfleet.com/repos/ted3/nwf_db/1_OLTP/branches/REL_3.45  -m 'Creating branch REL_3.45'
        cd $P
        echo "In " `pwd`
        echo "svn import . https://svn.networkfleet.com/repos/ted3/nwf_db/${P}/branches/${NEW_BRANCH} -m 'Creating new branch ${NEW_BRANCH}'"

    fi
    cd $CWD
done

IFS=$SAVEIFS

sort -r auditlog_temp >> auditlog
rm auditlog_temp


echo "Done."


TEMPDIR=$OP
OUTPUTDIR=output
MODULES=(1_OLTP 2_DW 3_Scoop 4_DevSupport 5_ERD)

SAVEIFS=$IFS; IFS=$(echo -en "\n\b")
rm -rf $OUTPUTDIR; mkdir $OUTPUTDIR 

echo "========================================================================"
echo "*Concatenating SQL files*"

CONCAT_FILE=cat.sql
FILE_LIST=$OUTPUTDIR/files.txt
find ./$TEMPDIR -type f | sort > $FILE_LIST

while read LINE
do
    echo $LINE
    DIR=$(dirname $LINE)
    NEWCONCAT=`echo "$BRANCH/$DIR/$CONCAT_FILE" | sed 's/.\/tmp\///g' | sed 's/\//-/g'`
    echo -e "--CONCAT From $LINE\n" >> $OUTPUTDIR/$NEWCONCAT
    echo -e "prompt *** Starting script file $LINE\n"  >> $OUTPUTDIR/$NEWCONCAT
    cat $LINE >> $OUTPUTDIR/$NEWCONCAT
    echo -e "\n" >>  $OUTPUTDIR/$NEWCONCAT
    echo -e "prompt *** End script file $LINE\n"  >> $OUTPUTDIR/$NEWCONCAT
done < $FILE_LIST

echo "========================================================================"
echo "*Concatenated files*"
ls -1 $OUTPUTDIR/*cat.sql 

for catfile in `ls -1 $OUTPUTDIR/*cat.sql`
do
    echo -e "prompt *** Starting execution of deployment script $catfile\n$(cat $catfile)" > $catfile 
    echo -e "prompt *** Completed execution of deployment script $catfile\n"  >> $catfile 
done

echo "========================================================================"

IFS=$(echo -en "\n\b")

tar -cf patch.tar $TEMPDIR $OUTPUTDIR auditlog

echo "patch.tar was created"

echo "Done"
