import urllib2
import xml.dom.minidom
import os
import os.path
from subprocess import Popen, PIPE
import hashlib
import time

__author__ = 'jimperialsosa'



# Current version
VERSION = '3.42.0-SNAPSHOT'

# Constants, never to be changed
DOWNLOADS = 'downloads'
BASE_NEXUS_REPO = 'http://nexus.networkfleet.com:8081/nexus/content/repositories/snapshots'
BASE_URL = 'http://nexus.networkfleet.com:8081/nexus/content/repositories/snapshots/%s/%s/%s/maven-metadata.xml'


# ------------------------------------------------------------------------
class NexusPath:
    """
    This class represents a nexus artifact. Minimal info is retained
    """
    group_id = ''
    artifact_id = ''

    def __init__(self, gid, proj):
        self.group_id = gid
        self.artifact_id = proj


class JarFileInfo:
    """
    Represents the size, date and checksum of a file
    """
    file_size = 0
    creation_date = 0
    md5_checksum = 0

    def __init__(self, file_size, creation_date, md5cs, name, file_path):
        self.file_size = file_size
        self.creation_date = creation_date
        self.md5_checksum = md5cs
        self.file_path = file_path
        self.name = name


# A list of the projects deployed by Teamcity
PROJECTS = [
    NexusPath('com.networkfleet', 'api-server'),  # api
    NexusPath('com.networkfleet', 'api-management'),
    NexusPath('com.networkfleet', 'oauth2-authorization-server'),

    NexusPath('com.networkfleet', 'arch'),  # arch

    NexusPath('com.networkfleet', 'dataconnect'),  # dataconnect

    NexusPath('com.networkfleet.eda', 'eda-jjk'),  # eda-jjk

    NexusPath('com.networkfleet.eda', 'message-processor'),  # eda
    NexusPath('com.networkfleet.eda', 'eda-console-webapp'),  
    NexusPath('com.networkfleet.eda', 'alertengine'),  
]

FILES = ['api-common-' + VERSION + '.jar',
         'api-common-server-' + VERSION + '.jar',
         'api-model-' + VERSION + '.jar',
         'api-server-common-' + VERSION + '.jar',
         'api-server-restdocs-' + VERSION + '.jar',
         'arch-dataservice-' + VERSION + '.jar',
         'arch-model-' + VERSION + '.jar',
         'common-' + VERSION + '.jar',
         'dataservice-staging-' + VERSION + '.jar',
         'eda-common-' + VERSION + '.jar',
         'jjkeller-' + VERSION + '.jar',
         'model-' + VERSION + '.jar',
         'oauth2-common-' + VERSION + '.jar',
         'restdocs-annotations-' + VERSION + '.jar',
         'restdocs-jaxb-' + VERSION + '.jar']


def hashfile(fname, hasher, blocksize=65536):
    """
    Calculate the md5 checksum of a file content.
    :param fname:
    :param hasher:
    :param blocksize:
    :return: hash hex digest of file
    """
    afile = open(fname, 'rb')
    buf = afile.read(blocksize)
    while len(buf) > 0:
        hasher.update(buf)
        buf = afile.read(blocksize)
    afile.close()
    return hasher.hexdigest()


# - - - - - - - - - - - - - - - - - - - - - - - -
def create_url(project, ver):
    """
    Creates an URL for maven.
    :param project: name of artifact

    :param ver: version of artifact.
    :return: the complete URL
    """
    return BASE_URL % (project.group_id.replace('.', '/'), project.artifact_id, ver)


# - - - - - - - - - - - - - - - - - - - - - - - -
def get_metadata(url, project):
    """
    Retrieves the name of the latest artifact from Nexus.
    :param url: Location of metadata.xml
    :param project: artifact id
    :return:an URL to the actual artifact in Nexus.
    """
    response = urllib2.urlopen(url)
    txt = response.read()
    response.close()

    # parse
    dt = xml.dom.minidom.parseString(txt)
    metadata = dt.documentElement

    # - - - -
    group_id = ''
    groupIdNodes = metadata.getElementsByTagName('groupId')
    for a in groupIdNodes[0].childNodes:
        group_id = a.data

    # - - - -
    artifactId = ''
    artifactIdNodes = metadata.getElementsByTagName('artifactId')
    for a in artifactIdNodes[0].childNodes:
        artifactId = a.data

    # - - - -
    version = ''
    versionNodes = metadata.getElementsByTagName('version')
    for a in versionNodes[0].childNodes:
        version = a.data

    war = None
    snapshotVersions = metadata.getElementsByTagName('snapshotVersion')
    for snapshot in snapshotVersions:
        # print "Snapshot version name=%s" % snapshot.nodeName

        for snapshotNode in snapshot.childNodes:
            if snapshotNode.nodeName == 'extension':
                text = snapshotNode.firstChild
                #print "\tExtension: %s" % text.data
                if text.data == 'war':
                    # Found war, look for name
                    war = 'war'

            if snapshotNode.nodeName == 'value':
                text = snapshotNode.firstChild
                #print "\tValue: %s" % text.data
                if war is not None:
                    return "%s/%s/%s/%s-%s.%s" % (
                        group_id.replace('.', '/'), project.artifact_id, version, artifactId, text.data, war)


