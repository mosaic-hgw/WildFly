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


ENV MYSQL_CONNECTOR_VERSION			5.1.41
ENV MYSQL_CONNECTOR_DOWNLOAD_URL	http://central.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar
ENV MYSQL_CONNECTOR_SHA1			b0878056f15616989144d6114d36d3942321d0d1

ENV WAIT_FOR_IT_DOWNLOAD_URL		https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh
ENV WAIT_FOR_IT_SHA1				d6bdd6de4669d72f5a04c34063d65c33b8a5450c

ENV ECLIPSELINK_VERSION				2.6.4
ENV ECLIPSELINK_DOWNLOAD_URL		http://search.maven.org/remotecontent?filepath=org/eclipse/persistence/eclipselink/${ECLIPSELINK_VERSION}/eclipselink-${ECLIPSELINK_VERSION}.jar
ENV ECLIPSELINK_PATH				modules/system/layers/base/org/eclipse/persistence/main
ENV ECLIPSELINK_SHA1				526cc0ddb69c01784e7e9b0a048f39dc313403cb

ENV WILDFLY_HOME					/opt/jboss/wildfly
ENV ADMIN_USER						admin
ENV JBOSS_CLI						$WILDFLY_HOME/bin/jboss-cli.sh

ENV ENTRY_JBOSS_BATCH				/entrypoint-jboss-batch
ENV ENTRY_DEPLOYMENTS				/entrypoint-deployments
ENV READY_PATH						/opt/jboss/ready


USER root
RUN mkdir $ENTRY_JBOSS_BATCH $READY_PATH $ENTRY_DEPLOYMENTS && \
	chmod go+w $ENTRY_JBOSS_BATCH $READY_PATH $ENTRY_DEPLOYMENTS && \
	chown jboss:jboss $ENTRY_JBOSS_BATCH $READY_PATH $ENTRY_DEPLOYMENTS
USER jboss

# prepare WildFly
RUN curl -Lso mysql-connector-java-${MYSQL_CONNECTOR_VERSION}-bin.jar ${MYSQL_CONNECTOR_DOWNLOAD_URL} && \
	sha1sum mysql-connector-java-${MYSQL_CONNECTOR_VERSION}-bin.jar | grep ${MYSQL_CONNECTOR_SHA1} && \

	curl -Lso wait-for-it.sh ${WAIT_FOR_IT_DOWNLOAD_URL} && \
	sha1sum wait-for-it.sh | grep ${WAIT_FOR_IT_SHA1} && \

	curl -Lso ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar ${ECLIPSELINK_DOWNLOAD_URL} && \
	sha1sum ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar | grep ${ECLIPSELINK_SHA1} && \
	sed -i "s/<\/resources>/\n \
		<resource-root path=\"eclipselink-$ECLIPSELINK_VERSION.jar\">\n \
		    <filter>\n \
		        <exclude path=\"javax\/**\" \/>\n \
		    <\/filter>\n \
		<\/resource-root>\n \
	<\/resources>/" ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/module.xml && \
	chown -R jboss:jboss ${WILDFLY_HOME}/${ECLIPSELINK_PATH} && \

    { \
        echo '#!/bin/bash'; \
        echo; \
        echo 'if [ ! -f "'$READY_PATH'/admin.created" ]; then'; \
        echo '    echo "========================================================================="'; \
        echo '    if [ -z "$NO_ADMIN" ]; then'; \
        echo '        WILDFLY_PASS=${WILDFLY_PASS:-$(tr -cd "[:alnum:]-_!#%&/<({[|]})>+*,.;$" < /dev/urandom | head -c30)}'; \
        echo '        '$WILDFLY_HOME'/bin/add-user.sh -s -a '$ADMIN_USER' $WILDFLY_PASS && \'; \
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

    { \
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
        echo; \
        echo '    rm -rf '$WILDFLY_HOME'/standalone/deployments'; \
        echo '    ln -s '$ENTRY_DEPLOYMENTS' '$WILDFLY_HOME'/standalone/deployments'; \
        echo 'fi'; \
        echo; \
        echo $WILDFLY_HOME'/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0'; \
    } > run.sh && \
	chmod +x wait-for-it.sh create_wildfly_admin.sh run.sh && \

	$WILDFLY_HOME/bin/standalone.sh & \
	until `$JBOSS_CLI -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running`; do sleep 1; done ; \
	$JBOSS_CLI -c "module add --name=com.mysql --resources=/opt/jboss/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}-bin.jar --dependencies=javax.api\,javax.transaction.api" && \
	$JBOSS_CLI -c "/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql,driver-xa-datasource-class-name=com.mysql.jdbc.jdbc2.optional.MysqlXADataSource)" && \
	$JBOSS_CLI -c ":shutdown" && \

	rm -rf mysql-connector-java-${MYSQL_CONNECTOR_VERSION}-bin.jar $WILDFLY_HOME/standalone/configuration/standalone_xml_history/current/*

EXPOSE 8080 9990 8443 9993

HEALTHCHECK --interval=5s --timeout=3s CMD $JBOSS_CLI -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running && exit 0 || exit 1

CMD ["./run.sh"]
