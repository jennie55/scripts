__author__ = 'jorgeimperial'

import urllib2
import sys
import re

URL = 'http://qa.networkfleet.com/portal'


def get_page(url):
    response = urllib2.urlopen(url)
    txt = response.read()
    response.close()
    return txt


def parse_for_revision(branch, text):
    pattern = r"%s.(\d+)" % branch
    print 'Looking for pattern \'%s\'' % pattern
    version_pattern = re.compile(pattern)

    lines = text.split('\n')
    for line in lines:
        matches = version_pattern.search(line)
        if matches:
	    #print 'matched line: %s' % line
            revision = matches.groups()[0]
            return revision
    return None


def check_stage_deployment(branch):
    page = get_page(URL)
    #print page

    revision = parse_for_revision(branch, page)
    print 'Revision %s' %  revision
    return 0


# Main entry point
if __name__ == '__main__':

    branch = sys.argv[1]
    start_rev = sys.argv[2]
    end_rev   = sys.argv[3]

    ret = check_stage_deployment(branch)
    if int(start_rev) <= int(ret) <= int(end_rev):
        sys.exit(0)
    else:
        sys.exit(-1)

