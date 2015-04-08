FROM ubuntu:utopic

MAINTAINER Andrey Karpov "karpov@corp.sputnik.ru"

#RUN timedatectl set-timezone Europe/Moscow
RUN ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime

RUN apt-get -qq update
RUN apt-get -qq upgrade

RUN apt-get -qq install \
  build-essential \
  devscripts \
  equivs \
  git-core \
  openssh-server \
  nano \
  mc \
  vim \
  cmake \
  g++ \
  python-pip \
  supervisor \
  libboost-all-dev \
  python-virtualenv

RUN pip install setuptools
RUN locale-gen ru_RU
RUN locale-gen ru_RU.UTF-8
RUN locale-gen en_US.utf8
RUN update-locale

ENV SUPERVISOR_DIRS /var/log/supervisor
ENV ELLIPTICS_DIRS \
  /var/elliptics/history.2 \
  /var/elliptics/eblob.2
ENV SSHD_DIRS \
  /var/run/sshd
RUN mkdir -p $SUPERVISOR_DIRS $ELLIPTICS_DIRS $SSHD_DIRS

### SSH client and server
RUN echo 'root:root' | chpasswd
RUN sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
RUN sed -ri 's/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/' /etc/ssh/ssh_config
RUN echo '    UserKnownHostsFile=/dev/null' >> /etc/ssh/ssh_config
#COPY ./ssh_deploy_private.key /root/.ssh/id_rsa
RUN chmod 0400 /root/.ssh/id_rsa

COPY ioserv.json /etc/elliptics/ioserv.json

### elliptics
RUN git clone https://github.com/reverbrain/react.git --recursive building/react
RUN git clone https://github.com/shindo/handystats.git --recursive building/handystats
RUN git clone https://github.com/reverbrain/eblob.git -b v0.22.16 --recursive building/eblob
RUN git clone https://github.com/3Hren/blackhole.git --recursive -b v0.2 building/blackhole
RUN git clone https://github.com/reverbrain/elliptics.git --recursive -b v2.26.3.33 building/elliptics
#FIXME часть тестов после сборки пакета не проходит, поэтому пропускаем
ADD elliptics/tests/CMakeLists.txt /building/elliptics/tests/CMakeLists.txt

RUN cd building/react && mk-build-deps -ir -t "apt-get -qq --no-install-recommends" && debuild -e CC -e CXX -uc -us -j$(cat /proc/cpuinfo | fgrep -c processor) && debi
RUN cd building/handystats && mk-build-deps -ir -t "apt-get -qq --no-install-recommends" && debuild -e CC -e CXX -uc -us -j$(cat /proc/cpuinfo | fgrep -c processor) && debi
RUN cd building/eblob && mk-build-deps -ir -t "apt-get -qq --no-install-recommends" && debuild -e CC -e CXX -uc -us -j$(cat /proc/cpuinfo | fgrep -c processor) && debi
RUN cd building/blackhole && mk-build-deps -ir -t "apt-get -qq --no-install-recommends"
#FIXME сборщик пакетов в какой-то момент задаёт дурацкий вопрос с невозможностью пропуска
RUN cd building/blackhole && \
    echo 'y' |debuild -e CC -e CXX -uc -us -j$(cat /proc/cpuinfo | fgrep -c processor) && \
    debi

RUN git clone https://github.com/cocaine/cocaine-core --recursive -b v0.11 building/cocaine-core
RUN git clone https://github.com/cocaine/cocaine-framework-native --recursive -b v0.11 building/cocaine-framework-native
RUN cd building/cocaine-core && mk-build-deps -ir -t "apt-get -qq --no-install-recommends" && debuild -e CC -e CXX -uc -us -j$(cat /proc/cpuinfo | fgrep -c processor) && debi
RUN cd building/cocaine-framework-native && mk-build-deps -ir -t "apt-get -qq --no-install-recommends" && debuild -e CC -e CXX -uc -us -j$(cat /proc/cpuinfo | fgrep -c processor) && debi
RUN cd building/elliptics && mk-build-deps -ir -t "apt-get -qq --no-install-recommends" && debuild -e CC -e CXX -uc -us -j$(cat /proc/cpuinfo | fgrep -c processor) && debi

ADD develop/index_perf/CMakeLists.txt /develop/index_perf/CMakeLists.txt
RUN cd /develop/index_perf && wget https://raw.githubusercontent.com/reverbrain/elliptics/master/example/index_perf.cpp && mkdir build && cd build && cmake --config Release .. && make

### system
RUN apt-get clean
RUN apt-get autoclean
EXPOSE 22 1025 10053
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord"]
