***************************
NRES Pipeline Documentation
***************************

This pipeline is designed to produced extracted one-dimensional spectra from the Network of Robotic Echelle Spectrographs (NRES)
instruments on the Las Cumbres Observatory (LCO) global telescope network.

Language
========
The bulk of the algorithm code is written in IDL. The IDL code is wrapped using Python to be integrated with the rest of the
LCO systems. Each time a command is run, a new instance of IDL is spawned that is run until completion. The IDL pipeline is
designed to be strictly serial (as opposed to parallel). More discussion of this is below.

Installation
============
The Python code is written as a standalone package and be installed in the usual way::

    python setup.py install

IDL Dependencies
================
The IDL code has a few dependencies that must be installed in the IDL path for the pipeline to work::

    astron
    coyote astron
    mpfit
    exofast

These dependencies require several large ancillary data files. We currently include these in the Docker image, but that
is not strictly necessary. The main reason we include those files in the Docker image is that the IDL code requires write
access to those files which is faster and simpler rather than mounting a shared drive. This has the secondary benefit of
allowing multiple instances of the pipeline to be run at the same time (See more discussion about this below).

Deployment
==========
While the standalone package should work, the intention is that the NRES pipeline be run in a Docker container.

The Python installation in the Docker file is based on the Anaconda distribution, specifically miniconda.
The dependency installation in the Dockerfile should be reasonably self explanatory. Please note that the library used to
store metrics in Open Time Series Database is only available internally at LCO.

The archive user generally runs the pipeline. To make sure that the permissions are consistent across the system, the
archive user is created in the docker container with the same user ID and group IDs as the rest of the LCO user management
system (and LDAP), currently Active Directory. **Note that this requires extreme caution**. The archive user has read/write
access to all LCO raw and processed data. A misplaced *rm* command could remove data from other telescopes.

IDL Licensing is very complicated. At LCO, we have 6 floating licenses that can be used by any machine in the LCO operations
domain. Once a machine has an open IDL instance, it locks one of those licesnses. At that point, that license will cover
an arbitrary number of IDL sessions on that machine. To ensure that the NRES pipeline always has a license, we have added
a background service into the supervisor.d configuration to start an IDL session on startup. That way, if all of the licenses are
used, we will know upon startup. Otherwise, it will lock one of the available licenses for as long as the container is up.

The IDL code is all precompiled into a .sav file as part of the Docker build process. This improves the performance of the pipeline
so that the code does not have to be recompiled each time an IDL command is spawned. It also removes the compilation messages
from the logs to making them easier to ingest in ElasticSearch.

The Docker container is managed and run through Rancher in the Pipeline environment. This Rancher environment is
set to run on chanunpa.lco.gtn. This machine has 24 cores and 96 GB of RAM, enough to run all of the LCO pipelines. Note
this is not the SBA Production Docker Cluster. It is a separate host machine.

Directory Structure
===================
The standard LCO directory structure follows the convention::

