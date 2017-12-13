*************************
NRES Pipeline Documentation
*************************

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
These currently have to be build by hand. The procedure to do so is below::

1. Add the target information to the targets.csv file. Typically this is done in the code repository on Github and then
is deployed to individual sites.


Considerations for Reprocessing Data
====================================

Issues Handling Malformed Input Data
====================================

Reference/API
=============

.. automodapi:: nrespipe