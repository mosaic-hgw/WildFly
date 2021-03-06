FROM debian:10.9-slim

# ###license-information-start###
# The MOSAIC-Project - WildFly with MySQL-Connector and Healthcheck
# __
# Copyright (C) 2009 - 2021 Institute for Community Medicine
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

ENV WILDFLY_VERSION                 23.0.2.Final
ENV WILDFLY_DOWNLOAD_URL            https://download.jboss.org/wildfly/${WILDFLY_VERSION}/wildfly-${WILDFLY_VERSION}.tar.gz
ENV WILDFLY_SHA256                  6525f6372a8dbddb84d7e3a466dbef1e046253c2bcd682c29fd0f4c1ec606fc4

ENV MYSQL_CONNECTOR_VERSION         8.0.25
ENV MYSQL_CONNECTOR_DOWNLOAD_URL    ${MAVEN_REPOSITORY}/mysql/mysql-connector-java/${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar
ENV MYSQL_CONNECTOR_SHA256          a0a1be0389e541dad8841b326e79c51d39abbe1ca52267304d76d1cf4801ce96

ENV ECLIPSELINK_VERSION             2.7.8
ENV ECLIPSELINK_DOWNLOAD_URL        ${MAVEN_REPOSITORY}/org/eclipse/persistence/eclipselink/${ECLIPSELINK_VERSION}/eclipselink-${ECLIPSELINK_VERSION}.jar
ENV ECLIPSELINK_PATH                modules/system/layers/base/org/eclipse/persistence/main
ENV ECLIPSELINK_SHA256              4f0cf067c9e9fd28f600f4e0c2b97fa976a6d3ee1548e931be81751aecafc243

ENV WAIT_FOR_IT_COMMIT_HASH         ed77b63706ea721766a62ff22d3a251d8b4a6a30
ENV WAIT_FOR_IT_DOWNLOAD_URL        https://raw.githubusercontent.com/vishnubob/wait-for-it/${WAIT_FOR_IT_COMMIT_HASH}/wait-for-it.sh
ENV WAIT_FOR_IT_SHA256              2ea7475e07674e4f6c1093b4ad6b0d8cbbc6f9c65c73902fb70861aa66a6fbc0

ENV KEYCLOAK_VERSION                13.0.1
ENV KEYCLOAK_DOWNLOAD_URL           https://github.com/keycloak/keycloak/releases/download/${KEYCLOAK_VERSION}/keycloak-oidc-wildfly-adapter-${KEYCLOAK_VERSION}.tar.gz
ENV KEYCLOAK_SHA256                 7ee9c306aac23929c28e6e939881f9e4d3ffed5efca38807036c32426e9127a5

ENV JAVA_VERSION                    11

ENV USER                            mosaic
ENV HOME                            /opt/${USER}
ENV WILDFLY_HOME                    ${HOME}/wildfly
ENV ADMIN_USER                      admin
ENV JBOSS_CLI                       ${WILDFLY_HOME}/bin/jboss-cli.sh
ENV READY_PATH                      ${HOME}/ready
ENV DEBUGGING                       false
ENV LAUNCH_JBOSS_IN_BACKGROUND      true
ENV TEMP_PATH						/opt/temp

ENV ENTRY_WILDFLY_CLI               /entrypoint-wildfly-cli
ENV ENTRY_WILDFLY_DEPLOYS           /entrypoint-wildfly-deployments
ENV ENTRY_WILDFLY_LOGS				/entrypoint-wildfly-logs

# annotations
LABEL maintainer                           = "ronny.schuldt@uni-greifswald.de" \
      org.opencontainers.image.authors     = "university-medicine greifswald" \
      org.opencontainers.image.source      = "https://hub.docker.com/repository/docker/mosaicgreifswald/wildfly" \
      org.opencontainers.image.version     = "23.0.2.Final-20210603" \
      org.opencontainers.image.vendor      = "uni-greifswald.de" \
      org.opencontainers.image.title       = "mosaic-wildfly" \
      org.opencontainers.image.license     = "AGPLv3" \
      org.opencontainers.image.description = "This is a Docker image for the Java application server WildFly. The image is based on slim debian-image and prepared for the tools of the university medicine greifswald (but can also be used for other similar projects)."

# create folders and permissions
RUN echo && echo && \
	echo "===========================================================" && \
	echo && \
	echo "  Create new image by Dockerfile (using $(basename $0))" && \
	echo "  |" && \
	echo "  |____ 1. install system-updates" && \
	(apt-get update > install.log 2>&1 || (>&2 cat install.log && echo && exit 1)) && \
	(apt-get upgrade -qqy > install.log 2>&1 || (>&2 cat install.log && echo && exit 1)) && \
    \
	echo "  |____ 2. create user and group" && \
	groupadd --g 1000 ${USER} && \
	useradd -m -u 1000 -g 1000 -d ${HOME} ${USER} && \
	chmod 755 ${HOME} && \
    \
	echo "  |____ 3. create folders and permissions" && \
    mkdir ${ENTRY_WILDFLY_CLI} ${READY_PATH} ${ENTRY_WILDFLY_DEPLOYS} ${TEMP_PATH} && \
    chmod go+w ${ENTRY_WILDFLY_CLI} ${READY_PATH} ${ENTRY_WILDFLY_DEPLOYS} && \
    chown ${USER}:${USER} ${ENTRY_WILDFLY_CLI} ${READY_PATH} ${ENTRY_WILDFLY_DEPLOYS} && \
	\
	echo "  |____ 4. install missing packages (curl, gnupg, jre)" && \
	cd ${TEMP_PATH}/ && \
	(( \
	    apt-get install -y gnupg curl && \
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9 && \
        curl -Lso zulu-repo_1.0.0-2_all.deb https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-2_all.deb && \
        apt-get install -y ./zulu-repo_1.0.0-2_all.deb && \
        apt-get update && \
        apt-get install -y zulu${JAVA_VERSION}-jre \
    ) > install.log 2>&1 || (>&2 cat install.log && echo && exit 1)) && \
	\
	echo "  |____ 5. install wildfly" && \
	echo -n "  |  |____ 1. download " && \
	(curl -Lso wildfly.tar.gz ${WILDFLY_DOWNLOAD_URL} || (>&2 echo -e "\ncannot download\n" && exit 1))  && \
	echo "($(du -h wildfly.tar.gz | cut -f1))" && \
	echo "  |  |____ 2. check checksum" && \
	(sha256sum wildfly.tar.gz | grep -q ${WILDFLY_SHA256} > /dev/null|| (>&2 echo "sha256sum failed $(sha256sum wildfly.tar.gz)" && exit 1)) && \
    echo -n "  |  |____ 3. extract " && \
    tar xf wildfly.tar.gz && \
	echo "($(du -sh wildfly-${WILDFLY_VERSION} | cut -f1))" && \
	echo "  |  |____ 4. move" && \
	mv wildfly-${WILDFLY_VERSION} ${WILDFLY_HOME} && \
	echo "  |  |____ 5. create server.log" && \
	mkdir ${WILDFLY_HOME}/standalone/log && touch ${WILDFLY_HOME}/standalone/log/server.log && \
	echo "  |  |____ 6. set permissions" && \
	chown -R ${USER}:${USER} ${WILDFLY_HOME} && chmod -R g+rw ${WILDFLY_HOME} && \
	\
	echo "  |____ 6. download additional components" && \
	echo "  |  |____ 1. download mysql-connector" && \
    (curl -Lso mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar ${MYSQL_CONNECTOR_DOWNLOAD_URL} || (>&2 echo -e "\ncannot download\n" && exit 1))  && \
    (sha256sum mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar | grep -q ${MYSQL_CONNECTOR_SHA256} > /dev/null|| (>&2 echo "sha256sum failed $(sha256sum mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar)" && exit 1)) && \
	\
    echo "  |  |____ 2. download/install eclipslink" && \
    (curl -Lso ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar ${ECLIPSELINK_DOWNLOAD_URL} || (>&2 echo -e "\ncannot download\n" && exit 1))  && \
    (sha256sum ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar | grep -q ${ECLIPSELINK_SHA256} > /dev/null|| (>&2 echo "sha256sum failed $(sha256sum ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar)" && exit 1)) && \
    sed -i "s/<\/resources>/\n \
        <resource-root path=\"eclipselink-${ECLIPSELINK_VERSION}.jar\">\n \
            <filter>\n \
                <exclude path=\"javax\/**\" \/>\n \
            <\/filter>\n \
        <\/resource-root>\n \
    <\/resources>/" ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/module.xml && \
    chown -R ${USER}:${USER} ${WILDFLY_HOME}/${ECLIPSELINK_PATH} && \
	\
    echo "  |  |____ 3. download wait-for-it-script" && \
    (curl -Lso ${HOME}/wait-for-it.sh ${WAIT_FOR_IT_DOWNLOAD_URL} || (>&2 echo -e "\ncannot download\n" && exit 1))  && \
    (sha256sum ${HOME}/wait-for-it.sh | grep -q ${WAIT_FOR_IT_SHA256} > /dev/null || (>&2 echo "sha256sum failed $(sha256sum ${HOME}/wait-for-it.sh)" && exit 1)) && \
    chmod +x ${HOME}/wait-for-it.sh && \
	\
	echo "  |____ 7. install keycloack-client" && \
    echo "  |  |____ 1. download" && \
	(curl -Lso keycloak.tar.gz ${KEYCLOAK_DOWNLOAD_URL} || (>&2 echo -e "\ncannot download\n" && exit 1))  && \
	echo "  |  |____ 2. check checksum" && \
	(sha256sum keycloak.tar.gz | grep -q ${KEYCLOAK_SHA256} > /dev/null|| (>&2 echo "sha256sum failed $(sha256sum keycloak.tar.gz)" && exit 1)) && \
    echo "  |  |____ 3. extract" && \
	tar -xf keycloak.tar.gz -C ${WILDFLY_HOME} && \
	echo "  |  |____ 4. install" && \
    ($JBOSS_CLI --file=${WILDFLY_HOME}/bin/adapter-install-offline.cli > install.log 2>&1 || (>&2 cat install.log && exit 1)) && \
	\
	echo "  |____ 8. create bash-scripts" && \
	cd ${HOME} && { \
        echo '#!/bin/bash'; \
        echo; \
        echo 'if [ ! -f "'${READY_PATH}'/admin.created" ]; then'; \
        echo '    echo "========================================================================="'; \
        echo '    echo'; \
        echo '    if [ -z "${NO_ADMIN}" ]; then'; \
        echo '        echo -e "\033[1;37m  You can configure this WildFly-Server using:\033[0m"'; \
        echo '        echo -e "\033[1;37m    Username: '${ADMIN_USER}'\033[0m"'; \
        echo '        if [ -z "${WILDFLY_PASS}" ]; then'; \
        echo '            WILDFLY_PASS=$(tr -cd "[:alnum:]" < /dev/urandom | head -c20)'; \
        echo '            echo -e "\033[1;37m    Password: ${WILDFLY_PASS}\033[0m"'; \
        echo '            echo -e "\033[1;37m  The password is displayed here only this once.\033[0m"'; \
        echo '        else'; \
        echo '            echo -e "\033[1;37m    Password: ***known***\033[0m"'; \
        echo '        fi'; \
        echo '        '${WILDFLY_HOME}'/bin/add-user.sh '${ADMIN_USER}' ${WILDFLY_PASS} > create_admin.log'; \
        echo '        cat create_admin.log'; \
        echo '    else'; \
        echo '        echo "  You can NOT configure this WildFly-Server"'; \
        echo '        echo "  because no admin-user was created."'; \
        echo '    fi'; \
        echo '    echo'; \
        echo '    touch '${READY_PATH}'/admin.created'; \
        echo 'fi'; \
    } > create_wildfly_admin.sh && \
	\
    { \
        echo '#!/bin/bash'; \
        echo; \
        echo '[ -f '${READY_PATH}'/jboss_cli_block ] && exit 1'; \
        echo '[[ $(curl -sI http://localhost:8080 | head -n 1) != *"200"* ]] && exit 1'; \
        echo 'exit 0'; \
    } > wildfly_started.sh && \
    chmod u+x wildfly_started.sh && \
	\
    { \
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
        echo -e '        URL_STATE=$(curl -sNIX GET ${DEPLOYMENT_URL} | head -n 1)'; \
        echo '        echo " > ${DEPLOYMENT_URL}: ${URL_STATE}"'; \
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
        echo -e '    DEPLOYMENTS=$(curl -sk --digest "${MGNT_URL}" | grep -oE \x27"deployment" ?: ?(null|\{[^}]*\}),\x27 | sed -r \x27s/([": \{\}]|deployment|null)//g;s/,/\\n/g;s/\\n$//\x27)'; \
        echo '    while read DEPLOYMENT'; \
        echo '    do'; \
        echo '        DEPLOYMENT_STATE=$(curl -sk --digest "${MGNT_URL}/deployment/${DEPLOYMENT}?operation=attribute&name=status")'; \
        echo '        echo " > ${DEPLOYMENT}: ${DEPLOYMENT_STATE}"'; \
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
        echo -e '        DEPLOYMENT_NAME=$(echo $DEPLOYMENT | awk \x27{print $1}\x27)'; \
        echo -e '        DEPLOYMENT_STATE=$(echo $DEPLOYMENT | awk \x27{print $2}\x27)'; \
        echo '        echo " > ${DEPLOYMENT_NAME}: ${DEPLOYMENT_STATE}"'; \
        echo '        if [[ ${DEPLOYMENT_STATE} == *"FAILED"* ]]'; \
        echo '        then'; \
        echo '            echo "deployment ${DEPLOYMENT_NAME} failed"'; \
        echo '            exit 1'; \
        echo '        fi'; \
        echo '    done < <(echo "$DEPLOYMENTS")'; \
        echo 'fi'; \
        echo; \
        echo 'exit 0'; \
    } >> healthcheck.sh && \
    \
    { \
        echo '#!/bin/bash'; \
        echo; \
        echo 'echo "========================================================================="'; \
        echo; \
        echo 'if [ "$ADD_CLI_FILTER" ]; then'; \
        echo '    CLI_FILTER="(\.cli|\.${ADD_CLI_FILTER/[, |]+/|\\.})"'; \
        echo 'else'; \
        echo '    CLI_FILTER="\.cli"'; \
        echo 'fi'; \
        echo; \
        echo 'BATCH_FILES=$(comm -23 <(ls '${ENTRY_WILDFLY_CLI}' 2> /dev/null | grep -E "$CLI_FILTER$" | grep -v .completed) \\'; \
        echo '    <(ls '${READY_PATH}' 2> /dev/null | grep .completed | sed "s/\.completed$//"))'; \
        echo; \
        echo 'echo "  $(echo ${BATCH_FILES} | wc -w) cli-file(s) found to execute with jboss-cli.sh"'; \
        echo 'echo "  filter: ${CLI_FILTER}"'; \
        echo 'echo "${BATCH_FILES}"'; \
        echo 'echo'; \
        echo; \
        echo 'if [ $(echo ${BATCH_FILES} | wc -w) -gt 0 ]; then'; \
        echo '    env > env.properties'; \
        echo '    touch '${READY_PATH}'/jboss_cli_block'; \
        echo; \
        echo '    '${WILDFLY_HOME}'/bin/standalone.sh --admin-only &'; \
        echo '    until `'${JBOSS_CLI}' -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running`; do sleep 1; done;'; \
        echo; \
        echo '    for BATCH_FILE in ${BATCH_FILES}; do'; \
        echo '        if [ -f "'${ENTRY_WILDFLY_CLI}'/${BATCH_FILE}" ]; then'; \
        echo '            echo "execute jboss-batchfile \"${BATCH_FILE}\""'; \
        echo '            '${JBOSS_CLI}' -c --properties=env.properties --file='${ENTRY_WILDFLY_CLI}'/${BATCH_FILE}'; \
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
        echo 'rm -f '${READY_PATH}'/jboss_cli_block env.properties'; \
    } > add_jboss_cli.sh && \
    \
    { \
        echo '#!/bin/bash'; \
        echo; \
        echo './create_wildfly_admin.sh'; \
        echo; \
        echo './add_jboss_cli.sh'; \
        echo 'rm -f '${WILDFLY_HOME}'/standalone/configuration/standalone_xml_history/current/*'; \
        echo; \
        echo ${WILDFLY_HOME}'/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0 $([ "${DEBUGGING}" == "true" ] && echo "--debug")'; \
    } > run_wildfly.sh && \
    \
    { \
        echo '#!/bin/bash'; \
        echo; \
		echo 'echo "========================================================================="'; \
        echo 'echo'; \
		echo 'echo "  This is a Docker image for the Java application server WildFly. The"'; \
        echo 'echo "  image is based on slim debian-image and prepared for the tools of the"'; \
        echo 'echo "  university medicine greifswald (but can also be used for other similar"'; \
        echo 'echo "  projects)."'; \
        echo 'echo'; \
        echo 'echo "  https://hub.docker.com/repository/docker/mosaicgreifswald/wildfly"'; \
        echo 'echo'; \
		echo 'echo "========================================================================="'; \
        echo 'echo'; \
        echo 'cat versions'; \
        echo 'echo'; \
        echo; \
        echo '# befor wildfly'; \
        echo './run_wildfly.sh'; \
        echo '# after wildfly'; \
    } > run.sh && \
    \
    echo "  |____ 9. prepare wildfly" && \
	echo -n "  |  |____ 1. start app-server" && \
	(${WILDFLY_HOME}/bin/standalone.sh > install.log 2>&1 &) && \
	STARTTIME=$(date +%s) && \
	TIMEOUT=30 && \
	(until `./wildfly_started.sh`;do sleep 1;echo -n '.';if [ $(($(date +%s)-STARTTIME)) -ge $TIMEOUT ];then echo;cat install.log;echo;exit 1;fi;done;echo -e "\r  |  |____ 1. start app-server $(printf %-30s '('$(($(date +%s)-STARTTIME))'s)')") && \
	echo "  |  |____ 2. install mysql-connector" && \
	($JBOSS_CLI -c "module add --name=com.mysql --resources=${TEMP_PATH}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar --dependencies=javax.api\,javax.transaction.api" > install.log || (>&2 cat install.log && exit 1)) && \
	echo "  |  |____ 3. add datasource-driver for mysql" && \
	($JBOSS_CLI -c "/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql,driver-class-name=com.mysql.cj.jdbc.Driver)" > install.log || (>&2 cat install.log && exit 1)) && \
	echo "  |  |____ 4. add deployment-scanner" && \
    ($JBOSS_CLI -c "/subsystem=deployment-scanner/scanner=entrypoint:add(scan-interval=5000,path=${ENTRY_WILDFLY_DEPLOYS})" > install.log || (>&2 cat install.log && exit 1)) && \
	echo "  |  |____ 5. shutdown app-server" && \
	($JBOSS_CLI -c ":shutdown" > install.log || (>&2 cat install.log && exit 1)) && \
    \
    echo "  |____ 10. create textfiles 'versions' and 'entrypoints'" && \
	{ \
		echo "  Build-Date (WildFly-Img): $(date +%Y-%m-%d)"; \
		echo "  Distribution            : $(cat /etc/os-release | grep -E '^NAME' | cut -d'"' -f2) v$(cat /etc/os-release | grep 'VERSION_ID' | cut -d'=' -f2 | sed 's/\"//g')"; \
		echo "  Java                    : $(java -version 2>&1 | head -n1 | sed -r 's/^.+"(.+)".+$/\1/' | cat)"; \
		echo "  WildFly                 : $(${WILDFLY_HOME}/bin/standalone.sh -version --admin-only | grep WildFly | sed -r 's/^[^(]+ ([0-9\.]+Final).+$/\1/' | cat)"; \
		echo "  MySQL-Connector         : ${MYSQL_CONNECTOR_VERSION}"; \
		echo "  EclipseLink             : $(ls ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-* | sed -r 's/^.+-([0-9\.]+)\.jar$/\1/' | cat)"; \
		echo "  KeyCloak-Client         : ${KEYCLOAK_VERSION}"; \
	} > versions && \
	{ \
		echo "  ENTRY_WILDFLY_CLI       : ${ENTRY_WILDFLY_CLI}"; \
		echo "  ENTRY_WILDFLY_DEPLOYS   : ${ENTRY_WILDFLY_DEPLOYS}"; \
		echo "  ENTRY_WILDFLY_LOGS      : ${ENTRY_WILDFLY_LOGS}"; \
	} > entrypoints && \
	\
	echo "  |____ 11. cleanup" && \
	(( \
        apt-get remove --purge --auto-remove -y gnupg && \
        apt-get clean && \
        apt-get autoremove && \
        rm -rf ${TEMP_PATH} ${WILDFLY_HOME}/standalone/configuration/standalone_xml_history/current/* && \
        ln -s ${WILDFLY_HOME}/standalone/log ${ENTRY_WILDFLY_LOGS} && \
        chown ${USER}:${USER} -R ${HOME} ${ENTRY_WILDFLY_LOGS} && \
        chmod u+x ${HOME}/*.sh \
    ) > install.log 2>&1 || (>&2 cat install.log && echo && exit 1)) && \
	\
	echo && \
	echo "===========================================================" && \
	echo && \
	cat versions && \
	echo && \
	echo "===========================================================" && \
	echo && \
	cat entrypoints && \
	echo && \
	echo "===========================================================" && \
	echo

WORKDIR ${HOME}
USER ${USER}

# ports
EXPOSE 8080 9990 8443 9993 8787

# check if wildfly is running
HEALTHCHECK CMD ./healthcheck.sh

# run wildfly
CMD ["./run.sh"]
