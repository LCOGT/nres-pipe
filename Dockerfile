FROM docker.lcogt.net/miniconda3:4.3.21
MAINTAINER Las Cumbres Observatory <webmaster@lco.global>
ENTRYPOINT [ "/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf" ]

RUN yum -y install epel-release \
        && yum install -y freetype libXp libXpm libXmu redhat-lsb-core supervisor fpack \
        && yum -y clean all

RUN conda install -y -c conda-forge pip numpy cython astropy sqlalchemy pytest mock requests ipython celery \
        && conda clean -y --all

RUN mkdir -p /opt/idl/src \
        && curl -o /opt/idl/src/idl.tar.gz "http://packagerepo.lco.gtn/repos/idl/idl85envi53linux.x86_64.gz" \
        && tar -xzf /opt/idl/src/idl.tar.gz -C /opt/idl/src/ \
        && /opt/idl/src/install.sh -s <<< $'y\n/opt/idl\ny\nn\ny\ny\ny\ny\ny\ny\ny\ny\nn' \
        && rm -rf /opt/idl/src/idl.tar.gz

RUN mkdir -p /opt/idl/xtra/astron \
        && curl -o /opt/idl/xtra/astron.tar.gz "https://idlastro.gsfc.nasa.gov/ftp/astron.tar.gz" \
        && tar -xzf /opt/idl/xtra/astron.tar.gz -C /opt/idl/xtra/astron/ \
        && rm -f /opt/idl/xtra/astron.tar.gz && mkdir -p /opt/idl/xtra/astrolib/data

RUN curl -o /opt/idl/xtra/coyote_astron.tar.gz "https://idlastro.gsfc.nasa.gov/ftp/coyote_astron.tar.gz" \
        && tar -xzf /opt/idl/xtra/coyote_astron.tar.gz -C /opt/idl/xtra/astron/ \
        && rm -f /opt/idl/xtra/coyote_astron.tar.gz

RUN curl -o /opt/idl/xtra/mpfit.tar.gz "http://www.physics.wisc.edu/~craigm/idl/down/mpfit.tar.gz" \
        && mkdir -p /opt/idl/xtra/mpfit \
        && tar -xzf /opt/idl/xtra/mpfit.tar.gz -C /opt/idl/xtra/mpfit/ \
        && rm -f /opt/idl/xtra/mpfit.tar.gz

RUN mkdir /home/archive \
        && /usr/sbin/groupadd -g 10000 "domainusers" \
        && /usr/sbin/useradd -g 10000 -d /home/archive -M -N -u 10087 archive \
        && chown -R archive:domainusers /home/archive

RUN pip install opentsdb_python_metrics --trusted-host buildsba.lco.gtn --extra-index-url http://buildsba.lco.gtn/python/ \
        && rm -rf ~/.cache/pip

WORKDIR /nres/code
COPY ./util/exofast /nres/code/util/exofast
COPY . /nres/code

RUN python /nres/code/setup.py install

# trailing slash is required for nres root
ENV EXOFAST_PATH="/nres/code/util/exofast/" \
    IDL_LMGRD_LICENSE_FILE="1700@ad4sba.lco.gtn:/usr/local/itt/license/license.dat" \
    PATH="${PATH}:/opt/idl/idl/bin" \
    IDL_PATH="+/nres/code:+/opt/idl/xtra/astron/pro:+/opt/idl/xtra/exofast:+/opt/idl/xtra/mpfit:<IDL_DEFAULT>" \
    NRESROOT="/nres/" \
    ASTRO_DATA="/opt/idl/xtra/astrolib/data"

COPY docker/ /

ENV HOME /home/archive

WORKDIR /home/archive
