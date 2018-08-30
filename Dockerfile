FROM jboss/wildfly:13.0.0.Final

# ###license-information-start###
# The MOSAIC-Project - WildFly with MySQL-Connector
# __
# Copyright (C) 2009 - 2017 Institute for Community Medicine
# University Medicine of Greifswald – mosaic-project@uni-greifswald.de
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


ENV MYSQL_CONNECTOR_VERSION			8.0.11
ENV MYSQL_CONNECTOR_DOWNLOAD_URL	http://central.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar
ENV MYSQL_CONNECTOR_SHA256			0cbe25eb4b4e7a38f52374a46283fc2381c68870581651925db752000c0d053d

ENV MARIADB_CONNECTOR_VERSION		2.2.6
ENV MARIADB_CONNECTOR_DOWNLOAD_URL	https://downloads.mariadb.com/Connectors/java/connector-java-${MARIADB_CONNECTOR_VERSION}/mariadb-java-client-${MARIADB_CONNECTOR_VERSION}.jar
ENV MARIADB_CONNECTOR_SHA256		4d28fbd8fd4ea239b0ef9482f56ce77e2ef197a60d523a8ee3c84eb984fc76fe

ENV ECLIPSELINK_VERSION				2.7.3
ENV ECLIPSELINK_DOWNLOAD_URL		https://repo1.maven.org/maven2/org/eclipse/persistence/eclipselink/${ECLIPSELINK_VERSION}/eclipselink-${ECLIPSELINK_VERSION}.jar
ENV ECLIPSELINK_PATH				modules/system/layers/base/org/eclipse/persistence/main
ENV ECLIPSELINK_SHA256				028b097396296c7442d2de14c3f6abda25c8e34c1b4134de6ade3b1e6aacc07f

ENV WAIT_FOR_IT_COMMIT_HASH			8ed92e8cab83cfed76ff012ed4a36cef74b28096
ENV WAIT_FOR_IT_DOWNLOAD_URL		https://raw.githubusercontent.com/vishnubob/wait-for-it/${WAIT_FOR_IT_COMMIT_HASH}/wait-for-it.sh
ENV WAIT_FOR_IT_SHA256				0f75de5c9d9c37a933bb9744ffd710750d5773892930cfe40509fa505788835c

ENV WILDFLY_HOME					/opt/jboss/wildfly
ENV ADMIN_USER						admin
ENV JBOSS_CLI						$WILDFLY_HOME/bin/jboss-cli.sh

ENV ENTRY_JBOSS_BATCH				/entrypoint-jboss-batch
ENV ENTRY_DEPLOYMENTS				/entrypoint-deployments
ENV READY_PATH						/opt/jboss/ready


USER root
RUN mkdir $ENTRY_JBOSS_BATCH $READY_PATH $ENTRY_DEPLOYMENTS && \
	chmod go+w $ENTRY_JBOSS_BATCH $READY_PATH $ENTRY_DEPLOYMENTS && \
	chown jboss:jboss $ENTRY_JBOSS_BATCH $READY_PATH $ENTRY_DEPLOYMENTS && \
	yum -y install which
USER jboss

