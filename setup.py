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
      install_requires=['numpy', 'kombu', 'celery', 'sqlalchemy', 'astropy', 'lcogt_logging', 'requests',
                        'opentsdb_python_metrics'],
      entry_points={'console_scripts': ['run_nres_listener=nrespipe.main:run_listener',
                                        'run_nres_tasks=nrespipe.main:run_celery_worker',
                                        'run_nres_periodic_worker=nrespipe.main:run_periodic_worker',
                                        'nres_stack_calibrations=nrespipe.main:stack_nres_calibrations']})
