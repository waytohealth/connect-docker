FROM openjdk:11-jre

COPY mysql-apt-config_0.8.15-1_all.deb /tmp/

RUN apt-get clean && apt-get update && apt-get install -y --no-install-recommends locales postgresql-client lsb-release \
    && echo 4 | dpkg -i /tmp/mysql-apt-config_0.8.15-1_all.deb \
    && apt-get update && apt-get install -y mysql-community-client \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN curl -SL 'https://s3.amazonaws.com/downloads.mirthcorp.com/connect/3.9.1.b263/mirthconnect-3.9.1.b263-unix.tar.gz' \
    | tar -xzC /opt \
    && mv "/opt/Mirth Connect" /opt/connect

RUN useradd -u 1000 mirth
RUN mkdir -p /opt/connect/appdata && chown -R mirth:mirth /opt/connect/appdata

VOLUME /opt/connect/appdata
VOLUME /opt/connect/custom-extensions
WORKDIR /opt/connect
RUN rm -rf cli-lib manager-lib \
    && rm mirth-cli-launcher.jar mirth-manager-launcher.jar mccommand mcmanager
RUN (cat mcserver.vmoptions /opt/connect/docs/mcservice-java9+.vmoptions ; echo "") > mcserver_base.vmoptions
EXPOSE 8443

# Set container timezone to Eastern Time
RUN rm -fv /etc/localtime && ln -sv /usr/share/zoneinfo/America/New_York /etc/localtime && echo 'America/New_York' > /etc/timezone

# Install UPHS's CA certificate
COPY mysql-apt-config_0.8.15-1_all.deb /tmp/
COPY uphscert.der /tmp
RUN keytool -import -alias uphscert -cacerts -file /tmp/uphscert.der -noprompt -storepass changeit

COPY entrypoint.sh /
RUN chmod 755 /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

RUN chown -R mirth:mirth /opt/connect
USER mirth
CMD ["./mcserver"]