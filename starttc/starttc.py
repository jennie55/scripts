#!/usr/bin/env python

import sys
import urllib2
import xml.dom.minidom
from subprocess import Popen, PIPE
import time
from os.path import join
# Import the email modules we'll need
import smtplib
from email.mime.text import MIMEText
import logging

conn_db = 0

class TeamcityProject:
    __attributes = ['href', 'id', 'name', 'projectId', 'projectName', 'webUrl']

    svn_output = ''
    name = ''
    project_name = ''
    href = ''
    web_url = ''

    def __init__(self, title, project_id, cvs):
        self.project_id = project_id
        self.cvs = cvs
        self.title = title

    def __str__(self):
        return self.name

    def populate(self, project):
        self.href = project.getAttribute('href')
        self.name = project.getAttribute('name')
        self.project_name = project.getAttribute('projectName')
        self.web_url = project.getAttribute('webUrl')

    def set_svn_output(self, output):
        self.svn_output = output


email_source = 'jorge.imperial-sosa@one.verizon.com'
email_dest = ['nwfsre@one.verizon.com', 'nwfqa@one.verizon.com', 'nwfappdevteam@one.verizon.com',
              'nwftraining@one.verizon.com', 'srydell@one.verizon.com', 'jashby@one.verizon.com',
              'jhaims@one.verizon.com']
email_dest_sre = 'nwfsre@one.verizon.com'


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
# LOGFILE = 'genrevlog.txt'

# In configuration file
BLD_PROJECTS = []


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
    msg['To'] = ', '.join(you)

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
    msg['To'] = ', '.join(you)

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
def do_teamcity(user, pwd, tc_projects, wait_for_it=0, start_rev=0, current_rev=0):
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

    populate_projects(tc_projects, projects, start_revision=start_rev, current_revision=current_rev)

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

            # Get task Id to wait on it
            if wait_for_it:
                DOMTree = xml.dom.minidom.parseString(task_data)
                task = DOMTree.documentElement
                task_id = task.getAttribute('taskId')
                logging.info("Task id is %s: waiting..." % task_id)
                if wait_on_task(task_id, 10 * 60) == 0:
                    logging.error('Timeout')
                    raise Exception('Timeout')
        except urllib2.HTTPError as e:
            logging.error("\tHTTPError %s" % str(e))
        except urllib2.URLError as e:
            logging.error("\tURLError %s" % str(e))
        except IOError as e:
            logging.error("\tIOError %s" % str(e))
        except Exception as ge:
            logging.error("\tGeneral Exception %s" % str(ge))


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
    """
    paths = doc.getElementsByTagName('build_rev_path')
    if paths[0].hasAttribute('path'):
        logging.info('Changing build revs path to %s' % paths[0].getAttribute('path'))
        BUILD_REV_PATH = paths[0].getAttribute('path')
    """
    teamcity_projects = doc.getElementsByTagName('tc_build_project')
    for tc_proj in teamcity_projects:
        tc = TeamcityProject(tc_proj.getAttribute('name'), tc_proj.getAttribute('id'),
                             "%s/%s" % (tc_proj.getAttribute('svn_url'), PROD_BRANCH))
        BLD_PROJECTS.append(tc)

    return 0


def create_log_filename():
    fname = "%s-%s.log" % ('starttc', join(time.strftime('%Y-%m-%d_%H-%M-%S')))
    return fname


def get_revision_range(argv):
    i = 0
    while i < len(argv) - 1:
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

    if len(sys.argv) < 2:
        print "Usage: starttc project-id1 [project-id2 ...]"
        exit(1)

    # create log
    logfile = create_log_filename()
    logging.basicConfig(filename=logfile, level=logging.INFO, format='%(asctime)s %(message)s')
    logging.info('Get config')
    get_config(sys.argv[-1])
    logging.info('Start teamcity api')
    do_teamcity(USER, PWD, BLD_PROJECTS)

    logging.info('Done.')
    logging.shutdown()
