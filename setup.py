"""
nrespipe - Data reduction pipeline for NRES

Author
    Curtis McCully (cmccully@lco.global)
    Tim Brown (tbrown@lco.global)
    Rob Siverd (rsiverd@lco.global)

June 2017
"""
from setuptools import setup

setup(name='nrespipe',
      author=['Curtis McCully', 'Tim Brown', 'Rob Siverd'],
      author_email=['cmccully@lco.global', 'tbrown@lco.global', 'rsiverd@lco.global'],
      version=0.1,
      packages=['nrespipe'],
      install_requires=['numpy', 'kombu', 'celery', 'sqlalchemy', 'astropy', 'lcogt_logging'],
      entry_points={'console_scripts': ['nres_listener=nrespipe.main:run_listener',
                                        'nres_celery=nrespipe.main:run_celery_tasks']})
