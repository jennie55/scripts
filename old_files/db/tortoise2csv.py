import sys



class LogRecord:
    def __init__(self):
        self.revision = ''
        self.author = ''
        self.message = ''
        self.date = ''
        self.added = ''

    def clean(self):
        self.revision = ''
        self.author = ''
        self.message = ''
        self.date = ''
        self.added = ''

"""
Revision: 49995
Author: sbheemireddy
Date: Wednesday, November 04, 2015 12:09:33 PM
Message:
3.47.0 NWF-39450
----
Modified : /nwf_db/1_OLTP/trunk/3_NCOWN/4_PROCEDURE/vehmld_verification_rpt.prc

Revision: 49994
Author: sbheemireddy


"""

if __name__ == "__main__":

    if len(sys.argv) < 1:
        print 'Need one parameter'
        sys.exit(2)

    # read file in
    file_name = sys.argv[1]
    log = open(file_name, 'rt')
    lines = log.readlines()
    log.close()

    log_rec = LogRecord()
    index = 0
    for line in lines:
        if line.startswith('Revision'):
            if log_rec.revision:
                print "%s\t%s\t%s\t%s\t%s" % (log_rec.revision, log_rec.author, log_rec.date, log_rec.message, log_rec.added)
                log_rec.clean()
            rev = line.split(':')
            log_rec.revision = rev[1].strip('\n')
        if line.startswith('Author'):
            rev = line.split(':')
            log_rec.author = rev[1].strip('\n')
        if line.startswith('Date'):
            rev = line.split(':')
            date = rev[1:]
            log_rec.date = ':'.join(date).strip('\n')
        if line.startswith('Message'):
            m = lines[index+1]
            log_rec.message =m.strip('\n')

        if line.startswith('Added'):
            rev = line.split(':')
            if len(rev) > 1:
                log_rec.added = rev[1].strip('\n')

        index += 1



