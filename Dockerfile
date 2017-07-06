FROM docker.lcogt.net/miniconda3:4.0.5
MAINTAINER Las Cumbres Observatory <webmaster@lco.global>

RUN yum -y install epel-release && \
    yum install -y freetype libXp libXpm libXmu redhat-lsb-core-4.1-27.el7.centos.1.x86_64 supervisor

RUN conda install -y -c conda-forge pip numpy cython astropy sqlalchemy pytest mock requests ipython celery\
        && conda clean -y --all

RUN mkdir -p /opt/idl/src && \
    curl -o /opt/idl/src/idl.tar.gz "http://packagerepo.lco.gtn/repos/idl/idl85envi53linux.x86_64.gz" && \
    tar -xzf /opt/idl/src/idl.tar.gz -C /opt/idl/src/

RUN /opt/idl/src/install.sh -s <<< $'y\n/opt/idl\ny\nn\ny\ny\ny\ny\ny\ny\ny\ny\nn'
RUN mkdir -p /opt/idl/xtra/astron && \
    curl -o /opt/idl/xtra/astron.tar.gz "https://idlastro.gsfc.nasa.gov/ftp/astron.tar.gz" && \
    tar -xzf /opt/idl/xtra/astron.tar.gz -C /opt/idl/xtra/astron/ && rm -f /opt/idl/xtra/astron.tar.gz


RUN curl -o /opt/idl/xtra/exofast.tar.gz http://www.astronomy.ohio-state.edu/~jdeast/exofast.tgz && \
    tar -xzf /opt/idl/xtra/exofast.tar.gz -C /opt/idl/xtra/ && rm -f /opt/idl/xtra/exofast.tar.gz && \
    mkdir -p /opt/idl/xtra/astrolib/data

ENTRYPOINT exec /usr/bin/supervisord -n -c /etc/supervisord.conf

WORKDIR /nres/code
COPY . /nres/code

RUN python /nres/code/setup.py install

# trailing slash is required for nres root
ENV EXOFAST_PATH="/opt/idl/xtra/exofast/" IDL_LMGRD_LICENSE_FILE="1700@ad4sba.lco.gtn:/usr/local/itt/license/license.dat" \
    PATH="${PATH}:/opt/idl/idl/bin" \
    IDL_PATH="+/nres/code:+/opt/idl/xtra/astron/pro:+/opt/idl/xtra/exofast:<IDL_DEFAULT>" NRESROOT="/nres/" ASTRO_DATA="/opt/idl/xtra/astrolib/data"

# COPY docker/supervisor-app.conf /etc/supervisor/conf.d/
COPY docker/ /
