#!/home/bea/usr/local/bin/python2.7
import sys

import smtplib

import subprocess
from subprocess import call

import os
from os import listdir
from os.path import join, isfile

import time

RELEASE="3.42"
STAGE_REL = "REL_%s" % RELEASE

email_source='jorge.imperial-sosa@one.verizon.com'
email_dest='nwfdev@one.verizon.com;nwftraining@one.verizon.com'
email_dest_sre='nwfsre@one.verizon.com'



print "Building for stage"


# Import the email modules we'll need
from email.mime.text import MIMEText


# - - - - - - - - - - - - - - - - - - - - - - - -
def send_email_file(me,you,subject,textfile):
    #textfile='textfile.txt'
    #you='jorge.imperial-sosa@one.verizon.com'
    #me='jorge.imperial-sosa@one.verizon.com'

    # Open a plain text file for reading.  For this example, assume that
    # the text file contains only ASCII characters.
    fp = open(textfile, 'rb')
    # Create a text/plain message
    msg = MIMEText( fp.read() )
    fp.close()
    print msg

    # me == the sender's email address
    # you == the recipient's email address
    msg['Subject'] = subject  # 'The contents of %s' % textfile
    msg['From'] = me
    msg['To'] = you

    # Send the message via our own SMTP server, but don't include the
    # envelope header.
    s = smtplib.SMTP('localhost')
    s.sendmail(me, [you], msg.as_string())
    s.quit()



# - - - - - - - - - - - - - - - - - - - - - - - -
def send_email_text(me,you,subject,message):
    msg = MIMEText( message )
    # me == the sender's email address
    # you == the recipient's email address
    msg['Subject'] = subject
    msg['From'] = me
    msg['To'] = str([you])

    # Send the message via our own SMTP server, but don't include the envelope header.
    s = smtplib.SMTP('localhost')
    s.sendmail(me, [you], msg.as_string())
    s.quit()

# - - - - - - - - - - - - - - - - - - - - - - - -
def get_last_rev(path):
    lf = listdir(path)
    # sort the list
    lf = sorted(lf)
    # return first

    fp = open( join(path,lf[-1]), 'rt')
    rev = fp.read()
    fp.close()

    return int(rev)

