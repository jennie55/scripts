#!/bin/bash

# 5/18/16 - RB - updated to provide long file names to concatenated sql files
# 5/24/16 - RB - display svn status and prompt before committing to SVN 

#BRANCH=REL_3.43.3
BRANCH=$1
if [ -z "$BRANCH" ] ; then
    echo "A branch name is required (i.e.: REL_3.43.3)"
    exit 4
fi

OP=./tmp
FILE_LIST=files.txt
CONCAT_FILE=cat.sql
USR_CONCAT=user-concat.txt

# checkout scripts into a single workspace 
rm -rf $OP
svn co https://svn.networkfleet.com/repos/ted3/nwf_db $OP --depth empty
pushd .
cd $OP 
for MODULE in 1_OLTP 2_DW 3_Scoop 4_DevSupport
do   
    svn update --set-depth empty $MODULE   
    svn update --set-depth empty $MODULE/branches   
    svn update --set-depth infinity $MODULE/branches/$1
done
popd 

# Remove previous concatenated files
rm `find $OP -name concatenated.txt`
rm `find $OP -name *${CONCAT_FILE}`
rm `find $OP -name ${USR_CONCAT}`

# Get a list of files and filter out the SVN directories
find $OP -type f | grep -v ".svn" | sort > $FILE_LIST

# 
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")


PREV_DIR=""
while read LINE 
do
    FNAME=$(basename $LINE)
    DIR=$(dirname $LINE)

    # construct a unique SQL file name using the directory path
    NEWCONCAT=`echo "$BRANCH/$PREV_DIR/$CONCAT_FILE" | sed 's/.\/tmp\///g' | sed 's/\//-/g' | sed 's/-branches-'$BRANCH'//g'`

    echo $LINE

    if [ -n "$PREV_DIR" ] ; then
        if [ "$DIR" != "$PREV_DIR" ] ; then
            #cat $PREV_DIR/* > $CONCAT_FILE
            rm -f *$CONCAT_FILE
            for FC in `ls -v $PREV_DIR/*`
            do
                BFC=$(basename $FC)
                echo -e "-- From $BFC\n" >> $NEWCONCAT
                cat $FC >> $NEWCONCAT
                echo -e "\n" >>  $NEWCONCAT
            done

            mv $NEWCONCAT $PREV_DIR

            pushd .
            cd $PREV_DIR
            svn add $NEWCONCAT 
            popd
        fi 
    fi

    PREV_DIR=$DIR
done < $FILE_LIST

# prompt before committing changes to SVN
cd $OP
clear
echo
echo "These files will be modified:"
echo
svn status
echo
read -p "Do you want to commit changes to SVN? [y/n]" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    svn commit -m "concatenated the sql files" 
fi
cd ..

exit 0

# Second step: to the same for 
for SUBDIR in ${DIRS[@]} 
do
   # if directory exists, go into each directory inside and create a list of files named *cat.sql 
   if [ -d $OP/$SUBDIR ] ; then
      #for D in $OP/$SUBDIR/*
      for D in `ls -v $OP/$SUBDIR/*`
      do
          echo "---->$D"
          pushd .
          cd $D
          #cat `find . -name  $CONCAT_FILE` > $USR_CONCAT
          rm $USR_CONCAT
          FILE_LIST=$(find . -name  *$CONCAT_FILE)
          for FF in $FILE_LIST 
          do
              cat $FF >> $USR_CONCAT
              echo -e "\n" >> $USR_CONCAT
          done



          #svn add $USR_CONCAT
          #svn commit $USR_CONCAT -m "User concatenation"
          popd 
          

      done
   fi
done
IFS=$SAVEIFS
echo "Done."

