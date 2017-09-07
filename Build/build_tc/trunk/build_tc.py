#!/usr/bin/env python

import sys
import urllib2
import xml.dom.minidom

from subprocess import Popen, PIPE

import time

from os import listdir
from os.path import join

import sqlite3

from Projects import TeamcityProject as TCProject

email_source = 'jorge.imperial-sosa@one.verizon.com'
#email_dest = 'nwfappdevteam@one.verizon.com;nwfqa@one.verizon.com;nwfsre@one.verizon.com;nwftraining@one.verizon.com;jhaims@one.verizon.com;srydell@one.verizon.com;jashby@one.verizon.com'
#email_dest = 'nwfsre@one.verizon.com,nwfqa@one.verizon.com,nwfappdevteam@one.verizon.com,nwftraining@one.verizon.com,srydell@one.verizon.com,jashby@one.verizon.com,jhaims@one.verizon.com'
email_dest = ['nwfsre@one.verizon.com','nwfqa@one.verizon.com','nwfappdevteam@one.verizon.com','nwftraining@one.verizon.com','srydell@one.verizon.com','jashby@one.verizon.com','jhaims@one.verizon.com']
email_dest_sre = 'nwfsre@one.verizon.com'


# Import the email modules we'll need
import smtplib
from email.mime.text import MIMEText

import re
import sqlite3

conn_db = 0

#
import logging


"""
Build order comes from

https://confluence.networkfleet.com:8443/display/TED/Api+Command+Line+Builds

"""

# Configuration defaults
USER = 'autobuilder'
PWD = 'autobuild'
PROD_BRANCH = 'REL_X.XX'
BUILD_REV_PATH = '/usr/local/teamcity-data/build-automation/tc/stage-builds'

TC_PARENT_PROJECT = 'bld_current_prod'

MIN_REVISION = 30000
LOGFILE = 'genrevlog.txt'


# In configuration file
BLD_PROJECTS = []
DEPLOY_PROJECTS = []


# These are global so they can be used from all routines. Authentication is the problem.
PASSWORD_MGR = 0
HANDLER = 0
OPENER = 0

# Urls
TOP_LEVEL_URL = 'https://teamcity.networkfleet.com:8543/httpAuth/app/rest'
AUTH_URL = 'https://teamcity.networkfleet.com:8543/httpAuth/app/rest/projects/%s' % TC_PARENT_PROJECT
BUILD_URL = "https://teamcity.networkfleet.com:8543/httpAuth/app/rest/buildQueue"
CONFIG_URL = 'http://teamcity.networkfleet.com:8543/httpAuth/app/rest/buildTypes/<buildTypeLocator>'

DISABLE_EMAIL = 0
DISABLE_BUILD = 0


# - - - - - - - - - - - - - - - - - - - - - - - -
def send_email_file(me, you, subject, textfile):
    # Open a plain text file for reading.  For this example, assume that
    # the text file contains only ASCII characters.
    fp = open(textfile, 'rb')
    # Create a text/plain message
    msg = MIMEText(fp.read())
    fp.close()
    logging.info(msg)

    # me == the sender's email address
    # you == the recipient's email address
    msg['Subject'] = subject  # 'The contents of %s' % textfile
    msg['From'] = me
    msg['To'] =  ', '.join(you)

    if DISABLE_EMAIL:
        return 0

    # Send the message via our own SMTP server, but don't include the
    # envelope header.
    s = smtplib.SMTP('localhost')
    s.sendmail(me, you, msg.as_string())
    s.quit()


# - - - - - - - - - - - - - - - - - - - - - - - -
def send_email_text(me, you, subject, message):
    msg = MIMEText(message)
    # me == the sender's email address
    # you == the recipient's email address
    msg['Subject'] = subject
    msg['From'] = me
    msg['To'] =  ', '.join(you)

    if DISABLE_EMAIL:
        return 0

    # Send the message via our own SMTP server, but don't include the envelope header.
    s = smtplib.SMTP('localhost')
    s.sendmail(me, you, msg.as_string())
    s.quit()


