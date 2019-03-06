FROM jboss/wildfly:16.0.0.Final

# ###license-information-start###
# The MOSAIC-Project - WildFly with MySQL-Connector
# __
# Copyright (C) 2009 - 2019 Institute for Community Medicine
# University Medicine of Greifswald - mosaic-project@uni-greifswald.de
# __
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# ###license-information-end###

MAINTAINER Ronny Schuldt <ronny.schuldt@uni-greifswald.de>

# variables
ENV MYSQL_CONNECTOR_VERSION         8.0.15
ENV MYSQL_CONNECTOR_DOWNLOAD_URL    http://central.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar
ENV MYSQL_CONNECTOR_SHA256          8ae9fca44d84506399d7f806a7896e4e056daa31571ec67c645bdcacfa434f58

ENV MARIADB_CONNECTOR_VERSION       2.4.0
ENV MARIADB_CONNECTOR_DOWNLOAD_URL  https://downloads.mariadb.com/Connectors/java/connector-java-${MARIADB_CONNECTOR_VERSION}/mariadb-java-client-${MARIADB_CONNECTOR_VERSION}.jar
ENV MARIADB_CONNECTOR_SHA256        1b7e3ab5b940df96894bcab56b7750559754ed0ee2b063338707eda33e8c66a5

ENV ECLIPSELINK_VERSION             2.7.4
ENV ECLIPSELINK_DOWNLOAD_URL        https://repo1.maven.org/maven2/org/eclipse/persistence/eclipselink/${ECLIPSELINK_VERSION}/eclipselink-${ECLIPSELINK_VERSION}.jar
ENV ECLIPSELINK_PATH                modules/system/layers/base/org/eclipse/persistence/main
ENV ECLIPSELINK_SHA256              ca7cecafa370b421bf1e34d20a41c8c8a2023c5caf7f206e74b3fdda03330dcd

ENV WAIT_FOR_IT_COMMIT_HASH         9995b721327eac7a88f0dce314ea074d5169634f
ENV WAIT_FOR_IT_DOWNLOAD_URL        https://raw.githubusercontent.com/vishnubob/wait-for-it/${WAIT_FOR_IT_COMMIT_HASH}/wait-for-it.sh
ENV WAIT_FOR_IT_SHA256              3f3790f899f53d1a10947f0b992b122a358ffa34997d8c0fe126a02bba806917

ENV WILDFLY_HOME                    /opt/jboss/wildfly
ENV ADMIN_USER                      admin
ENV JBOSS_CLI                       ${WILDFLY_HOME}/bin/jboss-cli.sh
ENV DEBUGGING                       false

ENV ENTRY_JBOSS_BATCH               /entrypoint-jboss-batch
ENV ENTRY_DEPLOYMENTS               /entrypoint-deployments
ENV READY_PATH                      /opt/jboss/ready

# create folders and permissions
USER root
RUN echo "> 1. create folders and permissions" && \
	mkdir ${ENTRY_JBOSS_BATCH} ${READY_PATH} ${ENTRY_DEPLOYMENTS} && \
	chmod go+w ${ENTRY_JBOSS_BATCH} ${READY_PATH} ${ENTRY_DEPLOYMENTS} && \
	chown jboss:jboss ${ENTRY_JBOSS_BATCH} ${READY_PATH} ${ENTRY_DEPLOYMENTS}  && \
	\
	echo "> 2. install which" && \
	[ "$(which which 2>&1 /dev/null)" != "" ] && yum -y install which || echo "  'which' already installed"