# - - - - - - - - - - - - - - - - - - - - - - - -
def download_file(url, filename):
    """
    Downloads a file from an URL (Nexus)
    :param url: the file to download
    :param filename: filename to save it on disk
    :return:
    """
    response = urllib2.urlopen(url)
    txt = response.read()
    response.close()
    f = open(filename, 'wb')
    f.write(txt)
    f.close()
    return True


# - - - - - - - - - - - - - - - - - - - - - - - -
def unzip(filename, out_dir):
    """
     Unzips a file in a directory
    :param filename: path to file to unzip
    :param out_dir: directory to unzip contents
    :return:
    """

    # Get latest rev
    revision_number = 0
    lst_cmd = ['unzip', filename, '-d', out_dir]

    process = Popen(lst_cmd, stdout=PIPE)
    stdout, stderr = process.communicate()

    # print stdout
    #print stderr
    return True


def clean_dir( path_to_clean ):
    cln_cmd = ['rm', '-fr', path_to_clean]
    process = Popen(cln_cmd, stdout=PIPE)
    stdout, stderr = process.communicate()

    # print stdout
    #print stderr
    return True



def do_recursive_check(curr_dir, file_name, jar_file_list):
    # Go thru the list of entries in a directory
    try:
        for root, dir_names, file_names in os.walk(curr_dir):
            # print "Directory: %s" % root
            for f in file_names:
                if f == file_name:
                    # full path
                    full_path = os.path.join(root, f)

                    md5_check = hashfile(full_path, hashlib.md5())
                    creation_date = time.ctime(os.path.getctime(full_path))
                    file_size = os.path.getsize(full_path)
                    """
                    print full_path
                    print creation_date
                    print md5_check
                    """
                    #
                    jar_file_list.append(JarFileInfo(file_size, creation_date, md5_check, f, full_path))

    except Exception as e:
        print e


if __name__ == "__main__":
    try:
    # Nuke all contents
        download_path = os.path.join( os.getcwd(), DOWNLOADS)
        print "Removing previous files at %s" % download_path
        clean_dir(download_path)
        os.mkdir(download_path, 0777)
    except Exception as e:
        print str(e)

   
    # Get war files from nexus
    for p in PROJECTS:
        url = create_url(p, VERSION)
        if url is not None:
            #  Get that metadata!
            proj_nexus_path = get_metadata(url, p)

            war_url = "%s/%s" % (BASE_NEXUS_REPO, proj_nexus_path)
            print war_url

            # create subdir
            try:
                os.mkdir( "%s/%s" % (DOWNLOADS, p.artifact_id), 0777)
            except:
                pass
            # download
            filename =  os.path.basename(proj_nexus_path)
            print "Downloading %s in %s/%s/%s ..." % (filename, DOWNLOADS, os.getcwd(), p.artifact_id)

            full_path =  '%s/%s' % (DOWNLOADS, filename)
            download_file( war_url, full_path )
            # unzip
            print 'Unzipping %s...' % filename
            #
            out_dir =  '%s/%s' % (DOWNLOADS, p.artifact_id)
            unzip( full_path, out_dir)
            #

    # All unzipped?
    JarFiles = []
    for jar_file in FILES:
        path = os.path.join(os.getcwd(), DOWNLOADS)
        do_recursive_check(path, jar_file, JarFiles)

    # Report
    for jar_file in FILES:
        print '-----------------------------------------------------------------------------------------'
        print jar_file
        checksum = None
        file_size = None
        for f in JarFiles:
            if jar_file == f.name:
                print "%s bytes\t%s\t%s\t%s" % (f.file_size, f.md5_checksum, f.creation_date, f.file_path)

                # Check checksums
                if not checksum:
                    checksum = f.md5_checksum
                else:
                    if checksum != f.md5_checksum:
                        print '\tDifference in checksum detected %s' % jar_file

                # Check file sizes
                if not file_size:
                    file_size = f.file_size
                else:
                    if file_size != f.file_size:
                        print '\tDifference in file size detected %s' % jar_file

        """
        self.file_size = file_size
        self.creation_date = creation_date
        self.md5_checksum = md5cs
        self.file_path = file_path
        self.name = name
        """

    # Alarms
    print 'Done.'

