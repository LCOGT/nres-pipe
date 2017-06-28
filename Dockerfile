FROM docker.lcogt.net/miniconda3:4.0.5
MAINTAINER Las Cumbres Observatory <webmaster@lco.global>

RUN yum install -y freetype libXp libXpm libXmu


RUN conda install -y pip numpy cython astropy sqlalchemy pytest mock requests ipython \
        && conda clean -y --all

RUN mkdir -p /opt/idl/src && \
    curl -o /opt/idl/src/idl.tar.gz "http://packagerepo.lco.gtn/repos/idl/idl85envi53linux.x86_64.gz" && \
    tar -xzf /opt/idl/src/idl.tar.gz -C /opt/idl/src/

COPY docker/answers.txt /opt/idl/src/

RUN /opt/idl/src/install.sh -s < /opt/idl/src/answers.txt

RUN mkdir -p /opt/idl/xtra/astron && \
    curl -o /opt/idl/xtra/astron.tar.gz "http://idlastro.gsfc.nasa.gov/ftp/astron.tar.gz" && \
    tar -xzf /opt/idl/xtra/astron.tar.gz -C /opt/idl/xtra/astron/

WORKDIR /nres/code
COPY docker/idl.sh /etc/profile.d/
COPY . /nres/code

