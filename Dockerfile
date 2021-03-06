#
# Ubuntu 14.04 with activiti Dockerfile
#
# Pull base image.
FROM java:8

MAINTAINER Frank Wang "support@bpmunion.com"

ENV REFRESHED_AT 2015-05-26 22:00

USER root

RUN apt-get update

RUN apt-get install git openssh-server -y

RUN echo "export LC_ALL=C" >> /root/.bashrc                                               

# Install Supervisor.
RUN  apt-get install -y supervisor && sed -i 's/^\(\[supervisord\]\)$/\1\nnodaemon=true/' /etc/supervisor/supervisord.conf 

ADD adds/authorized_keys /authorized_keys

ADD config/config.sh /config.sh

RUN chmod u+x /config.sh

RUN sh /config.sh && rm /config.sh

ADD config/sshd.conf /etc/supervisor/conf.d/sshd.conf

ADD config/tomcat.conf /etc/supervisor/conf.d/tomcat.conf

EXPOSE 8080

EXPOSE 22 

ENV TOMCAT_VERSION 8.0.22

ENV ACTIVITI_VERSION 5.17.0

ENV MYSQL_CONNECTOR_JAVA_VERSION 5.1.35

RUN wget http://archive.apache.org/dist/tomcat/tomcat-8/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz -O /tmp/catalina.tar.gz
RUN wget https://github.com/Activiti/Activiti/releases/download/activiti-${ACTIVITI_VERSION}/activiti-${ACTIVITI_VERSION}.zip -O /tmp/activiti.zip

# Unpack
RUN tar xzf /tmp/catalina.tar.gz -C /opt
RUN ln -s /opt/apache-tomcat-${TOMCAT_VERSION} /opt/tomcat
RUN rm /tmp/catalina.tar.gz

RUN unzip /tmp/activiti.zip -d /opt/activiti

# Remove unneeded apps
RUN rm -rf /opt/tomcat/webapps/examples
RUN rm -rf /opt/tomcat/webapps/docs

# To install jar files first we need to deploy war files manually
RUN unzip /opt/activiti/activiti-${ACTIVITI_VERSION}/wars/activiti-rest.war -d /opt/tomcat/webapps/activiti-rest

# Add mysql connector to application
RUN wget http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_CONNECTOR_JAVA_VERSION}.zip -O /tmp/mysql-connector-java.zip
RUN unzip /tmp/mysql-connector-java.zip -d /tmp
RUN cp /tmp/mysql-connector-java-${MYSQL_CONNECTOR_JAVA_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_JAVA_VERSION}-bin.jar /opt/tomcat/webapps/activiti-rest/WEB-INF/lib/
#RUN cp /tmp/mysql-connector-java-${MYSQL_CONNECTOR_JAVA_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_JAVA_VERSION}-bin.jar /opt/tomcat/webapps/activiti-explorer/WEB-INF/lib/

# Add roles
ADD assets /assets
RUN cp /assets/config/tomcat/tomcat-users.xml /opt/apache-tomcat-${TOMCAT_VERSION}/conf/

CMD ["/assets/init"]

