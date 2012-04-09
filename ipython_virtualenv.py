# http://blog.ufsoft.org/2009/1/29/ipython-and-virtualenv
import site
from os import environ
from os.path import join
from sys import version_info

if 'VIRTUAL_ENV' in environ:
    virtual_env = join(environ.get('VIRTUAL_ENV'),
                       'lib',
                       'python%d.%d' % version_info[:2],
                       'site-packages')
    site.addsitedir(virtual_env)
    print 'VIRTUAL_ENV ->', virtual_env
    del virtual_env
del site, environ, join, version_info