/archive/engineering/{site}/{instrument}/{day-obs}/raw/*.fits.fz

Note that the files are fpacked to optimize disk usage.
For NRES data there are two "raw" data products. One is the raw Sinistro frame from e.g. fl09, but these files are not
processed by the pipeline or are not ingested into the archive. The NRES Composite Data Products (CDPs) are considered
the raw data from NRES that are served to the users. The raw NRES CDPs are stored in::

/archive/engineering/{site}/nres{01-04}/{day-obs}/raw/*.fits.fz

These products are the raw inputs to the pipeline.

Queues
======

Worker Processes
================

Periodic Workers
==================

Metrics
=======

Logging
=======

Database
========

CSV Files
=========

Environment Variables
=====================

Output Data Products
====================

Trace Files
===========

Procedure to Start Reduction for a New Site
===========================================

#. Login as the "archive" user (again please use caution as mistyped commands can very significant consequences). ...
#. cd to the nres?? instance directory, e.g. /archive/engineering/cpt/nres03
#. Make a new directory called "reduced"
#. cd into the newly created reduced directory.
#. Make the following directories:

    .. code-block:: bash

        bias blaz ccor class config csv dark dble diag expm
        extr flat plot rv spec tar temp thar trace trip zero

#. Copy the contents of the config directory in the Github repository into the newly created config directory.

#.
    | Copy the csv files from the csv directory in the Github repository. You do not need to copy the code out of this directory.
        Only the .csv files. I recommend not copying the files from another site. This will have all of the master calibrations, etc.
        from this other site and will at least slow down performance. Copying csv files from other sites may have also have other
        unknown side effects.

#.
    | Add a new line to ccds.csv for the corresponding camera. This can typically be done by copying a previous row and
        changing the camera name, (e.g. "fl17").

#.
    | Add a new line to the spectrographs.csv file for the new site. This is also done by copying a previous line from another
        site and changing the site code (e.g. "CPT"). This only serves as a first guess for the code, but should be roughly accurate.
        It may be useful to update these coefficients automatically after getting a successful trace and wavelength solution, but
        the infrastructure to do so does not exist yet.

#.
    | Reduce a batch of bias files. For each of the individual bias frames, run the pipeline.
        Typically it is always easiest to run the pipeline from an IPython session through a
        terminal in Rancher inside the Docker container:

    .. code-block:: python

        from glob import glob
        import os
        from nrespipe import utils
        fs = glob('/archive/engineering/cpt/nres03/201712??/raw/*b00*')
        for f in fs:
            utils.post_to_fits_exchange(os.environ['FITS_BROKER'], f)

#.
    Stack the bias frames:

    .. code-block:: python

        import os
        import datetime
        # Choose a start date
        d0 = datetime.datetime(2017, 12, 3, 8)
        # Reduce all of the data over 18 days
        for i in range(18):
            start_date = d0 + datetime.timedelta(days=i)
            end_date = start_date + datetime.timedelta(days=1)
            os.system("nres_stack_calibrations --site cpt --camera fl13 --nres-instrument nres03 --calibration-type BIAS --start {start} --end {end}".format(start=start_date.strftime("%Y-%m-%dT%H:%M:%S"), end=end_date.strftime("%Y-%m-%dT%H:%M:%S")))

#.
    Reduce a batch of dark frames:

    .. code-block:: python

        from glob import glob
        import os
        from nrespipe import utils
        fs = glob('/archive/engineering/cpt/nres03/201712??/raw/*d00*')
        for f in fs:
            utils.post_to_fits_exchange(os.environ['FITS_BROKER'], f)

#.
    Stack the dark frames:

    .. code-block:: python

        import os
        import datetime
        # Choose a start date
        d0 = datetime.datetime(2017, 12, 3, 8)
        # Reduce all of the data over 18 days
        for i in range(18):
            start_date = d0 + datetime.timedelta(days=i)
            end_date = start_date + datetime.timedelta(days=1)
            os.system("nres_stack_calibrations --site cpt --camera fl13 --nres-instrument nres03 --calibration-type DARK --start {start} --end {end}".format(start=start_date.strftime("%Y-%m-%dT%H:%M:%S"), end=end_date.strftime("%Y-%m-%dT%H:%M:%S")))

#.
    | Make a starting trace file. Right now this requires us to hand trace a file (see config/ref_trace.txt for format).
        There has been development to do this automatically but is not robust yet.
        After you make the hand traced text file run:

    .. code-block:: bash

        run_nres_trace0 --site cpt --camera fl13 --nres-instrument nres03 --filename /archive/engineering/cpt/nres03/reduced/config/cpt_nres03_trace.2017a.txt

#.
    | Then refine the trace on two good S/N flat field files, one with fibers 0 and 1 illuminated,
        the other with fibers 1 and 2 illuminated:

    .. code-block:: bash

        run_nres_trace_refine --flat_filename1 /archive/engineering/cpt/nres03/20171215/raw/cptnrs03-fl13-20171215-0007-w00.fits.fz --flat_filename2 /archive/engineering/cpt/nres03/20171215/raw/cptnrs03-fl13-20171215-0003-w00.fits.fz --site cpt --camera fl13 --nres-instrument nres03

#.
    Reduce a batch of flat frames:

    .. code-block:: python

        from glob import glob
        import os
        from nrespipe import utils
        fs = glob('/archive/engineering/cpt/nres03/201712??/raw/*w00*')
        for f in fs:
            utils.post_to_fits_exchange(os.environ['FITS_BROKER'], f)

#.
    Stack the flat frames:

    .. code-block:: python

        import os
        import datetime
        # Choose a start date
        d0 = datetime.datetime(2017, 12, 3, 8)
        # Reduce all of the data over 18 days
        for i in range(18):
            start_date = d0 + datetime.timedelta(days=i)
            end_date = start_date + datetime.timedelta(days=1)
            os.system("nres_stack_calibrations --site cpt --camera fl13 --nres-instrument nres03 --calibration-type FLAT --start {start} --end {end}".format(start=start_date.strftime("%Y-%m-%dT%H:%M:%S"), end=end_date.strftime("%Y-%m-%dT%H:%M:%S")))

#.
    Reduce a batch of arc lamp exposures (i.e. DOUBLE frames):

    .. code-block:: python

        from glob import glob
        import os
        from nrespipe import utils
        fs = glob('/archive/engineering/cpt/nres03/201712??/raw/*w00*')
        for f in fs:
            utils.post_to_fits_exchange(os.environ['FITS_BROKER'], f)

#.
    Stack the arc frames. This will also create a "TRIPLE" file:

    .. code-block:: python

        import os
        import datetime
        # Choose a start date
        d0 = datetime.datetime(2017, 12, 3, 8)
        # Reduce all of the data over 18 days
        for i in range(18):
            start_date = d0 + datetime.timedelta(days=i)
            end_date = start_date + datetime.timedelta(days=1)
            os.system("nres_stack_calibrations --site cpt --camera fl13 --nres-instrument nres03 --calibration-type ARC --start {start} --end {end}".format(start=start_date.strftime("%Y-%m-%dT%H:%M:%S"), end=end_date.strftime("%Y-%m-%dT%H:%M:%S")))


#.
    | Copy a "ZERO" radial velocity template file from another site and add it to zeros.csv.
        Make sure you set the flags to "0100".

#.
    Then reduce the science spectra from a standard star:

    .. code-block:: python

        import os
        from nrespipe import utils
        f = '/archive/engineering/cpt/nres03/20171216/cptnrs03-fl13-20171216-0016-e00.fits.fz'
        utils.post_to_fits_exchange(os.environ['FITS_BROKER'], f)
        f = '/archive/engineering/cpt/nres03/20171216/cptnrs03-fl13-20171216-0017-e00.fits.fz
        utils.post_to_fits_exchange(os.environ['FITS_BROKER'], f)

#.
    Stack the standard stars. To do this, run the following from the command line:

    .. code-block:: bash

        nres_stack_calibrations --site cpt --camera fl13 --nres-instrument nres03 --calibration-type TEMPLATE --start 2017-12-16T22:40:00 --end 2017-12-16T23:00:00 --target HD49933_templ

    Then update the flags to 0100 again in the zeros.csv.

#.
    Reduce all of the science frames taken previously:

    .. code-block:: python

        from glob import glob
        import os
        from nrespipe import utils
        fs = glob('/archive/engineering/cpt/nres03/201712??/raw/*e00*')
        for f in fs:
            utils.post_to_fits_exchange(os.environ['FITS_BROKER'], f)

At this point you should be able to reduce new data as it arrives.

To schedule nightly stacking of calibration files add the following to settings.py:

    .. code-block:: python

        'cpt_stack_calibrations_nightly': {'task': 'nrespipe.tasks.make_stacked_calibrations_for_one_night',
                                        'schedule': crontab(minute=0, hour=11),
                                        'kwargs': {'site': 'cpt', 'camera': 'fl13',
                                                   'nres_instrument': 'nres03'},
                                        'options': {'queue': 'periodic'}
                                        },
        'cpt_refine_trace_nightly': {'task': 'nrespipe.tasks.refine_trace_from_last_night',
                                  'schedule': crontab(minute=1, hour=11),
                                  'kwargs': {'site': 'cpt', 'camera': 'fl13',
                                             'nres_instrument': 'nres03',
                                             'raw_data_root': '/archive/engineering'},
                                  'options': {'queue': 'periodic'}
                                  }

Making New Radial Velocity Standards (ZERO Files)
=================================================
To calculate a radial velocity, the pipeline cross correlates the observed spectrum with template spectra. Currently,
these template spectra are built from previously observed stars with a previously measured radial velocity, effective
temperature and surface gravity. We may move to synthetic stellar models eventually, but currently we used observed spectra.
Ideally, we would want 5 high signal-to-noise (S/N ~ 200) that are taken consecutively on a single telescope. More often
we have fewer observations at S/N~50.

The pipeline combines the observed spectra to make a radial velocity standard. Internally, these files are called ZERO files.
Each site has its own targets.csv file which is used to track physical information about a star (effective temperature, surface
gravity, etc.). The targets.csv file is maintained in the Github repository. Any changes to this file should be deployed in the
"reduced" directories for each of the sites.
These currently have to be build by hand. The procedure to do so is below:

#.
    | Add the target information to the targets.csv file. Typically this is done in the code repository
        on Github and then is deployed to individual sites.

    The rows have the following format:

    | Name, RA(deg), Dec(deg), Vmag, Bmag, gmag, rmag, imag, Jmag, Kmag, ProperMotionRA, ProperMotionDE,
        Parallax, RV, Teff, Logg, ZERO

    | ZERO is currently always set to "NULL". Missing magnitudes should be set to -99.9.
        Proper motions are in mas/yr. Parallax is in mas. RV is in km/s.


Considerations for Reprocessing Data
====================================

Issues Handling Malformed Input Data
====================================

Reference/API
=============

.. automodapi:: nrespipe