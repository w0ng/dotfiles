# Make IPython recognise virtualenv, Python 3 (https://gist.github.com/1759781)
from os import environ
from os.path import join, sep

if 'VIRTUAL_ENV' in environ:
    virtual_env_dir = environ['VIRTUAL_ENV']
    activate_this = join(virtual_env_dir, "bin", "activate_this.py")
    exec(compile(open(activate_this).read(), activate_this, 'exec'),
         dict(__file__=activate_this))
    virtual_env_name = virtual_env_dir.split(sep)[-1]
    print('{0:9} {1} {2}'.format('VIRT_ENV', '->', virtual_env_name))
    del activate_this, virtual_env_dir, virtual_env_name
del environ, join, sep
