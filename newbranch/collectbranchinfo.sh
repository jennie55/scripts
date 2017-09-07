#!/bin/bash



mydir=`pwd`
tempdir="/tmp/tmp_projlistcheckout"
repo="https://svn.networkfleet.com/repos/ted3"


# empty checkout of ted3
if [ -d "$tempdir" ]; then
  cd $tempdir
  svn update
else
  svn checkout $repo $tempdir --depth empty
  cd $tempdir
fi

cd $mydir

rm outputfile

for project in "${projectlist[@]}"
do

  commitcountR13=`svn log $repo/$project/branches/REL_2016.R13 -q | sed -e "s/[\-]//g" |grep r| grep -v build |wc -l`
  commitcountR12=`svn log $repo/$project/branches/REL_2016.R12 -q | sed -e "s/[\-]//g" |grep r| grep -v build |wc -l`
  commitcountR11=`svn log $repo/$project/branches/REL_2016.R11 -q | sed -e "s/[\-]//g" |grep r| grep -v build |wc -l`
  commitcountR10=`svn log $repo/$project/branches/REL_2016.R10 -q | sed -e "s/[\-]//g" |grep r| grep -v build |wc -l`
  commitcount351=`svn log $repo/$project/branches/REL_3.51 -q | sed -e "s/[\-]//g" |grep r| grep -v build |wc -l`
  commitcount350=`svn log $repo/$project/branches/REL_3.50 -q | sed -e "s/[\-]//g" |grep r| grep -v build |wc -l`
  commitcount349=`svn log $repo/$project/branches/REL_3.49 -q | sed -e "s/[\-]//g" |grep r| grep -v build |wc -l`
  commitcount348=`svn log $repo/$project/branches/REL_3.48 -q | sed -e "s/[\-]//g" |grep r| grep -v build |wc -l`
  commitcount347=`svn log $repo/$project/branches/REL_3.47 -q | sed -e "s/[\-]//g" |grep r| grep -v build |wc -l`
  commitcount346=`svn log $repo/$project/branches/REL_3.46 -q | sed -e "s/[\-]//g" |grep r| grep -v build |wc -l`
  commitcount345=`svn log $repo/$project/branches/REL_3.45 -q | sed -e "s/[\-]//g" |grep r| grep -v build |wc -l`
  commitcount344=`svn log $repo/$project/branches/REL_3.44 -q | sed -e "s/[\-]//g" |grep r| grep -v build |wc -l`
  commitcount343=`svn log $repo/$project/branches/REL_3.43 -q | sed -e "s/[\-]//g" |grep r| grep -v build |wc -l`
  commitcount342=`svn log $repo/$project/branches/REL_3.42 -q | sed -e "s/[\-]//g" |grep r| grep -v build |wc -l`
  commitcount341=`svn log $repo/$project/branches/REL_3.41 -q | sed -e "s/[\-]//g" |grep r| grep -v build |wc -l`
  commitcount340=`svn log $repo/$project/branches/REL_3.40 -q | sed -e "s/[\-]//g" |grep r| grep -v build |wc -l`


  echo "$project;$commitcountR13;$commitcountR12;$commitcountR11;$commitcountR10;$commitcount351;$commitcount350;$commitcount349;$commitcount348;$commitcount347;$commitcount346;$commitcount345;$commitcount344;$commitcount343;$commitcount342;$commitcount341;$commitcount340"
done > outputfile


rm -rf $tempdir
