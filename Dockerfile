FROM jboss/wildfly:19.1.0.Final

# ###license-information-start###
# The MOSAIC-Project - WildFly with MySQL-Connector
# __
# Copyright (C) 2009 - 2020 Institute for Community Medicine
# University Medicine of Greifswald - mosaic-project@uni-greifswald.de
# __
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# ###license-information-end###

MAINTAINER Ronny Schuldt <ronny.schuldt@uni-greifswald.de>

# variables
ENV MAVEN_REPOSITORY                https://repo1.maven.org/maven2

ENV MYSQL_CONNECTOR_VERSION         8.0.20
ENV MYSQL_CONNECTOR_DOWNLOAD_URL    ${MAVEN_REPOSITORY}/mysql/mysql-connector-java/${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar
ENV MYSQL_CONNECTOR_SHA256          56a42553b516660ae0bcd08f7f4f5f375294afbd62200d6c0c88a8c61c668ede

ENV MARIADB_CONNECTOR_VERSION       2.6.0
ENV MARIADB_CONNECTOR_DOWNLOAD_URL  ${MAVEN_REPOSITORY}/org/mariadb/jdbc/mariadb-java-client/${MARIADB_CONNECTOR_VERSION}/mariadb-java-client-${MARIADB_CONNECTOR_VERSION}.jar
ENV MARIADB_CONNECTOR_SHA256        7e0882a76f59ed7dfc50b00936cc59d70148553daededad2c7f5423314e503a8

ENV ECLIPSELINK_VERSION             2.7.7
ENV ECLIPSELINK_DOWNLOAD_URL        ${MAVEN_REPOSITORY}/org/eclipse/persistence/eclipselink/${ECLIPSELINK_VERSION}/eclipselink-${ECLIPSELINK_VERSION}.jar
ENV ECLIPSELINK_PATH                modules/system/layers/base/org/eclipse/persistence/main
ENV ECLIPSELINK_SHA256              5225a9862205612c76f10259fce17241f264619fba299a5fd345cd950e038254

ENV WAIT_FOR_IT_COMMIT_HASH         ed77b63706ea721766a62ff22d3a251d8b4a6a30
ENV WAIT_FOR_IT_DOWNLOAD_URL        https://raw.githubusercontent.com/vishnubob/wait-for-it/${WAIT_FOR_IT_COMMIT_HASH}/wait-for-it.sh
ENV WAIT_FOR_IT_SHA256              2ea7475e07674e4f6c1093b4ad6b0d8cbbc6f9c65c73902fb70861aa66a6fbc0

ENV WILDFLY_HOME                    /opt/jboss/wildfly
ENV ADMIN_USER                      admin
ENV JBOSS_CLI                       ${WILDFLY_HOME}/bin/jboss-cli.sh
ENV DEBUGGING                       false

ENV ENTRY_JBOSS_BATCH               /entrypoint-jboss-batch
ENV ENTRY_DEPLOYMENTS               /entrypoint-deployments
ENV READY_PATH                      /opt/jboss/ready

# annotations
LABEL org.opencontainers.image.authors     = "university-medicine greifswald" \
      org.opencontainers.image.source      = "https://hub.docker.com/repository/docker/mosaicgreifswald/wildfly" \
      org.opencontainers.image.version     = "19.1.0.Final-20200602" \
      org.opencontainers.image.vendor      = "uni-greifswald.de" \
      org.opencontainers.image.title       = "wildfly" \
      org.opencontainers.image.license     = "AGPLv3" \
      org.opencontainers.image.description = "This is a Docker image for the Java application server WildFly. The image is based on image jboss/wildfly and prepared for the tools of the university medicine greifswald (but can also be used for other similar projects)."

# create folders and permissions
USER root
RUN echo ">  1. create folders and permissions" && \
    mkdir ${ENTRY_JBOSS_BATCH} ${READY_PATH} ${ENTRY_DEPLOYMENTS} && \
    chmod go+w ${ENTRY_JBOSS_BATCH} ${READY_PATH} ${ENTRY_DEPLOYMENTS} && \
    chown jboss:jboss ${ENTRY_JBOSS_BATCH} ${READY_PATH} ${ENTRY_DEPLOYMENTS}  && \
    \
    echo ">  2. install which" && \
    [ "$(which which 2>&1 /dev/null)" != "" ] && \
    (yum install -y --setopt=skip_missing_names_on_install=false which > install_libs.log || (>&2 cat install_libs.log && exit 1)) && \
    rm -f install_libs.log && \
    \
    echo ">  3. install mysql-connector" && \
    curl -Lso mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar ${MYSQL_CONNECTOR_DOWNLOAD_URL} && \
    (sha256sum mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar | grep ${MYSQL_CONNECTOR_SHA256} > /dev/null|| (>&2 echo "sha256sum failed $(sha256sum mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar)" && exit 1)) && \
    \
    echo ">  4. install mariadb-connector" && \
    curl -Lso mariadb-java-client-${MARIADB_CONNECTOR_VERSION}.jar ${MARIADB_CONNECTOR_DOWNLOAD_URL} && \
    (sha256sum mariadb-java-client-${MARIADB_CONNECTOR_VERSION}.jar | grep ${MARIADB_CONNECTOR_SHA256} > /dev/null|| (>&2 echo "sha256sum failed $(sha256sum mariadb-java-client-${MARIADB_CONNECTOR_VERSION}.jar)" && exit 1)) && \
    \
    echo ">  5. install wait-for-it-script" && \
    curl -Lso wait-for-it.sh ${WAIT_FOR_IT_DOWNLOAD_URL} && \
    (sha256sum wait-for-it.sh | grep ${WAIT_FOR_IT_SHA256} > /dev/null || (>&2 echo "sha256sum failed $(sha256sum wait-for-it.sh)" && exit 1)) && \
    chmod +x wait-for-it.sh && \
    \
    echo ">  6. install eclipslink" && \
    curl -Lso ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar ${ECLIPSELINK_DOWNLOAD_URL} && \
    (sha256sum ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar | grep ${ECLIPSELINK_SHA256} > /dev/null|| (>&2 echo "sha256sum failed $(sha256sum ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar)" && exit 1)) && \
    sed -i "s/<\/resources>/\n \
        <resource-root path=\"eclipselink-${ECLIPSELINK_VERSION}.jar\">\n \
            <filter>\n \
                <exclude path=\"javax\/**\" \/>\n \
            <\/filter>\n \
        <\/resource-root>\n \
    <\/resources>/" ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/module.xml && \
    chown -R jboss:jboss ${WILDFLY_HOME}/${ECLIPSELINK_PATH} && \
    \
    echo ">  7. create script create_wildfly_admin.sh" && { \
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
    echo ">  8. create script wildfly_started.sh" && { \
        echo '#!/bin/bash'; \
        echo; \
        echo '[ -f '${READY_PATH}'/jboss_cli_block ] && exit 1'; \
        echo '[[ $(curl -sI http://localhost:8080 | head -n 1) != *"200"* ]] && exit 1'; \
        echo 'exit 0'; \
    } > wildfly_started.sh && \
    chmod +x wildfly_started.sh && \
    \
    echo ">  9. create script healthcheck.sh" && { \
        echo '#!/bin/bash'; \
        echo; \
        echo '[ -f '${READY_PATH}'/jboss_cli_block ] && exit 1'; \
        echo; \
        echo '# check is wildfly running'; \
        echo './wildfly_started.sh || exit 1'; \
        echo; \
        echo '# if set HEALTHCHECK_URLS via env-variable, then check this for request-code 200'; \
        echo 'if [ ! -z "$HEALTHCHECK_URLS" ]'; \
        echo 'then'; \
        echo '    echo "using healthcheck-urls"'; \
        echo '    while read DEPLOYMENT_URL'; \
        echo '    do'; \
        echo '        [ -z ${DEPLOYMENT_URL} ] && continue'; \
        echo -e '        URL_STATE=$(curl -sI ${DEPLOYMENT_URL} | head -n 1)'; \
        echo '        if [[ $URL_STATE != *"200"* ]]'; \
        echo '        then'; \
        echo -e '            echo "url \x27${DEPLOYMENT_URL}\x27 has returned \x27${URL_STATE//[$\x27\\t\\r\\n\x27]}\x27, expected 200"'; \
        echo '            exit 1'; \
        echo '        fi'; \
        echo '    done < <(echo "$HEALTHCHECK_URLS")'; \
        echo 'fi'; \
        echo; \
        echo '# if set WILDFLY_PASS, then check deployments via managemant-tool'; \
        echo 'if [ ! -z $WILDFLY_PASS ]'; \
        echo 'then'; \
        echo '    echo "using wildfly-password"'; \
        echo '    MGNT_URL="http://${ADMIN_USER}:${WILDFLY_PASS}@localhost:9990/management"'; \
        echo -e '    DEPLOYMENTS=$(curl -sk --digest "${MGNT_URL}" | python2 -c "import sys,json; print json.load(sys.stdin)[\x27deployment\x27].keys();" 2>/dev/null)'; \
        echo -e '    DEPLOYMENTS=$(echo $DEPLOYMENTS | sed -r "s/\[?u\x27([^\x27]+)\x27(, |\])/\1\\n/g")'; \
        echo '    while read DEPLOYMENT'; \
        echo '    do'; \
        echo '        DEPLOYMENT_STATE=$(curl -sk --digest "${MGNT_URL}/deployment/${DEPLOYMENT}?operation=attribute&name=status")'; \
        echo '        if [[ $DEPLOYMENT_STATE == *"FAILED"* ]]'; \
        echo '        then'; \
        echo '            echo "deployment ${DEPLOYMENT} failed"'; \
        echo '            exit 1'; \
        echo '        fi'; \
        echo '    done < <(echo "$DEPLOYMENTS")'; \
        echo 'fi'; \
        echo; \
        echo '# if both are not set, use as fallback-variant the jboss-cli to check deployment-states'; \
        echo 'if [ -z $WILDFLY_PASS ] && [ -z "$HEALTHCHECK_URLS" ]'; \
        echo 'then'; \
        echo '    echo "using fallback-variant"'; \
        echo -e '    DEPLOYMENTS=$($JBOSS_CLI -c "deployment-info" | awk \x27{if (NR!=1) {print $1,$NF}}\x27)'; \
        echo '    while read DEPLOYMENT'; \
        echo '    do'; \
        echo -e '        if [[ $(echo $DEPLOYMENT | awk \x27{print $2}\x27) == *"FAILED"* ]]'; \
        echo '        then'; \
        echo -e '            echo "deployment $(echo $DEPLOYMENT | awk \x27{print $1}\x27) failed"'; \
        echo '            exit 1'; \
        echo '        fi'; \
        echo '    done < <(echo "$DEPLOYMENTS")'; \
        echo 'fi'; \
        echo; \
        echo 'exit 0'; \
    } >> healthcheck.sh && \
    chmod +x healthcheck.sh && \
    \
    echo "> 10. create script run.sh" && { \
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
    chmod +x run.sh && \
    \
    echo "> 11. prepare wildfly" && \
    (${WILDFLY_HOME}/bin/standalone.sh &) && \
    until `./wildfly_started.sh`; do sleep 1; done ; \
    $JBOSS_CLI -c "/subsystem=deployment-scanner/scanner=entrypoint:add(scan-interval=5000,path=${ENTRY_DEPLOYMENTS})" && \
    $JBOSS_CLI -c "module add --name=com.mysql --resources=/opt/jboss/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar --dependencies=javax.api\,javax.transaction.api" && \
    $JBOSS_CLI -c "/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql,driver-class-name=com.mysql.cj.jdbc.Driver)" && \
    $JBOSS_CLI -c "module add --name=com.mariadb --resources=/opt/jboss/mariadb-java-client-${MARIADB_CONNECTOR_VERSION}.jar --dependencies=javax.api\,javax.transaction.api" && \
    $JBOSS_CLI -c "/subsystem=datasources/jdbc-driver=mariadb:add(driver-name=mariadb,driver-module-name=com.mariadb)" && \
    $JBOSS_CLI -c ":shutdown" && \
    rm -rf mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar mariadb-java-client-${MARIADB_CONNECTOR_VERSION}.jar ${WILDFLY_HOME}/standalone/configuration/standalone_xml_history/current/* && \
    \
    echo "> 12. temporary workaround" && \
    chown jboss -R wildfly/standalone
USER jboss

# ports
EXPOSE 8080 9990 8443 9993 8787

# check if wildfly is running
HEALTHCHECK CMD ./healthcheck.sh

# run wildfly
CMD ["./run.sh"]
