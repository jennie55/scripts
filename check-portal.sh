#!/bin/bash
#*****************************************************************
#  Verifies that portal is up and running, and also that the build
#  revision is between a given range.
#  The range is specified in the command line as two numbers.
#
#*****************************************************************
R1=$2
R2=$3

PAGE_URL=https://qa.networkfleet.com/portal
VERSION=$1


usage()
{
  echo -e "usage: $0 branch start_revision end_revision"
  echo -e "\te.g.: "
  echo -e "\t'$0 3.42  32879 32890'"
}

usage_and_exit()
{
   usage
   exit 4
}


if [ "$#" -lt "3" ]; then
   # fewer than 3 arguments supplied
   usage_and_exit 4 "too few arguments" 
fi

# remove previous files if they exist
rm -f index.html 2>1 > /dev/null 2>&1
rm -f fourHundredFour.jsf\;jsessionid\=* > /dev/null 2>&1

# get pate
wget ${PAGE_URL} -o qa.portal.response

# is the page being served?
RESPONSE=$(grep "HTTP request sent" qa.portal.response)
PAGE_OK=$(echo "$RESPONSE" | grep "200 OK")
echo $PAGE_OK

# we have a page, lets see what it is
if [ "$PAGE_OK" ] ; then
    echo "A page was retrieved..."
    # just for sanity, check for 404 page
    mv fourHundredFour.jsf* fourHundredFour.jsf  > /dev/null 2>&1
    if [ -e fourHundredFour.jsf ] ; then
	echo "Received 404 default page."
	exit 2
    fi
    # At this point we should have index.html (or 500 error?)
    if [ -e index.html ] ; then
	echo "index page retrieved"
	VERSION_FOUND=$(egrep -o "${VERSION}.[0-9]+" index.html)
	echo "Version found is '$VERSION_FOUND'"
	REVISION=$(echo "${VERSION_FOUND}" | cut -d '.' -f 3)
	echo "Revision is $REVISION"
	if [ $REVISION -gt $R1 ] ;  then
	    if [ $REVISION -lt $R2 ] ; then
		echo "Revision in range..."
		exit 0
	    else
		echo "Revision later than build range ($R2)"
	    fi
        else
	    echo "The revision is not in the range $R1 .. $R2"
	fi
    else
	echo "An error ocurred... (500?)"
    fi
else
    echo "Page not retrieved"
fi
exit 3
