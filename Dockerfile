FROM centos:7
ENV IDL /opt/idl/src/
RUN mkdir -p $IDL
WORKDIR $IDL
RUN curl -o idl.tar.gz "http://nagios.lco.gtn/repos/idl/idl85envi53linux.x86_64.gz"
RUN yum install -y freetype libXp libXpm libXmu
RUN tar -xzf idl.tar.gz
COPY docker/answers.txt .
COPY docker/idl.sh /etc/profile.d/
COPY docker/idl.csh /etc/profile.d/
RUN ./install.sh -s < ./answers.txt