# - - - - - - - - - - - - - - - - - - - - - - - -
def populate_projects(project_list, xml_from_tc, start_revision, current_revision):
    """
    Populates our list of teamcity config with data from teamcity.

    :param project_list: A list of TeamCity objects
    :param xml_from_tc: XML from teamcity
    :param start_rev: where we start in svn
    :param current_revision: where the current rev is in svn
    :return:
    """

    logging.info("populating...")
    for p in project_list:
        # 'href', 'id', 'name', 'projectId', 'projectName', 'webUrl'

        for tc in xml_from_tc:
            tc_id = tc.getAttribute('id')

            if p.project_id == tc_id:
                p.populate(tc)

    # Get svn url for ever project
    for p in project_list:
        # str_cmd = 'svn log -v --stop-on-copy http://subversion.repository.com/svn/repositoryname'
        if p.cvs:
            lst_cmd = ['/usr/bin/svn', 'log', p.cvs, '-r%d:%d' % (start_revision, current_revision)]
            # logging.info(lst_cmd)
            process = Popen(lst_cmd, stdout=PIPE)
            stdout, stderr = process.communicate()
            # print stdout
            p.set_svn_output(stdout)

            tokens = p.cvs.split('/')

            if tokens and len(tokens) > 6:
                p.name = tokens[5]

    logging.info('done populating')
    return 0


# - - - - - - - - - - - - - - - - - - - - - - - -
def wait_on_task(id, timeout):
    """
    Waits on a task id from teamcity up to timeout. Reports success or failure of build.

    :param id: id to wait on
    :param timeout: how much time we are allowing
    :return:
    """

    increment = 15
    secs = 0
    while True:
        url = "%s/%s:%d" % (BUILD_URL, 'taskId', int(id))
        response = urllib2.urlopen(url)
        txt = response.read()
        response.close()
        # parse
        dt = xml.dom.minidom.parseString(txt)
        task = dt.documentElement
        state = task.getAttribute('state')
        # logging.info( 'State: %s (%d secs)' %  (state, secs))
        time.sleep(increment)

        if state == 'finished':
            status = task.getAttribute('status')
            logging.info('\tStatus: %s  (%d secs)' % (status, secs))
            if status == 'SUCCESS':
                return True
            else:
                return False

        secs += increment

        # TODO: Check for timeout here

    return False


# - - - - - - - - - - - - - - - - - - - - - - - -
def generate_revision_log(tc_projects, output_file_name):
    f = open(output_file_name, 'wt')
    # Run all configurations in the projects list
    for project in tc_projects:
        f.write("%s\n" % project.name)
        lines = project.svn_output.split('\n')
        for line in lines:
            f.write("%s\n" % line)
    f.close()


