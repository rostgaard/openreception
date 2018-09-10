# TODO:
# - Change integration_tests dependencies to use esl:master instead of devel
# Mangement-client:
#Error on line 15, column 3 of pubspec.yaml: Duplicate mapping key.
#  route_hierarchical: any
#  ^^^^^^^^^^^^^^^^^^
# - Fix version of esl that maps to serverstack

FROM debian:jessie
LABEL maintainer="krs@retrospekt.dk"
RUN apt-get update
RUN apt-get install -y git gcc make libjson-c-dev wget unzip
#RUN apt-get -y install supervisor


# Install Dart SDK (old 1.x release)
RUN wget https://storage.googleapis.com/dart-archive/channels/stable/release/1.22.0/sdk/dartsdk-linux-x64-release.zip -O /tmp/dartsdk-linux-x64-release.zip
RUN (cd /opt && unzip /tmp/dartsdk-linux-x64-release.zip)

ENV PATH="/opt/dart-sdk/bin:${PATH}"


# TODO debug tools to remove:
RUN apt-get install -y nano

# Install nginx and expose the ports
RUN apt-get install -y nginx

RUN apt-get install -y supervisor

RUN useradd -ms /bin/bash openreception
#RUN cp /opt/openreception/server_stack/tools/supervisord-configs/*.conf /etc/supervisor/conf.d/

# Symlink for supervisor configs
RUN ln -s /opt/dart-sdk/bin/dart /usr/local/bin/

RUN cd /opt && git clone https://github.com/rostgaard/openreception.git
RUN cd /opt/openreception && git pull && git checkout dart1-fixes
RUN cd /opt/openreception && make -C framework dependencies
RUN PATH=$PATH:/opt/dart-sdk/bin && cd /opt/openreception && make -C integration_tests dependencies
RUN PATH=$PATH:/opt/dart-sdk/bin && cd /opt/openreception && make -C management_client dependencies
RUN PATH=$PATH:/opt/dart-sdk/bin && cd /opt/openreception && make -C receptionist_client dependencies
RUN PATH=$PATH:/opt/dart-sdk/bin && cd /opt/openreception && make -C server_stack dependencies

COPY server_stack/lib/configuration.dart /opt/openreception/server_stack/lib/
COPY receptionist_client/web/configuration_url.dart /opt/openreception/receptionist_client/web

RUN PATH=$PATH:/opt/dart-sdk/bin && cd /opt/openreception && make -C server_stack snapshots install-symlinks
RUN PATH=$PATH:/opt/dart-sdk/bin && cd /opt/openreception && make -C receptionist_client js-build
RUN PATH=$PATH:/opt/dart-sdk/bin && cd /opt/openreception && make -C management_client build
RUN cd /opt/openreception && make -C integration_tests lib/config.dart

RUN mkdir /var/log/openreception

# Install freeswitch
RUN wget -O - https://files.freeswitch.org/repo/deb/freeswitch-1.8/fsstretch-archive-keyring.asc | apt-key add -
RUN echo "deb http://files.freeswitch.org/repo/deb/freeswitch-1.8/ jessie main" > /etc/apt/sources.list.d/freeswitch.list
RUN echo "deb-src http://files.freeswitch.org/repo/deb/freeswitch-1.8/ jessie main" >> /etc/apt/sources.list.d/freeswitch.list
# you may want to populate /etc/freeswitch at this point.
# if /etc/freeswitch does not exist, the standard vanilla configuration is deployed
RUN apt-get update && apt-get install -y freeswitch-meta-all


# Generate example data store
RUN dart /opt/openreception/integration_tests/bin/datastore_ctl.dart create  -f /var/opt/openreception
RUN dart /opt/openreception/integration_tests/bin/datastore_ctl.dart generate --reuse-store --organizations 20 --receptions 100 --reception-attr 200 --dialplans 200 --ivrs 50 --users 20 --contacts 500 -f /var/opt/openreception
RUN mkdir /var/opt/openreception/tokens
COPY server_stack/tools/admin.json /var/opt/openreception/tokens/
COPY openreception.conf /etc/nginx/sites-enabled/default
COPY server_stack/tools/supervisord-configs/*.conf /etc/supervisor/conf.d/
COPY integration_tests/conf /etc/freeswitch/

RUN mv /opt/openreception/receptionist_client/build/web /var/www/html/receptionist_client
RUN cd /opt/openreception && make -C management_client js-build

RUN mv /opt/openreception/management_client/build/web /var/www/html/management_client

RUN chown -R openreception:openreception /var/opt/openreception

EXPOSE 80
RUN false

## TODO
# - Install management interface
# - Install freeswitch and push the correct config
# - Verify that the integration tests run
# - Try setting up a machine locally with fonet SIP trunk