# - - - - - - - - - - - - - - - - - - - - - - - - 
def do_create_revlog(path, rev1, rev2, fileout ):

    os.chdir( path )

    str_cmd = "./genrevlog.sh  " + str(rev1) + "  " + str(rev2) 
    p = subprocess.Popen(str_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    fp = open( fileout, "wt")
    for line in p.stdout.readlines():
	fp.write( line )
	print line

    fp.close()
    retval = p.wait()


# - - - - - - - - - - - - - - - - - - - - - - - -
def do_build(path, release, previous_rev,revision_number):

    os.chdir( path )

    str_cmd = "./ted3build.sh --path branches --name " + release + " --rev " + str(revision_number) + " --profile staging"
    p = subprocess.Popen(str_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    fp = open( "build-output-" + str(revision_number) + ".log", "wt")
    for line in p.stdout.readlines():
	fp.write( line )
	print line

    fp.close()
    retval = p.wait()

# - - - - - - - - - - - - - - - - - - - - - - - -
def do_deploy( path,  revision_number ):
    os.chdir( path )
    str_cmd="./pushTed3Build.bash --rev " + str(revision_number)  +  "  --portal --report --media"
    p = subprocess.Popen(str_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    fname = "deploy-output-" + str(revision_number) + ".log"
    fp = open( fname, "wt")
    for line in p.stdout.readlines():
	fp.write( line )
	print line

    fp.close()
    retval = p.wait()

    return fname



# - 
def do_check( start_rev, end_rev):
    """
    Checks if portal is up"
    """
    os.chdir( path )
    str_cmd="./check-portal.sh %s %s %s "  % ( RELEASE, start_rev, end_rev)
    p = subprocess.Popen(str_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    fname = "check-output-" + str(revision_number) + ".log"
    fp = open( fname, "wt")
    for line in p.stdout.readlines():
        fp.write( line )
        print line

    fp.close()
    retval = p.wait()

    return fname


# - - - - - - - - - - - - - - - - - - - - - - - -
def do_push_last_rev( path,  revision_number ):
   
    fname = join(path, time.strftime('%Y-%m-%d_%H-%M-%S') )
    print 'Writing rev in ' + fname 
    fp = open( fname, "wt" )
    fp.write( str(revision_number) )
    fp.close
    return fname




#  - - - - - - - - - - - - - - - - - - -- - - - - 
def check_generated_wars( branch, rev):
    """
        We should get 3 files (depends on ted3build!!!)
	[bea@starsky svn-builds]$ ll *-37682-*
	-rw-r--r-- 1 bea bea 147513426 Dec 18 11:06 media-REL_3.41-37682-staging_profile.zip
	-rw-r--r-- 1 bea bea 134065893 Dec 18 11:08 nwf-portal-REL_3.41-37682-staging_profile.war
	-rw-r--r-- 1 bea bea  65943982 Dec 18 11:07 ssp-REL_3.41-37682-staging_profile.war
    """

    names = [  "media-%s-%s-staging_profile.zip" % ( branch, str(rev) ),
	       "nwf-portal-%s-%s-staging_profile.war" % ( branch, str(rev) ),
	       "ssp-%s-%s-staging_profile.war" % ( branch, str(rev) )

	    ]

    not_found = False
    failed = []
    for f in names:
        if not isfile(f):
	    not_found = True
	    failed.append( f )

    if not_found:
	return False, failed
    else:
        return True, None


# - - - - - - - - - - - - - - - - - - - - - - - 
def abort_ops( ops, message, branch, rev ):
    s = "Unsuccessful %s: branch %s/rev %s:\n%s" % (ops, branch, str(rev), message )
    print s 
    send_email_text(email_source,email_dest_sre,'Error while building.', s)
    exit(2)


# - - - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - 
def check_deployment_log(fname, STAGE_REL, revision_number):
    f = open(fname, "rt")

    not_found = False
    undeployed = []
    if not f:
	return False, None
    else:
        for line in f:
	    if line.find('Unable to deploy') != -1:
		not_found = True
	        undeployed.append( line )

    if not_found:
        return False, undeployed
    else:
        return True, None



if __name__ == '__main__':


    subprocess.call( ['svn', 'update' ] )
    
    # Get latest rev
    revision_number = 0
    p = subprocess.Popen("svn info | grep Revision | cut -d ':' -f 2", shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    for line in p.stdout.readlines():
	revision_number = int(line)
    retval = p.wait()

    # previous is in /home/bea/svn/ted3/svn-builds
    path = '/home/bea/svn/ted3/svn-builds'
    previous_rev = get_last_rev( join(path,'etc') )

    print "Current rev number is %s" % str(revision_number)
    print "Previous rev number is %s" % str(previous_rev)

    if revision_number > (previous_rev+1) :

	# create rev log
	do_create_revlog(path, (previous_rev+1), revision_number,'revlog.log')
	send_email_file(email_source,email_dest,'new build going to stage: %s to %s' % (previous_rev+1,revision_number),'revlog.log')

	# Build
	do_build(path, STAGE_REL, previous_rev+1,revision_number) 


	# Verify that files were generated:
	build_status, file_list = check_generated_wars( STAGE_REL, revision_number)
	if not build_status:
	    abort_ops( "build", "Build process did not generate expected war file: %s" % str(file_list), STAGE_REL, revision_number )
        
	# Deploy
        deploy_log = do_deploy(path, revision_number )
        
	deploy_status, file_list = check_deployment_log(deploy_log, STAGE_REL, revision_number)
	if not deploy_status:
	    abort_ops( "deploy", "Deploy process did not push: %s" % str(file_list), STAGE_REL, revision_number )
       
        # Check
	check_log = do_check(previous_rev+1,revision_number)
        send_email_file(email_source,email_dest_sre,'Checking deployment', check_log)

	# Success
	do_push_last_rev(join(path,'etc'), revision_number )
        #
	send_email_file(email_source,email_dest,'new build in stage: %s to %s --[ DONE ]--' % (previous_rev+1,revision_number),'revlog.log')
    else:
        send_email_text(email_source,email_dest,'No build required.','Revisions: %s - %s' % (previous_rev+1,revision_number) )
        

