
import os
import sys
import svn.remote
import svn.local


import shutil


class CreateBranchApp():



    def __init__(self):
        pass

    def parse_commandline(self, arguments):
        #TODO: real command line parsing
        self.version = '3.47.0'
        self.svn_branch = 'REL_3.47'
        self.svn_root = 'http://144.70.182.112/ted3'
        self.project_file = './projects_3.46.list'
        self.checkout_root = './ted3'

        self.BRANCHES = 'branches'
        self.TRUNK = 'trunk'

    def get_projects(self):
        project_list = []
        f = open( self.project_file, 'rt')
        lines = f.readlines()
        f.close()
        for line in lines:
            if not '(' in line:
                if not ')' in line:
                    project_list.append(line.strip('\n'))
        return project_list

    def check_projects_exist(self, projects):
        not_in_repo = []
        for project in projects:
            try:
                path = '%s/%s/%s' % (self.svn_root, project,self.TRUNK)
                svn_remote = svn.remote.RemoteClient(path)
                info = svn_remote.info()
                print '.',

            except Exception as e:
                not_in_repo.append(project)
        print '.'

        return not_in_repo

    def get_missing_branches(self, projects):
        no_branches = []
        for project in projects:
            try:
                path = '%s/%s/%s' % (self.svn_root, project,self.BRANCHES)
                svn_remote = svn.remote.RemoteClient(path)
                info = svn_remote.info()
                print '.',
            except Exception as e:
                no_branches.append(project)
        print '.'
        return no_branches

    def create_branch(self, projects):
        errors = []
        for project in projects:
            try:
                source_path =  '%s/%s/%s' % (self.svn_root, project,self.TRUNK)
                dest_path =  '%s/%s/%s/%s' % (self.svn_root, project,self.BRANCHES, self.svn_branch)
                svn_remote = svn.remote.RemoteClient(source_path)
                svn_remote.copy_tree(dest_path, msg='Creating branch %s' % self.svn_branch)
                print '.',
            except Exception as e:
                errors.append(project)
                print "%s" % str(e)
        print '.'
        return errors

    def checkout_projects(self, projects):
        errors = []

        for project in projects:
            try:
                source_path =  '%s/%s/%s/%s' % (self.svn_root, project,self.BRANCHES, self.svn_branch)
                svn_remote = svn.remote.RemoteClient(source_path)
                svn_remote.checkout("%s/%s/%s" % (self.checkout_root, self.version, project) )
                print '.',
            except Exception as e:
                errors.append(project)
                print "%s" % str(e)
        print '.'
        return errors

    def commit_all_changes(self, projects):
        errors = []
        for project in projects:
            try:

                path = "%s/%s/%s" % (self.checkout_root, self.version, project)
                svn_local = svn.local.LocalClient(path)
                info = svn_local.info()
                svn_local.run_command('commit', [path, '-m', 'committed'])
                print '.',
            except Exception as e:
                errors.append(project)
                print "%s" % str(e)
        print '.'
        return errors


    def change_pom_files(self, projects):
        pom_list = []
        for root, dirs, files in os.walk('%s/%s' % (self.checkout_root, self.version)):
            for name in files:
                if name == 'pom.xml':
                    file_name = os.path.join(root,name)
                    print file_name
                    pom_list.append(file_name)
                    # change it
                    f = open(file_name, 'rt')
                    lines = f.readlines()
                    f.close()
                    f = open(file_name, 'wt')

                    for line in lines:
                        if 'NIGHTLY-SNAPSHOT' in line:
                            line = line.replace('NIGHTLY-SNAPSHOT', self.version)
                        f.write( '%s' % line)

                    f.close()

        return pom_list

    def create_target_list(self, pom_list):
        file_name = '%s/%s' % (self.checkout_root, 'targets.txt')
        target_list = open(file_name, 'wt')
        for pom in pom_list:
            target_list.write('%s\n' % pom)
        target_list.close()
        return file_name





    def run(self):
        #
        print 'Get file list from %s...' % self.project_file
        projects = self.get_projects()

        # Verify that trunk exists for all projects
        print 'Verifying that projects exist in %s...' % self.svn_root
        not_in_repo = self.check_projects_exist(projects)
        if len(not_in_repo):
            print 'The following projects were not in the repository:'
            for proj in not_in_repo: print '\t%s' % proj
            return -1

        #
        print 'Verifying that \'branches\' exist...'
        branches_missing = self.get_missing_branches(projects)
        if len(branches_missing):
            print 'The following projects do not have a branches directory:'
            for proj in branches_missing: print '\t%s' % proj
            return -1

        #
        print 'Branching now...'
        error_branches = self.create_branch(projects)
        if len(error_branches):
            print 'The following projects could not be branched:'
            for proj in error_branches: print '\t%s' % proj
            return -1

        try:
            shutil.rmtree('%s/%s' % (self.checkout_root, self.version))
        except Exception:
            pass

        # Check out and change pom files
        print 'Checking out new branch...'
        self.checkout_projects(projects)

        print 'Changing pom files'
        pom_list = self.change_pom_files(projects)
        target_list = self.create_target_list(pom_list)


        print 'Updating subversion branch with new versions in pom files'
        error_commits = self.commit_all_changes(projects)

        return 0


if __name__ == '__main__':
    app = CreateBranchApp()
    app.parse_commandline(sys.argv)
    sys.exit(app.run())