FROM docker.lcogt.net/miniconda3:4.3.21
MAINTAINER Las Cumbres Observatory <webmaster@lco.global>
ENTRYPOINT [ "/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf" ]

RUN yum -y install epel-release \
        && yum install -y freetype libXp libXpm libXmu redhat-lsb-core supervisor fpack wget ghostscript \
        && yum -y clean all

RUN conda install -y -c conda-forge pip numpy cython astropy sqlalchemy pytest mock requests ipython celery \
        && conda clean -y --all

RUN mkdir /home/archive \
        && /usr/sbin/groupadd -g 10000 "domainusers" \
        && /usr/sbin/useradd -g 10000 -d /home/archive -M -N -u 10087 archive \
        && chown -R archive:domainusers /home/archive

RUN mkdir -p /opt/idl/src \
        && curl -o /opt/idl/src/idl.tar.gz "http://packagerepo.lco.gtn/repos/idl/idl85envi53linux.x86_64.gz" \
        && tar -xzf /opt/idl/src/idl.tar.gz -C /opt/idl/src/ \
        && /opt/idl/src/install.sh -s <<< $'y\n/opt/idl\ny\nn\ny\ny\ny\ny\ny\ny\ny\ny\nn' \
        && rm -rf /opt/idl/src/idl.tar.gz \
        && chown -R archive:domainusers /opt/idl

RUN mkdir -p /opt/idl/xtra/astron \
        && curl -o /opt/idl/xtra/astron.tar.gz "https://idlastro.gsfc.nasa.gov/ftp/astron.tar.gz" \
        && tar -xzf /opt/idl/xtra/astron.tar.gz -C /opt/idl/xtra/astron/ \
        && rm -f /opt/idl/xtra/astron.tar.gz && mkdir -p /opt/idl/xtra/astrolib/data \
        && chown -R archive:domainusers /opt/idl/xtra

RUN curl -o /opt/idl/xtra/coyote_astron.tar.gz "https://idlastro.gsfc.nasa.gov/ftp/coyote_astron.tar.gz" \
        && tar -xzf /opt/idl/xtra/coyote_astron.tar.gz -C /opt/idl/xtra/astron/ \
        && rm -f /opt/idl/xtra/coyote_astron.tar.gz

RUN curl -o /opt/idl/xtra/mpfit.tar.gz "http://www.physics.wisc.edu/~craigm/idl/down/mpfit.tar.gz" \
        && mkdir -p /opt/idl/xtra/mpfit \
        && tar -xzf /opt/idl/xtra/mpfit.tar.gz -C /opt/idl/xtra/mpfit/ \
        && rm -f /opt/idl/xtra/mpfit.tar.gz \
        && chown -R archive:domainusers /opt/idl/xtra/mpfit

RUN curl -o /opt/idl/xtra/exofast.tgz "http://www.astronomy.ohio-state.edu/~jdeast/exofast.tgz" \
        && mkdir -p /opt/idl/xtra/exofast \
        && tar -xzf /opt/idl/xtra/exofast.tgz -C /opt/idl/xtra/exofast/ \
        && rm -f /opt/idl/xtra/exofast.tgz \
        && sed -i -e '123s/\[0d0/\[1d-30/' /opt/idl/xtra/exofast/exofast/bary/zbarycorr.pro \
        && chown -R archive:domainusers /opt/idl/xtra/exofast

# trailing slash is required for nres root
ENV EXOFAST_PATH="/nres/code/util/exofast/" \
    IDL_LMGRD_LICENSE_FILE="1700@ad4sba.lco.gtn:/usr/local/itt/license/license.dat" \
    PATH="${PATH}:/opt/idl/idl/bin" \
    IDL_PATH="+/nres/code:+/opt/idl/xtra/astron/pro:+/opt/idl/xtra/exofast:+/opt/idl/xtra/mpfit:<IDL_DEFAULT>" \
    NRESROOT="/nres/" \
    ASTRO_DATA="/opt/idl/xtra/exofast/exofast/bary"

RUN pip install lcogt-logging && pip install opentsdb_python_metrics --trusted-host buildsba.lco.gtn --extra-index-url http://buildsba.lco.gtn/python/ \
        && rm -rf ~/.cache/pip

RUN conda install -y sep scipy sphinx -c openastronomy  \
        && conda clean -y --all

# Switch to wget?
RUN curl -o $ASTRO_DATA/tai-utc.dat ftp://maia.usno.navy.mil/ser7/tai-utc.dat \
        && curl --ftp-pasv -o $ASTRO_DATA/TTBIPM.09  ftp://ftp2.bipm.org/pub/tai/ttbipm/TTBIPM.09 \
        && curl --ftp-pasv -o $ASTRO_DATA/TTBIPM09.ext ftp://ftp2.bipm.org/pub/tai/ttbipm/TTBIPM.09.ext \
        && cat $ASTRO_DATA/TTBIPM.09 $ASTRO_DATA/TTBIPM09.ext > $ASTRO_DATA/bipmfile \
        && curl --ftp-pasv -o $ASTRO_DATA/finals.all ftp://maia.usno.navy.mil/ser7/finals.all \
        && cp $ASTRO_DATA/finals.all $ASTRO_DATA/iers_final_a.dat \
        && python -c "from astropy import time; print(time.Time.now().jd)" > $ASTRO_DATA/exofast_update \
        && chown -R archive:domainusers $ASTRO_DATA

COPY . /nres/code/

WORKDIR /nres/code

RUN python /nres/code/setup.py install


RUN idl -e precompile_nrespipe -quiet  -args '/nres/code/precompile.sav' \
        && chown -R archive /nres/code

ENV NRES_IDL_PRECOMPILE='/nres/code/precompile.sav'

COPY docker/ /

ENV HOME /home/archive

WORKDIR /home/archive
