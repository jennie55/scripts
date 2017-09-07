#!/usr/bin/python

# This script updates the version fields of a pom.xml file
#  usage:  ./update_pom_version.py pom.xml NIGHTLY-SNAPSHOT

import sys
import re
from lxml import etree as ET

if __name__ == '__main__':

    # regex to match our release string

    p = re.compile('20[0-9]{2}[.]R[0-9]{1,2}[.][0-9]{5}')

    # pick up command line arguments

    try:
        pomfile = sys.argv[1]
    except:
        print 'ERROR: pomfile was not specified'
        print 'usage: ' + sys.argv[-1] + ' pom.xml NIGHTLY-SNAPSHOT'
        raise SystemExit(1)
    try:
        newversion = sys.argv[2]
    except:
        print 'ERROR: version was not specified'
        print 'usage: ' + sys.argv[-1] + ' pom.xml NIGHTLY-SNAPSHOT'
        raise SystemExit(1)

    # read and parse the pom.xml file

    try:
        tree = ET.parse(pomfile)
    except:
        print 'ERROR: pom file was not found, check the file path'
        raise SystemExit(1)

    root = tree.getroot()

    # walk through the xml and search for text to replace....

    for x in list(root.iter()):
        try:
            if x.text == 'NIGHTLY-SNAPSHOT' or p.match(x.text):
                oldversion = x.text
                x.text = newversion
                print oldversion + ' changed to ' + newversion
        except:
            print 'could not read value'

    # overwrite the pom.xml file

    try:
        output_file = open(pomfile, 'w')
    except:
        print 'ERROR: unable to write pom.xml file, check file permissions.'
        raise SystemExit(1)
    output_file.write(ET.tostring(root))
    output_file.write('\n')
    output_file.close()

    print 'updated ' + pomfile + ' with version ' + newversion