# prepare WildFly
RUN echo "1. download mysql-connector" && curl -Lso mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar ${MYSQL_CONNECTOR_DOWNLOAD_URL} && \
	echo "2. check mysql-connector" && (sha256sum mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar | grep ${MYSQL_CONNECTOR_SHA256} || (>&2 echo "sha256sum failed $(sha256sum mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar)" && exit 1)) && \

	echo "3. download mariadb-connector" && curl -Lso mariadb-java-client-${MARIADB_CONNECTOR_VERSION}.jar ${MARIADB_CONNECTOR_DOWNLOAD_URL} && \
	echo "4. check mariadb-connector" && (sha256sum mariadb-java-client-${MARIADB_CONNECTOR_VERSION}.jar | grep ${MARIADB_CONNECTOR_SHA256} || (>&2 echo "sha256sum failed $(sha256sum mariadb-java-client-${MARIADB_CONNECTOR_VERSION}.jar)" && exit 1)) && \

	echo "5. download wait-for-it-script" && curl -Lso wait-for-it.sh ${WAIT_FOR_IT_DOWNLOAD_URL} && \
	echo "6. check wait-for-it-script" && (sha256sum wait-for-it.sh | grep ${WAIT_FOR_IT_SHA256} || (>&2 echo "sha256sum failed $(sha256sum wait-for-it.sh)" && exit 1)) && \

	echo "7. download eclipslink" && curl -Lso ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar ${ECLIPSELINK_DOWNLOAD_URL} && \
	echo "8. check eclipslink" && (sha256sum ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar | grep ${ECLIPSELINK_SHA256} || (>&2 echo "sha256sum failed $(sha256sum ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar)" && exit 1)) && \
	echo "9. configure eclipslink" && sed -i "s/<\/resources>/\n \
		<resource-root path=\"eclipselink-$ECLIPSELINK_VERSION.jar\">\n \
		    <filter>\n \
		        <exclude path=\"javax\/**\" \/>\n \
		    <\/filter>\n \
		<\/resource-root>\n \
	<\/resources>/" ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/module.xml && \
	echo "10. change owner eclipslink" && chown -R jboss:jboss ${WILDFLY_HOME}/${ECLIPSELINK_PATH} && \

    echo "11. create script create_wildfly_admin.sh" && { \
        echo '#!/bin/bash'; \
        echo; \
        echo 'if [ ! -f "'$READY_PATH'/admin.created" ]; then'; \
        echo '    echo "========================================================================="'; \
        echo '    if [ -z "$NO_ADMIN" ]; then'; \
        echo '        WILDFLY_PASS=${WILDFLY_PASS:-$(tr -cd "[:alnum:]_#+*;&%$§=" < /dev/urandom | head -c20)}'; \
        echo '        '$WILDFLY_HOME'/bin/add-user.sh '$ADMIN_USER' $WILDFLY_PASS && \'; \
        echo '        echo "  You can configure this WildFly-Server using:" && \'; \
        echo '        echo "  '$ADMIN_USER':$WILDFLY_PASS"'; \
        echo '    else'; \
        echo '        echo "  You can NOT configure this WildFly-Server" && \'; \
        echo '        echo "  because no admin-user was created."'; \
        echo '    fi'; \
        echo '    echo "========================================================================="'; \
        echo '    touch '$READY_PATH'/admin.created'; \
        echo 'fi'; \
    } > create_wildfly_admin.sh && \

    echo "12. create script wildfly_started.sh" && { \
        echo '#!/bin/bash'; \
        echo; \
        echo '[ -f '$READY_PATH'/jboss_cli_block ] && exit 1'; \
        echo $JBOSS_CLI' -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running && exit 0'; \
        echo 'exit 1'; \
    } > wildfly_started.sh && \

    echo "13. create script run.sh" && { \
        echo '#!/bin/bash'; \
        echo; \
        echo './create_wildfly_admin.sh'; \
        echo; \
        echo 'BATCH_FILES=$(comm -23 <(ls '$ENTRY_JBOSS_BATCH' 2> /dev/null | grep -v .completed) \'; \
        echo '    <(ls '$READY_PATH' 2> /dev/null | grep .completed | sed "s/\.completed$//"))'; \
        echo; \
        echo 'echo "  $(echo $BATCH_FILES | wc -w) cli-file(s) found to execute with jboss-cli.sh"'; \
        echo; \
        echo 'if [ $(echo $BATCH_FILES | wc -w) -gt 0 ]; then'; \
        echo '    touch '$READY_PATH'/jboss_cli_block'; \
        echo '    if [ -L '$WILDFLY_HOME'/standalone/deployments ];then'; \
        echo '        rm '$WILDFLY_HOME'/standalone/deployments'; \
        echo '        mkdir '$WILDFLY_HOME'/standalone/deployments'; \
        echo '    fi'; \
        echo; \
        echo '    '$WILDFLY_HOME'/bin/standalone.sh &'; \
        echo '    until `'$JBOSS_CLI' -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running`; do sleep 1; done;'; \
        echo; \
        echo '    for BATCH_FILE in $BATCH_FILES; do'; \
        echo '        if [ -f "'$ENTRY_JBOSS_BATCH'/$BATCH_FILE" ]; then'; \
        echo '            echo "execute jboss-batchfile \"$BATCH_FILE\""'; \
        echo '            '$JBOSS_CLI' -c --file='$ENTRY_JBOSS_BATCH'/$BATCH_FILE'; \
        echo '            if [ $? -eq 0 ]; then'; \
        echo '                touch '$READY_PATH'/$BATCH_FILE.completed'; \
        echo '            else'; \
        echo '                echo "JBoss-Batchfile \"$BATCH_FILE\" can not be execute"'; \
        echo '                '$JBOSS_CLI' -c ":shutdown"'; \
        echo '                exit 99'; \
        echo '            fi'; \
        echo '        fi'; \
        echo '    done'; \
        echo; \
        echo '    '$JBOSS_CLI' -c ":shutdown"'; \
        echo '    rm -f '$WILDFLY_HOME'/standalone/configuration/standalone_xml_history/current/*'; \
        echo '    rm -rf '$WILDFLY_HOME'/standalone/deployments'; \
        echo '    ln -s '$ENTRY_DEPLOYMENTS' '$WILDFLY_HOME'/standalone/deployments'; \
        echo '    rm -f '$READY_PATH'/jboss_cli_block'; \
        echo 'fi'; \
        echo; \
        echo $WILDFLY_HOME'/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0'; \
    } > run.sh && \
	echo "14. change permission scriptes" && chmod +x wait-for-it.sh create_wildfly_admin.sh wildfly_started.sh run.sh

RUN	$WILDFLY_HOME/bin/standalone.sh & \
	until `./wildfly_started.sh`; do sleep 1; done ; \
	$JBOSS_CLI -c "module add --name=com.mysql --resources=/opt/jboss/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar --dependencies=javax.api\,javax.transaction.api" && \
	$JBOSS_CLI -c "/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql,driver-xa-datasource-class-name=com.mysql.jdbc.jdbc2.optional.MysqlXADataSource)" && \
	$JBOSS_CLI -c "module add --name=com.mariadb --resources=/opt/jboss/mariadb-java-client-${MARIADB_CONNECTOR_VERSION}.jar --dependencies=javax.api\,javax.transaction.api" && \
	$JBOSS_CLI -c "/subsystem=datasources/jdbc-driver=mariadb:add(driver-name=mariadb,driver-module-name=com.mariadb,driver-xa-datasource-class-name=com.mariadb.jdbc.MysqlDataSource)" && \
	$JBOSS_CLI -c ":shutdown" && \

	rm -rf mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar mariadb-java-client-${MARIADB_CONNECTOR_VERSION}.jar $WILDFLY_HOME/standalone/configuration/standalone_xml_history/current/*

EXPOSE 8080 9990 8443 9993

HEALTHCHECK --interval=5s --timeout=3s CMD ["./wildfly_started.sh"]

CMD ["./run.sh"]
