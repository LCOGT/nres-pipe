FROM centos:7
RUN yum install -y freetype libXp libXpm libXmu
RUN mkdir -p /opt/idl/src && \
    curl -o /opt/idl/src/idl.tar.gz "http://nagios.lco.gtn/repos/idl/idl85envi53linux.x86_64.gz" && \
    tar -xzf /opt/idl/src/idl.tar.gz -C /opt/idl/src/
COPY docker/idl.sh /etc/profile.d/
COPY docker/idl.csh /etc/profile.d/
COPY docker/answers.txt /opt/idl/src/
RUN /opt/idl/src/install.sh -s < /opt/idl/src/answers.txt
ENV PATH /opt/idl/idl85/bin:$PATH
WORKDIR /nres/
COPY . /nres/