# - - - - - - - - - - - - - - - - - - - - - - - -
def do_teamcity(user, pwd, tc_projects, build_id, start_rev=0, current_rev=0):
    # create a password manager
    PASSWORD_MGR = urllib2.HTTPPasswordMgrWithDefaultRealm()

    # Add the username and password.
    # If we knew the realm, we could use it instead of None.
    # top_level_url = "http://example.com/foo/"
    PASSWORD_MGR.add_password(None, TOP_LEVEL_URL, user, pwd)

    HANDLER = urllib2.HTTPBasicAuthHandler(PASSWORD_MGR)

    # create "OPENER" (OpenerDirector instance)
    OPENER = urllib2.build_opener(HANDLER)
    project_data = ''
    try:
        config = OPENER.open(AUTH_URL)
        project_data = config.read()
        config.close()
    except Exception as e:
        logging.error(str(e))

    # Install the opener.
    # Now all calls to urllib2.urlopen use our opener.
    urllib2.install_opener(OPENER)

    #
    # Project data from Teamcity
    DOMTree = xml.dom.minidom.parseString(project_data)
    collection = DOMTree.documentElement

    if collection.hasAttribute('buildTypes'):
        logging.info("Root element : %s" % collection.getAttribute('buildTypes'))
    projects = collection.getElementsByTagName('buildType')

    populate_projects(tc_projects, projects, start_rev, current_rev)

    # Only on build configurations pass. This is not right...
    if start_rev != 0 and current_rev != 0:
        generate_revision_log(tc_projects, LOGFILE)
        send_email_file(email_source, email_dest, 'New build in stage. %s to %s' % (last_rev, current_rev), LOGFILE)

    # Run all configurations in the projects list
    for project in tc_projects:

        #
        payload = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><build>\n<buildType id=\"%s\"/></build>" % project.project_id
        try:
            logging.info('*************************************************************************')
            logging.info("Title %s" % project.title)
            logging.info("Project %s" % project.name)
            logging.info("ID: %s" % project.project_id)
            lines = project.svn_output.split('\n')
            for line in lines:
                logging.info("%s", line)

            if not DISABLE_BUILD:
                req = urllib2.Request(BUILD_URL)
                req.add_header('Content-Type', 'application/xml')
                response = urllib2.urlopen(req, payload)

                task_data = response.read()
                response.close()
            t = time.time()
            sql_str = "INSERT INTO builds (build_id, start_date, end_date, project, start_rev, end_rev) VALUES (%d, %d, %d, '%s', %d, %d);" % (build_id, t, t, project.name, start_rev, current_rev)

            print sql_str
            try:
                conn_db.execute(sql_str)
            except Exception as r:
                print r

            # Get svn output into database
            line_number = 0
            while line_number < len(lines):
                print 'Line number %d' % line_number

                # svn record log starts with hyphens
                if '-------------------' in lines[line_number]:
                    # revision text
                    line_number += 1
                    rev_text = lines[line_number]

                    if '|' not in rev_text:
                        continue

                    # comments
                    comments = ''
                    line_number += 1
                    while '-------------------' not in lines[line_number]:
                        comments += lines[line_number]
                        line_number += 1

                        if line_number < len(lines):
                            continue

                    t = time.time()
                    sql_str = "INSERT INTO builds (build_id, project, start_rev, end_rev, revision_text, comments) VALUES (%d, '%s', %d, %d, '%s', '%s');" % (build_id, project.name, start_rev, current_rev, rev_text, comments)

                    print sql_str
                    try:
                        conn_db.execute(sql_str)
                    except Exception as r:
                        print r
                else:
                    line_number += 1

            conn_db.commit()

            # do not wait if there is no build, or if 'deploy' build
            if 0 == start_rev or 0 == current_rev or DISABLE_BUILD:
                continue

            # Get task Id to wait on it
            DOMTree = xml.dom.minidom.parseString(task_data)
            task = DOMTree.documentElement
            task_id = task.getAttribute('taskId')
            logging.info("Task id is %s: waiting..." % task_id)
            if wait_on_task(task_id, 10 * 60) == 0:
                logging.error('Timeout')
                raise Exception('Timeout')

        except urllib2.URLError as e:
            logging.error("\tURLError %s" % str(e))
        except urllib2.HTTPError as e:
            logging.error("\tHTTPError %s" % str(e))
        except IOError as e:
            logging.error("\tIOError %s" % str(e))
        except Exception as ge:
            logging.error("\tGeneral Exception %s" % str(ge))


# - - - - - - - - - - - - - - - - - - - - - - - -
def get_current_svn_rev():
    """
    Returns the current revision from SVN
    :return: svn rev as an int
    """

    # Get latest rev
    revision_number = 0
    lst_cmd = ['/usr/bin/svn', 'info', 'https://svn.networkfleet.com/repos/ted3']

    process = Popen(lst_cmd, stdout=PIPE)
    stdout, stderr = process.communicate()
    lines = stdout.split('\n')

    pattern = r"Last Changed Rev: (\d+)"
    version_pattern = re.compile(pattern)

    for line in lines:
        # Look for Last Changed Rev: 40034
        matches = version_pattern.search(line)
        if matches:
            revision = matches.groups()[0]
            return int(revision)


# - - - - - - - - - - - - - - - - - - - - - - - -
def get_last_rev(path):
    lf = listdir(path)

    if len(lf) == 0:
        return MIN_REVISION

    # sort the list
    lf = sorted(lf)
    fp = open(join(path, lf[-1]), 'rt')
    rev = fp.read()
    fp.close()
    return int(rev)


# - - - - - - - - - - - - - - - - - - - - - - - -
def do_push_last_rev(path, revision_number):
    file_name = join(path, time.strftime('%Y-%m-%d_%H-%M-%S'))
    logging.info('Writing rev in ' + file_name)
    fp = open(file_name, "wt")
    fp.write(str(revision_number))
    fp.close

    # database
    t = time.time()
    conn_db.execute(
        'INSERT INTO history (revision, date_built) VALUES (%d, %d)' % (int(revision_number), t))
    conn_db.commit()

    rows = conn_db.execute('SELECT id from history where revision = %d ' % int(revision_number))

    for row in rows:
        val = row[0]
        return val