# download files and create scripts
USER jboss
RUN echo "> 3. install mysql-connector" && \
	curl -Lso mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar ${MYSQL_CONNECTOR_DOWNLOAD_URL} && \
	(sha256sum mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar | grep ${MYSQL_CONNECTOR_SHA256} || (>&2 echo "sha256sum failed $(sha256sum mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar)" && exit 1)) && \
	\
	echo "> 4. install mariadb-connector" && \
	curl -Lso mariadb-java-client-${MARIADB_CONNECTOR_VERSION}.jar ${MARIADB_CONNECTOR_DOWNLOAD_URL} && \
	(sha256sum mariadb-java-client-${MARIADB_CONNECTOR_VERSION}.jar | grep ${MARIADB_CONNECTOR_SHA256} || (>&2 echo "sha256sum failed $(sha256sum mariadb-java-client-${MARIADB_CONNECTOR_VERSION}.jar)" && exit 1)) && \
	\
	echo "> 5. install wait-for-it-script" && \
	curl -Lso wait-for-it.sh ${WAIT_FOR_IT_DOWNLOAD_URL} && \
	(sha256sum wait-for-it.sh | grep ${WAIT_FOR_IT_SHA256} || (>&2 echo "sha256sum failed $(sha256sum wait-for-it.sh)" && exit 1)) && \
	chmod +x wait-for-it.sh && \
	\
	echo "> 6. install eclipslink" && \
	curl -Lso ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar ${ECLIPSELINK_DOWNLOAD_URL} && \
	(sha256sum ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar | grep ${ECLIPSELINK_SHA256} || (>&2 echo "sha256sum failed $(sha256sum ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar)" && exit 1)) && \
	sed -i "s/<\/resources>/\n \
		<resource-root path=\"eclipselink-${ECLIPSELINK_VERSION}.jar\">\n \
		    <filter>\n \
		        <exclude path=\"javax\/**\" \/>\n \
		    <\/filter>\n \
		<\/resource-root>\n \
	<\/resources>/" ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/module.xml && \
	chown -R jboss:jboss ${WILDFLY_HOME}/${ECLIPSELINK_PATH} && \
	\
    echo "> 7. create script create_wildfly_admin.sh" && { \
        echo '#!/bin/bash'; \
        echo; \
        echo 'if [ ! -f "'${READY_PATH}'/admin.created" ]; then'; \
        echo '    echo "========================================================================="'; \
        echo '    if [ -z "${NO_ADMIN}" ]; then'; \
        echo '        WILDFLY_PASS=${WILDFLY_PASS:-$(tr -cd "[:alnum:]" < /dev/urandom | head -c20)}'; \
        echo '        '${WILDFLY_HOME}'/bin/add-user.sh '${ADMIN_USER}' ${WILDFLY_PASS} && \'; \
        echo '        echo "  You can configure this WildFly-Server using:" && \'; \
        echo '        echo "  '${ADMIN_USER}':${WILDFLY_PASS}"'; \
        echo '    else'; \
        echo '        echo "  You can NOT configure this WildFly-Server" && \'; \
        echo '        echo "  because no admin-user was created."'; \
        echo '    fi'; \
        echo '    echo "========================================================================="'; \
        echo '    touch '${READY_PATH}'/admin.created'; \
        echo 'fi'; \
    } > create_wildfly_admin.sh && \
    chmod +x create_wildfly_admin.sh && \
	\
    echo "> 8. create script wildfly_started.sh" && { \
        echo '#!/bin/bash'; \
        echo; \
        echo '[ -f '${READY_PATH}'/jboss_cli_block ] && exit 1'; \
        echo $JBOSS_CLI' -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running && exit 0'; \
        echo 'exit 1'; \
    } > wildfly_started.sh && \
    chmod +x wildfly_started.sh && \
	\
    echo "> 9. create script run.sh" && { \
        echo '#!/bin/bash'; \
        echo; \
        echo './create_wildfly_admin.sh'; \
        echo; \
        echo 'BATCH_FILES=$(comm -23 <(ls '${ENTRY_JBOSS_BATCH}' 2> /dev/null | grep -v .completed) \'; \
        echo '    <(ls '${READY_PATH}' 2> /dev/null | grep .completed | sed "s/\.completed$//"))'; \
        echo 'echo "  ${BATCH_FILES}"'; \
        echo; \
        echo 'echo "  $(echo ${BATCH_FILES} | wc -w) cli-file(s) found to execute with jboss-cli.sh"'; \
        echo; \
        echo 'if [ $(echo ${BATCH_FILES} | wc -w) -gt 0 ]; then'; \
        echo '    touch '${READY_PATH}'/jboss_cli_block'; \
        echo; \
        echo '    '${WILDFLY_HOME}'/bin/standalone.sh --admin-only &'; \
        echo '    until `'${JBOSS_CLI}' -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running`; do sleep 1; done;'; \
        echo; \
        echo '    for BATCH_FILE in ${BATCH_FILES}; do'; \
        echo '        if [ -f "'${ENTRY_JBOSS_BATCH}'/${BATCH_FILE}" ]; then'; \
        echo '            echo "execute jboss-batchfile \"${BATCH_FILE}\""'; \
        echo '            '${JBOSS_CLI}' -c --file='${ENTRY_JBOSS_BATCH}'/${BATCH_FILE}'; \
        echo '            if [ $? -eq 0 ]; then'; \
        echo '                touch '${READY_PATH}'/${BATCH_FILE}.completed'; \
        echo '            else'; \
        echo '                echo "JBoss-Batchfile \"${BATCH_FILE}\" can not be execute"'; \
        echo '                '${JBOSS_CLI}' -c ":shutdown"'; \
        echo '                exit 99'; \
        echo '            fi'; \
        echo '        fi'; \
        echo '    done'; \
        echo '    '${JBOSS_CLI}' -c ":shutdown"'; \
        echo 'fi'; \
        echo; \
        echo 'rm -f '${WILDFLY_HOME}'/standalone/configuration/standalone_xml_history/current/*'; \
        echo 'rm -f '${READY_PATH}'/jboss_cli_block'; \
        echo; \
        echo ${WILDFLY_HOME}'/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0 $([ "${DEBUGGING}" == "true" ] && echo "--debug")'; \
    } > run.sh && \
	echo "> 10. change script-permissions" && \
	chmod +x run.sh

# prepare wildfly
RUN	echo "> 11. prepare wildfly" && \
	cat run.sh && \
	${WILDFLY_HOME}/bin/standalone.sh & \
	until `./wildfly_started.sh`; do sleep 1; done ; \
	$JBOSS_CLI -c "/subsystem=deployment-scanner/scanner=entrypoint:add(scan-interval=5000,path=${ENTRY_DEPLOYMENTS})" && \
	$JBOSS_CLI -c "module add --name=com.mysql --resources=/opt/jboss/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar --dependencies=javax.api\,javax.transaction.api" && \
	$JBOSS_CLI -c "/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql,driver-class-name=com.mysql.cj.jdbc.Driver)" && \
	$JBOSS_CLI -c "module add --name=com.mariadb --resources=/opt/jboss/mariadb-java-client-${MARIADB_CONNECTOR_VERSION}.jar --dependencies=javax.api\,javax.transaction.api" && \
	$JBOSS_CLI -c "/subsystem=datasources/jdbc-driver=mariadb:add(driver-name=mariadb,driver-module-name=com.mariadb)" && \
	$JBOSS_CLI -c ":shutdown" && \
	rm -rf mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar mariadb-java-client-${MARIADB_CONNECTOR_VERSION}.jar ${WILDFLY_HOME}/standalone/configuration/standalone_xml_history/current/*

# ports
EXPOSE 8080 9990 8443 9993 8787

# check if wildfly is running
HEALTHCHECK CMD ./wildfly_started.sh

# run wildfly
CMD ["./run.sh"]
