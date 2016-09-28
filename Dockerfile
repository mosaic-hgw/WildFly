FROM jboss/wildfly:10.1.0.Final

# ###license-information-start###
# MOSAIC - WildFly with MySQL-Connector
# __
# Copyright (C) 2009 - 2016 MOSAIC - Institute for Community Medicine
# University Medicine of Greifswald - mosaic@uni-greifswald.de
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


ENV MYSQL_CONNECTOR_VERSION	5.1.39
ENV MYSQL_CONNECTOR_SHA1	4617fe8dc8f1969ec450984b0b9203bc8b7c8ad5
ENV WAIT_FOR_IT_SHA1		d6bdd6de4669d72f5a04c34063d65c33b8a5450c
ENV WILDFLY_HOME			/opt/jboss/wildfly
ENV JBOSS_CLI				$WILDFLY_HOME/bin/jboss-cli.sh

ENV ENTRY_JBOSS_BATCH		/entrypoint-jboss-batch
ENV ENTRY_DEPLOYMENTS		/entrypoint-deployments


USER root
RUN mkdir $ENTRY_JBOSS_BATCH $ENTRY_DEPLOYMENTS && \
	chmod go+w $ENTRY_JBOSS_BATCH $ENTRY_DEPLOYMENTS && \
	chown jboss:jboss $ENTRY_JBOSS_BATCH $ENTRY_DEPLOYMENTS
USER jboss

# prepare WildFly
RUN curl -so mysql-connector-java-${MYSQL_CONNECTOR_VERSION}-bin.jar http://central.maven.org/maven2/mysql/mysql-connector-java/$MYSQL_CONNECTOR_VERSION/mysql-connector-java-$MYSQL_CONNECTOR_VERSION.jar && \
	sha1sum mysql-connector-java-${MYSQL_CONNECTOR_VERSION}-bin.jar | grep $MYSQL_CONNECTOR_SHA1 && \
	curl -so wait-for-it.sh https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh && \
	sha1sum wait-for-it.sh | grep $WAIT_FOR_IT_SHA1 && \

	{ \
        echo '#!/bin/bash'; \
        echo; \
        echo 'BATCH_FILES=$(comm -23 <(ls -d '$ENTRY_JBOSS_BATCH'/* | grep -v .completed) \'; \
        echo '    <(ls -d '$ENTRY_JBOSS_BATCH'/* | grep .completed | sed "s/\.completed$//"))'; \
        echo; \
        echo 'if [ $(echo $BATCH_FILES | wc -w) -gt 0 ]; then'; \
        echo '    if [ -L '$WILDFLY_HOME'/standalone/deployments ];then'; \
        echo '        rm '$WILDFLY_HOME'/standalone/deployments'; \
        echo '        mkdir '$WILDFLY_HOME'/standalone/deployments'; \
        echo '    fi'; \
        echo; \
        echo '    '$WILDFLY_HOME'/bin/standalone.sh &'; \
        echo '    until `'$JBOSS_CLI' -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running`; do sleep 1; done;'; \
        echo; \
        echo '    for BATCH_FILE in $BATCH_FILES; do'; \
        echo '        if [ -f "$BATCH_FILE" ]; then'; \
        echo '            echo "execute jboss-batchfile \"$BATCH_FILE\""'; \
        echo '            '$JBOSS_CLI' -c --file=$BATCH_FILE'; \
        echo '            if [ $? -eq 0 ]; then'; \
        echo '                touch $BATCH_FILE.completed'; \
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
        echo; \
        echo '    rm -rf '$WILDFLY_HOME'/standalone/deployments'; \
        echo '    ln -s '$ENTRY_DEPLOYMENTS' '$WILDFLY_HOME'/standalone/deployments'; \
        echo 'fi'; \
        echo; \
        echo $WILDFLY_HOME'/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0'; \
    } > run.sh && \
	chmod +x wait-for-it.sh run.sh && \

	$WILDFLY_HOME/bin/standalone.sh & \
	until `$JBOSS_CLI -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running`; do sleep 1; done ; \
	$JBOSS_CLI -c "module add --name=com.mysql --resources=/opt/jboss/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}-bin.jar --dependencies=javax.api\,javax.transaction.api" && \
	$JBOSS_CLI -c "/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql,driver-xa-datasource-class-name=com.mysql.jdbc.jdbc2.optional.MysqlXADataSource)" && \
	$JBOSS_CLI -c ":shutdown" && \

	rm -rf mysql-connector-java-${MYSQL_CONNECTOR_VERSION}-bin.jar $WILDFLY_HOME/standalone/configuration/standalone_xml_history/current/*

EXPOSE 8080 9990 8443 9993

CMD ["./run.sh"]
