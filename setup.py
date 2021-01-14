"""
nrespipe - Data reduction pipeline for NRES

Author
    Curtis McCully (cmccully@lco.global)
    Tim Brown (tbrown@lco.global)
    Rob Siverd (rsiverd@lco.global)

June 2017
"""
from setuptools import setup, find_packages

setup(name='nrespipe',
      author=['Curtis McCully', 'Tim Brown', 'Rob Siverd'],
      author_email=['cmccully@lco.global', 'tbrown@lco.global', 'rsiverd@lco.global'],
      version=0.1,
      packages=find_packages(),
      package_dir={'nrespipe': 'nrespipe'},
      package_data={'nrespipe': ['data/trace_reference.cat']},
      setup_requires=['pytest-runner'],
      install_requires=['numpy', 'secretstorage==3.0.1', 'kombu', 'celery', "SQLAlchemy>1.3.0", 'astropy', 'lcogt_logging', 'requests',
                        'opentsdb_python_metrics>=0.2.0', 'sep', 'scipy', 'sphinx', 'sphinx-automodapi', 'astroquery==0.3.9',
                        'matplotlib', 'pypdf2', 'kombu', 'python-dateutil', 'ocs_ingester>=2.2.5'],
      tests_require=['pytest'],
      entry_points={'console_scripts': ['run_nres_listener=nrespipe.main:run_listener',
                                        'run_nres_tasks=nrespipe.main:run_celery_worker',
                                        'run_nres_periodic_worker=nrespipe.main:run_periodic_worker',
                                        'nres_stack_calibrations=nrespipe.main:stack_nres_calibrations',
                                        'run_nres_beats=nrespipe.main:run_beats_scheduler',
                                        'run_nres_trace0=nrespipe.main:run_nres_trace0',
                                        'run_nres_trace_refine=nrespipe.main:run_nres_trace_refine',
                                        'nres_sn=nrespipe.main:make_signal_to_noise_plot']})
