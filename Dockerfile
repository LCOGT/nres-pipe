FROM docker.lco.global/docker-miniconda3:4.7.12
MAINTAINER Las Cumbres Observatory <webmaster@lco.global>
ENTRYPOINT [ "/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf" ]

RUN yum -y install epel-release mariadb-devel sudo gcc xorg-x11-server-Xvfb \
        && yum install -y freetype libXp libXpm libXmu redhat-lsb-core supervisor fpack wget ghostscript \
        && yum -y clean all

COPY pip_requirements.txt conda_requirements.txt /opt/

RUN conda install -y --file /opt/conda_requirements.txt \
        && conda clean -y --all

RUN pip install -r /opt/pip_requirements.txt --trusted-host buildsba.lco.gtn --extra-index-url http://buildsba.lco.gtn/python/ --no-cache-dir

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

RUN curl -o /opt/idl/xtra/mpfit.tar.gz "https://pages.physics.wisc.edu/~craigm/idl/down/mpfit.tar.gz" \
        && mkdir -p /opt/idl/xtra/mpfit \
        && tar -xzf /opt/idl/xtra/mpfit.tar.gz -C /opt/idl/xtra/mpfit/ \
        && rm -f /opt/idl/xtra/mpfit.tar.gz \
        && chown -R archive:domainusers /opt/idl/xtra/mpfit

# trailing slash is required for nres root
ENV EXOFAST_PATH="/nres-pipe/code/util/exofast/" \
    IDL_LMGRD_LICENSE_FILE="1700@ad4sba.lco.gtn:/usr/local/itt/license/license.dat" \
    PATH="${PATH}:/opt/idl/idl/bin" \
    IDL_PATH="+/nres-pipe/code:+/opt/idl/xtra/astron/pro:+/opt/idl/xtra/exofast:+/opt/idl/xtra/mpfit:<IDL_DEFAULT>" \
    NRESROOT="/nres/" \
    ASTRO_DATA="/opt/idl/xtra/exofast/exofast/bary/"

RUN curl -o /opt/idl/xtra/exofast.tgz "http://www.astronomy.ohio-state.edu/~jdeast/exofast.tgz" \
        && mkdir -p /opt/idl/xtra/exofast \
        && tar -xzf /opt/idl/xtra/exofast.tgz -C /opt/idl/xtra/exofast/ \
        && rm -f /opt/idl/xtra/exofast.tgz \
        && sed -i -e '123s/\[0d0/\[1d-30/' /opt/idl/xtra/exofast/exofast/bary/zbarycorr.pro \
        && chown -R archive:domainusers /opt/idl/xtra/exofast

# Switch to wget?
RUN curl --ftp-pasv -o $ASTRO_DATA/TTBIPM.09  ftp://ftp2.bipm.org/pub/tai/ttbipm/TTBIPM.2009 \
        && curl --ftp-pasv -o $ASTRO_DATA/TTBIPM09.ext ftp://ftp2.bipm.org/pub/tai/ttbipm/TTBIPM.09.ext \
        && cat $ASTRO_DATA/TTBIPM.09 $ASTRO_DATA/TTBIPM09.ext > $ASTRO_DATA/bipmfile \
        && wget https://datacenter.iers.org/data/latestVersion/7_FINALS.ALL_IAU1980_V2013_017.txt -P $ASTRO_DATA \
        && cp $ASTRO_DATA/7_FINALS.ALL_IAU1980_V2013_017.txt $ASTRO_DATA/iers_final_a.dat \
        && python -c "from astropy import time; print(time.Time.now().jd)" > $ASTRO_DATA/exofast_update

RUN git clone https://github.com/mstamy2/PyPDF2 /usr/src/pypdf2

WORKDIR /usr/src/pypdf2

RUN python setup.py install

ENV DISPLAY=":99"

COPY . /nres-pipe/code/

RUN mv /nres-pipe/code/bary/* $ASTRO_DATA/ \
        && chown -R archive:domainusers $ASTRO_DATA

WORKDIR /nres-pipe/code

RUN python /nres-pipe/code/setup.py install

RUN idl -e precompile_nrespipe -quiet  -args '/nres-pipe/code/precompile.sav' \
        && chown -R archive /nres-pipe/code && [ -f /nres-pipe/code/precompile.sav ]

ENV NRES_IDL_PRECOMPILE='/nres-pipe/code/precompile.sav'

COPY docker/ /

RUN chown -R archive:domainusers /opt/conda

ENV HOME /home/archive

WORKDIR /home/archive
