# Copyright: Moshe Zadka (c) 2002
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY AUTHORS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

import sys, os

class DebconfError(Exception):
    pass

LOW, MEDIUM, HIGH, CRITICAL = 'low', 'medium', 'high', 'critical'

class Debconf:

    def __init__(self, title=None):
        for command in ('capb set reset title input beginblock endblock go get'
                        ' register unregister subst fset fget'
                        ' visible purge metaget exist version settitle').split():
            self.setCommand(command)
        self.write, self.read = sys.stdout, sys.stdin
        sys.stdout = sys.stderr
        self.setUp(title)

    def setUp(self, title):
        self.version = self.version(2)
        if self.version[:2] != '2.':
            raise DebconfError(256, "wrong version: %s" % self.version)
        self.capabilities = self.capb().split()
        if title:
            self.title(title)

    def setCommand(self, command):
        setattr(self, command,
               lambda *args, **kw: self.command(command, *args, **kw))

    def command(self, command, *params):
        command = command.upper()
        self.write.write("%s %s\n" % (command, ' '.join(map(str, params))))
        self.write.flush()
        resp = self.read.readline().strip()
        if ' ' in resp:
            status, data = resp.split(' ', 1)
        else:
            status, data = resp, ''
        status = int(status)
        if status == 0:
            return data
        else:
            raise DebconfError(status, data)

    def stop(self):
        self.write.write('STOP\n')
        self.write.flush()

    def forceInput(self, priority, question):
        try:
            self.input(priority, question)
            return 1
        except DebconfError, e:
            if e.args[0] != 30:
                raise
        return 0

    def getBoolean(self, question):
        bool = self.get(question)
        return bool == 'true'

    def getString(self, question):
        return self.get(question)


_frontEndProgram = '/usr/share/debconf/frontend'

def runFrontEnd():
    if not os.environ.has_key('DEBIAN_HAS_FRONTEND'):
        os.execv(_frontEndProgram, [_frontEndProgram, sys.executable]+sys.argv)


if __name__ == '__main__':
    runFrontEnd()
    db = Debconf()
    db.forceInput(CRITICAL, 'bsdmainutils/calendar_lib_is_not_empty')
    db.go()
    less = db.getBoolean('less/add_mime_handler')
    aptlc = db.getString('apt-listchanges/email-address')
    db.stop()
    print db.version
    print db.capabilities
    print less
    print aptlc