# - - - - - - - - - - - - - - - - - - - - - - - -
def get_config(config_path):
    """
    Reads configuration from an xml file
    :param config_path: XML file with configuration data
    :return:
    """

    f = open(config_path, 'rt')
    text = f.read()
    f.close()

    dom_tree = xml.dom.minidom.parseString(text)
    doc = dom_tree.documentElement

    #
    login = doc.getElementsByTagName('login')
    if login[0].hasAttribute('name'):
        USER = login[0].getAttribute('name')
    if login[0].hasAttribute('pwd'):
        PWD = login[0].getAttribute('pwd')

    branch = doc.getElementsByTagName('branch')
    if branch[0].hasAttribute('name'):
        PROD_BRANCH = branch[0].getAttribute('name')

    paths = doc.getElementsByTagName('build_rev_path')
    if paths[0].hasAttribute('path'):
        logging.info('Changing build revs path to %s' % paths[0].getAttribute('path'))
        BUILD_REV_PATH = paths[0].getAttribute('path')

    teamcity_projects = doc.getElementsByTagName('tc_build_project')
    for tc_proj in teamcity_projects:
        tc = TCProject(tc_proj.getAttribute('name'), tc_proj.getAttribute('id'),
                       "%s/%s" % (tc_proj.getAttribute('svn_url'), PROD_BRANCH))
        BLD_PROJECTS.append(tc)

    teamcity_projects = doc.getElementsByTagName('tc_deploy_project')
    for tc_proj in teamcity_projects:
        tc = TCProject(tc_proj.getAttribute('name'), tc_proj.getAttribute('id'),
                       "%s/%s" % (tc_proj.getAttribute('svn_url'), PROD_BRANCH))
        DEPLOY_PROJECTS.append(tc)

    return 0


def create_log_filename():
    fname = "%s-%s.log" % ('build', join(time.strftime('%Y-%m-%d_%H-%M-%S')) )
    return fname


def get_revision_range(argv):

    i = 0
    while i < len(argv)-1:
        if '--rev-range' in argv[i]:
            revision_range = argv[i + 1].split(':')
            return int(revision_range[0]), int(revision_range[1])
        i += 1

    return None, None

"""
------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------
"""
if __name__ == '__main__':

    #send_email_text(email_source, email_dest, "testing build distribution list", "sorry for the sp@m")
    #exit(999)

    if len(sys.argv) < 2:
        print "Usage: build_tc [--rev-range start:end]  configuration.xml"
        exit(1)

    # create log
    logfile = create_log_filename()
    logging.basicConfig(filename=logfile, level=logging.INFO, format='%(asctime)s %(message)s')

    conn_db = sqlite3.connect('builds.db')

    # Get configuration from file
    get_config(sys.argv[-1])

    # revisions
    last_rev, current_rev = get_revision_range(sys.argv)
    if not last_rev:
        last_rev = get_last_rev(BUILD_REV_PATH)
        current_rev = get_current_svn_rev()

    logging.info('From %d to %d' % (last_rev, current_rev))

    if current_rev <= last_rev:
        s = 'No build required. Current SVN rev is same as last built (%d,%d) for %s' % (
            last_rev, current_rev, sys.argv[1])
        logging.info(s)
        send_email_text(email_source, email_source, s, s)
    else:
        send_email_text(email_source, email_source, 'Build started in TeamCity',
                        '%s. Revisions: %s - %s' % (sys.argv[1], last_rev, current_rev))

        #
        build_id = do_push_last_rev(BUILD_REV_PATH, current_rev)

        do_teamcity(USER, PWD, BLD_PROJECTS, build_id, last_rev, current_rev)

        # Wait, to be sure.
        time.sleep(3)
        do_teamcity(USER, PWD, DEPLOY_PROJECTS, build_id)
        time.sleep(10*60)

        # send email notification
        send_email_file(email_source, email_dest, 'New build in stage. %s to %s --DONE--' % (last_rev, current_rev),
                        LOGFILE)

        # send log notification via email
        send_email_file(email_source, [email_source],
                        'Build finished in TeamCity. %s. Revisions: %s - %s' % (sys.argv[1], last_rev, current_rev),
                        logfile)

    conn_db.close()

    logging.info('Done.')
    logging.shutdown()

