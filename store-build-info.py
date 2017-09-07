#!/bin/env python

__author__ = 'jorge imperial'

import urllib2, base64
import re
import sys


if  __name__ == "__main__":
    username = 'nevin'
    password = 'xxxx'

    if len(sys.argv) > 1:
       hostname = sys.argv[1]
    else:
       hostname = 'http://qa.networkfleet.com/portal'

    auth_encoded = base64.encodestring('%s:%s' % (username, password))[:-1]

    #req = urllib2.Request('http://qa.networkfleet.com/portal')
    req = urllib2.Request( hostname )
    req.add_header('Authorization', 'Basic %s' % auth_encoded)

    try:
        response = urllib2.urlopen(req)
        code = response.code
        print code

        ver_pattern = re.compile( 'class="version">(\d+.\d+.\w+)')
        host_pattern = re.compile('App: (\w+.\w+.\w+)')
        for line in response:
            """
            if ' App:' in line:
                print line
            if 'class="version">' in line:
                print line
            """

            matches = ver_pattern.search(line)
            if matches:
                revision = matches.groups()[0]
                print revision
                continue

            matches = host_pattern.search(line)
            if matches:
                host = matches.groups()[0]
                print host
                continue




    except urllib2.URLError, e:
        print "\tURLError %s" %  str(e)
    except urllib2.HTTPError, e:
        print "\tHTTPError %s" %  str(e)
    except IOError, e:
        print "\tIOError %s" % str(e)
    except :
        print "\tGeneral Exception"

    print "Done"

