FROM alpine:3.12

# ###license-information-start###
# The MOSAIC-Project - WildFly with MySQL-Connector and Healthcheck
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
# along with this program. If not, see <http://www.gnu.org/licenses/>.
# ###license-information-end###

MAINTAINER Ronny Schuldt <ronny.schuldt@uni-greifswald.de>

# variables
ENV MAVEN_REPOSITORY                https://repo1.maven.org/maven2

ENV WILDFLY_VERSION                 20.0.1.Final
ENV WILDFLY_DOWNLOAD_URL            https://download.jboss.org/wildfly/${WILDFLY_VERSION}/wildfly-${WILDFLY_VERSION}.tar.gz
ENV WILDFLY_SHA256                  63ced690c05149f444e8d0418c1d76ab82941d1e3763ef4c49b0c43de5f95ae7

ENV MYSQL_CONNECTOR_VERSION         8.0.21
ENV MYSQL_CONNECTOR_DOWNLOAD_URL    ${MAVEN_REPOSITORY}/mysql/mysql-connector-java/${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar
ENV MYSQL_CONNECTOR_SHA256          2f62d886270a75ebc8e8fd89127d4a30ccc711f02256ade2cfb7090817132003

ENV ECLIPSELINK_VERSION             2.7.7
ENV ECLIPSELINK_DOWNLOAD_URL        ${MAVEN_REPOSITORY}/org/eclipse/persistence/eclipselink/${ECLIPSELINK_VERSION}/eclipselink-${ECLIPSELINK_VERSION}.jar
ENV ECLIPSELINK_PATH                modules/system/layers/base/org/eclipse/persistence/main
ENV ECLIPSELINK_SHA256              5225a9862205612c76f10259fce17241f264619fba299a5fd345cd950e038254

ENV WAIT_FOR_IT_COMMIT_HASH         ed77b63706ea721766a62ff22d3a251d8b4a6a30
ENV WAIT_FOR_IT_DOWNLOAD_URL        https://raw.githubusercontent.com/vishnubob/wait-for-it/${WAIT_FOR_IT_COMMIT_HASH}/wait-for-it.sh
ENV WAIT_FOR_IT_SHA256              2ea7475e07674e4f6c1093b4ad6b0d8cbbc6f9c65c73902fb70861aa66a6fbc0

ENV JAVA_VERSION                    11
ENV JAVA_HOME                       /usr/lib/jvm/default-jvm/

ENV HOME                            /opt/jboss
ENV WILDFLY_HOME                    /opt/jboss/wildfly
ENV ADMIN_USER                      admin
ENV JBOSS_CLI                       ${WILDFLY_HOME}/bin/jboss-cli.sh
ENV READY_PATH                      /opt/jboss/ready
ENV DEBUGGING                       false
ENV LAUNCH_JBOSS_IN_BACKGROUND      true

ENV ENTRY_JBOSS_BATCH               /entrypoint-jboss-batch
ENV ENTRY_DEPLOYMENTS               /entrypoint-deployments

# annotations
LABEL org.opencontainers.image.authors     = "university-medicine greifswald" \
      org.opencontainers.image.source      = "https://hub.docker.com/repository/docker/mosaicgreifswald/wildfly" \
      org.opencontainers.image.version     = "20.0.1.Final-20201008" \
      org.opencontainers.image.vendor      = "uni-greifswald.de" \
      org.opencontainers.image.title       = "wildfly" \
      org.opencontainers.image.license     = "AGPLv3" \
      org.opencontainers.image.description = "This is a Docker image for the Java application server WildFly. The image is based on image jboss/wildfly and prepared for the tools of the university medicine greifswald (but can also be used for other similar projects)."

# create folders and permissions
RUN echo && echo && \
	echo "===========================================================" && \
	echo && \
	echo "  Create new image by Dockerfile (using $(basename $0))" && \
	echo "  |" && \
	echo "  |____ 1. install missing packages (curl, bash, openjdk)" && \
	(apk add --quiet --no-cache curl bash openjdk${JAVA_VERSION}-jre --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community &> install.log || (>&2 cat install.log && echo && exit 1)) && \
	\
	echo "  |____ 2. create user and group" && \
	addgroup -g 1000 -S jboss && adduser -u 1000 -G jboss -h ${HOME} -S jboss && chmod 755 ${HOME} && \
	\
	echo "  |____ 3. create folders and permissions" && \
    mkdir ${ENTRY_JBOSS_BATCH} ${READY_PATH} ${ENTRY_DEPLOYMENTS} && \
    chmod go+w ${ENTRY_JBOSS_BATCH} ${READY_PATH} ${ENTRY_DEPLOYMENTS} && \
    chown jboss:jboss ${ENTRY_JBOSS_BATCH} ${READY_PATH} ${ENTRY_DEPLOYMENTS} && \ 
	\
	echo "  |____ 4. install wildfly" && \
	cd ${HOME} && \
	echo "  |  |____ 1. download" && \
	(curl -Lso wildfly.tar.gz https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz || (>&2 echo -e "\ncannot download\n" && exit 1)) && \
	echo "  |  |____ 2. check checksum" && \
	(sha256sum wildfly.tar.gz | grep -q ${WILDFLY_SHA256} > /dev/null|| (>&2 echo "sha256sum failed $(sha256sum wildfly.tar.gz)" && exit 1)) && \
    echo "  |  |____ 3. extract" && \
	tar xf wildfly.tar.gz && \
	echo "  |  |____ 4. move" && \
	mv wildfly-$WILDFLY_VERSION $WILDFLY_HOME && \
	echo "  |  |____ 5. create server.log" && \
	mkdir $WILDFLY_HOME/standalone/log && touch $WILDFLY_HOME/standalone/log/server.log && \
	echo "  |  |____ 6. set permissions" && \
	chown -R jboss:jboss ${WILDFLY_HOME} && chmod -R g+rw ${WILDFLY_HOME} && \
	\
	echo "  |____ 5. download additional components" && \
	echo "  |  |____ 1. download mysql-connector" && \
    curl -Lso mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar ${MYSQL_CONNECTOR_DOWNLOAD_URL} && \
    (sha256sum mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar | grep -q ${MYSQL_CONNECTOR_SHA256} > /dev/null|| (>&2 echo "sha256sum failed $(sha256sum mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar)" && exit 1)) && \
	\
    echo "  |  |____ 2. download/install eclipslink" && \
    curl -Lso ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar ${ECLIPSELINK_DOWNLOAD_URL} && \
    (sha256sum ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar | grep -q ${ECLIPSELINK_SHA256} > /dev/null|| (>&2 echo "sha256sum failed $(sha256sum ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar)" && exit 1)) && \
    sed -i "s/<\/resources>/\n \
        <resource-root path=\"eclipselink-${ECLIPSELINK_VERSION}.jar\">\n \
            <filter>\n \
                <exclude path=\"javax\/**\" \/>\n \
            <\/filter>\n \
        <\/resource-root>\n \
    <\/resources>/" ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/module.xml && \
    chown -R jboss:jboss ${WILDFLY_HOME}/${ECLIPSELINK_PATH} && \
	\
    echo "  |  |____ 3. download wait-for-it-script" && \
    curl -Lso wait-for-it.sh ${WAIT_FOR_IT_DOWNLOAD_URL} && \
    (sha256sum wait-for-it.sh | grep -q ${WAIT_FOR_IT_SHA256} > /dev/null || (>&2 echo "sha256sum failed $(sha256sum wait-for-it.sh)" && exit 1)) && \
    chmod +x wait-for-it.sh && \
	\
	echo "  |____ 6. create bash-scripts" && \
    echo "  |  |____ 1. create_wildfly_admin.sh" && { \
        echo '#!/bin/bash'; \
        echo; \
        echo 'if [ ! -f "'${READY_PATH}'/admin.created" ]; then'; \
        echo '    echo "========================================================================="'; \
        echo '    echo'; \
        echo '    if [ -z "${NO_ADMIN}" ]; then'; \
        echo '        WILDFLY_PASS=${WILDFLY_PASS:-$(tr -cd "[:alnum:]" < /dev/urandom | head -c20)}'; \
        echo '        ('${WILDFLY_HOME}'/bin/add-user.sh '${ADMIN_USER}' ${WILDFLY_PASS} > create_admin.log && \'; \
        echo '        echo -e "\033[1;37m  You can configure this WildFly-Server using:\033[0m" && \'; \
        echo '        echo -e "\033[1;37m  '${ADMIN_USER}':${WILDFLY_PASS}\033[0m") || \'; \
        echo '        cat create_admin.log'; \
        echo '    else'; \
        echo '        echo "  You can NOT configure this WildFly-Server" && \'; \
        echo '        echo "  because no admin-user was created."'; \
        echo '    fi'; \
        echo '    echo'; \
        echo '    touch '${READY_PATH}'/admin.created'; \
        echo 'fi'; \
    } > create_wildfly_admin.sh && \
    chmod +x create_wildfly_admin.sh && \
	\
    echo "  |  |____ 2. wildfly_started.sh" && { \
        echo '#!/bin/bash'; \
        echo; \
        echo '[ -f '${READY_PATH}'/jboss_cli_block ] && exit 1'; \
        echo '[[ $(curl -sI http://localhost:8080 | head -n 1) != *"200"* ]] && exit 1'; \
        echo 'exit 0'; \
    } > wildfly_started.sh && \
    chmod +x wildfly_started.sh && \
	\
    echo "  |  |____ 3. healthcheck.sh" && { \
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
    echo "  |  |____ 4. add_jboss_cli.sh" && { \
        echo '#!/bin/bash'; \
        echo; \
        echo 'echo "========================================================================="'; \
        echo; \
        echo 'if [ "$SWITCH_ON_CLI" ]; then'; \
        echo '    CLI_FILTER="(\.cli|\.${SWITCH_ON_CLI/[, |]+/|\\.})"'; \
        echo 'else'; \
        echo '    CLI_FILTER="\.cli"'; \
        echo 'fi'; \
        echo; \
        echo 'BATCH_FILES=$(comm -23 <(ls '${ENTRY_JBOSS_BATCH}' 2> /dev/null | grep -E "$CLI_FILTER$" | grep -v .completed) \'; \
        echo '    <(ls '${READY_PATH}' 2> /dev/null | grep .completed | sed "s/\.completed$//"))'; \
        echo; \
        echo 'echo "  $(echo ${BATCH_FILES} | wc -w) cli-file(s) found to execute with jboss-cli.sh"'; \
        echo 'echo "  filter: ${CLI_FILTER}"'; \
        echo 'echo "${BATCH_FILES}"'; \
        echo 'echo'; \
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
    } > add_jboss_cli.sh && \
    chmod +x add_jboss_cli.sh && \
    \
    echo "  |  |____ 5. run.sh" && { \
        echo '#!/bin/bash'; \
        echo; \
		echo 'echo "========================================================================="'; \
        echo 'cat versions'; \
        echo; \
        echo './create_wildfly_admin.sh'; \
        echo; \
        echo './add_jboss_cli.sh'; \
        echo; \
        echo ${WILDFLY_HOME}'/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0 $([ "${DEBUGGING}" == "true" ] && echo "--debug")'; \
    } > run.sh && \
    chmod +x run.sh && \
    \
    echo "  |____ 7. prepare wildfly" && \
	echo -n "  |  |____ 1. start app-server" && \
	(${WILDFLY_HOME}/bin/standalone.sh > install.log &) && \
	STARTTIME=$(date +%s) && \
	TIMEOUT=30 && \
	(until `./wildfly_started.sh`;do sleep 1;echo -n '.';if [ $(($(date +%s)-STARTTIME)) -ge $TIMEOUT ];then echo;cat install.log;echo;exit 1;fi;done;echo -e "\r  |  |____ 1. start app-server$(printf '%0.s ' {1..30})") && \
	ENDTIME=$(date +%s) && \
	echo "  |  |____ 2. install mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar" && \
	($JBOSS_CLI -c "module add --name=com.mysql --resources=/opt/jboss/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar --dependencies=javax.api\,javax.transaction.api" > install.log || (>&2 cat install.log && exit 1)) && \
	echo "  |  |____ 3. add datasource-driver for mysql" && \
	($JBOSS_CLI -c "/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql,driver-class-name=com.mysql.cj.jdbc.Driver)" > install.log || (>&2 cat install.log && exit 1)) && \
	echo "  |  |____ 4. add deployment-scanner" && \
    ($JBOSS_CLI -c "/subsystem=deployment-scanner/scanner=entrypoint:add(scan-interval=5000,path=${ENTRY_DEPLOYMENTS})" > install.log || (>&2 cat install.log && exit 1)) && \
	echo "  |  |____ 5. shutdown app-server" && \
	($JBOSS_CLI -c ":shutdown" > install.log || (>&2 cat install.log && exit 1)) && \
	\
	echo "  |____ 8. cleanup" && \
	rm -rf \
		wildfly.tar.gz \
		install.log \
		mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar \
		${WILDFLY_HOME}/standalone/configuration/standalone_xml_history/current/* && \
    chown jboss -R wildfly/standalone && \
    \
    echo "  |____ 9. create and show textfile 'versions'" && \
	{ \
		echo ;\
		echo "  Distribution            : $(cat /etc/os-release | grep 'PRETTY_NAME' | cut -d'"' -f2)"; \
		echo "  Java                    : $(java -version 2>&1 | head -n1 | sed -r 's/^.+"(.+)".+$/\1/' | cat)"; \
		echo "  WildFly                 : $(${WILDFLY_HOME}/bin/standalone.sh -version --admin-only | grep WildFly | sed -r 's/^[^(]+ ([0-9\.]+Final).+$/\1/' | cat)"; \
		echo "  MySQL-Connector         : ${MYSQL_CONNECTOR_VERSION}"; \
		echo "  EclipseLink             : $(ls ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-* | sed -r 's/^.+-([0-9\.]+)\.jar$/\1/' | cat)"; \
		echo ;\
	} > versions && \
	echo && \
	echo "===========================================================" && \
	cat versions && \
	echo "===========================================================" && \
	echo && \
	echo "  WildFly HDD-Space       : $(du -sh ${WILDFLY_HOME} | cut -f1)" && \
	echo "  WildFly Start-Time      : $((ENDTIME-STARTTIME)) seconds" && \
	echo && \
	echo "===========================================================" && \
	echo

WORKDIR ${HOME}
USER jboss

# ports
EXPOSE 8080 9990 8443 9993 8787

# check if wildfly is running
HEALTHCHECK CMD ./healthcheck.sh

# run wildfly
SHELL ["/bin/bash", "-c"]
CMD ["./run.sh"]
