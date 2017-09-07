#!/bin/bash

#
#  Creates a list of files that differ from two revisions of trunk and creates a branch (NEW_BRANCH)
#  to check them into Subversion.
#

BRANCH=3.52
NEW_BRANCH=REL_2016.R10
TOP_REV=57004
BOTTOM_REV=56445

# adding audit log output
echo "This lists the detected changes between the two revisions, and states whether they were included or not" > auditlog
echo "===========================================" >> auditlog
echo "BRANCH=$BRANCH" >> auditlog
echo "NEW_BRANCH=$NEW_BRANCH" >> auditlog
echo "TOP_REV=$TOP_REV" >> auditlog
echo "BOTTOM_REV=$BOTTOM_REV" >> auditlog
echo "===========================================" >> auditlog


OP=./tmp


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

    svn --quiet checkout -r $TOP_REV https://svn.networkfleet.com/repos/ted3/nwf_db/$P/trunk $P
    svn --quiet checkout -r $BOTTOM_REV https://svn.networkfleet.com/repos/ted3/nwf_db/$P/trunk x_$P
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
          if [[ $svn_msg == "${BRANCH}"* ]] ; then
             echo ":: Confirm svn message matched branch: ${BRANCH} :: Copying '${FN}' to $OP"
	     echo "r$svn_rev included: $FN $svn_msg" >> auditlog_temp
             ((count++))
             cp --parents "${FN}" $OP
          else
             echo "SVN message version MISMATCHED - no copy"
	     echo "$svn_rev ***skipped: $FN $svn_msg" >> auditlog_temp
             ((rejectCount++))
             svn log -v -l 1 --xml "${FN}" | grep -v '<\?xml' >> ${rejectLog}
          fi
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
