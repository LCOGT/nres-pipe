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
      package_dir={'nrespipe': 'nrespipe'},
      package_data={'nrespipe': ['data/trace_reference.cat']},
      install_requires=['numpy', 'kombu', 'celery', 'sqlalchemy', 'astropy', 'lcogt_logging', 'requests',
                        'opentsdb_python_metrics>=0.1.7.5', 'sep', 'scipy'],
      entry_points={'console_scripts': ['run_nres_listener=nrespipe.main:run_listener',
                                        'run_nres_tasks=nrespipe.main:run_celery_worker',
                                        'run_nres_periodic_worker=nrespipe.main:run_periodic_worker',
                                        'nres_stack_calibrations=nrespipe.main:stack_nres_calibrations',
                                        'run_nres_beats=nrespipe.main:run_beats_scheduler',
                                        'run_nres_trace0=nrespipe.main:run_nres_trace0',
                                        'run_nres_trace_refine=nrespipe.main:run_nres_trace_refine']})
