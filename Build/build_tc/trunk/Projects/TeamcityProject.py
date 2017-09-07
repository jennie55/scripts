__author__ = 'jimperialsosa'

"""

"""





class TeamcityProject:
    __attributes = [ 'href', 'id', 'name', 'projectId', 'projectName', 'webUrl']

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
