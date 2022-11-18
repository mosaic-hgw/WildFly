[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

# WildFly Docker Image
This is a Docker image for the Java application server [WildFly](http://wildfly.org/). The image is based on slim [debian-image](https://hub.docker.com/_/debian) and prepared for the tools of the MOSAIC-project (but can also be used for all other projects):

* [E-PIX](https://mosaic-greifswald.de/werkzeuge-und-vorlagen/id-management-e-pix.html) (Enterprise Patient Identifier Crossreferencing)
* [gPAS](https://mosaic-greifswald.de/werkzeuge-und-vorlagen/pseudonymverwaltung-gpas.html) (generic Pseudonym Administration Service)
* [gICS](https://mosaic-greifswald.de/werkzeuge-und-vorlagen/einwilligungsmanagement-gics.html) (generic Informed Consent Service)

## Why should you use this WildFly-Image?
* This images are based on Debian, one of the most popular Linux distributions.
* This image is a non-root container image. This adds an extra layer of security and is generally recommended for production environments.
* This image can be started directly without building your own image first. Of course, you can still build your own image.

## Available entrypoints
Entrypoints are directories in the container that can be mounted as volumes.
* `/entrypoint-wildfly-cli` to execute jBoss-cli-files before start WildFly (read-only access)
* `/entrypoint-wildfly-deployments` to import your deployments, also ear- and/or war-files (read-only access, optional write access)
* `/entrypoint-wildfly-logs` to export all available log-files (read/write access)
* `/entrypoint-wildfly-addins` to import additionals files for deployments (read-only access)
* `/entrypoint-java-cacerts` to change the cacerts with your own (read-only access)

## Useful Environment-Variables
Attention: In this version some ENV variables have been renamed!
* `WF_ADD_CLI_FILTER` define additional pipe-separated file-extensions that jboss-cli should process, default is empty
* `WF_ADMIN_USER` define username for wildfly-admin, default: admin
* `WF_ADMIN_PASS` to set password for wildfly-admin, default is a random-string
* `WF_NO_ADMIN` set "true" if you don't need wildfly-admin, default is empty
* `WF_HEALTHCHECK_URLS` contain a list of urls to check the health of this container, default is empty
* `TZ` to change timezone, default: Europe/Berlin
* `JAVA_OPTS` you need more memory? then give yourself more memory and any more.
* `WF_MARKERFILES` Available values are "true", "false" and "auto" (default). These affect the creation of marker-files (.isdeploying or .deployed) in the deployment-directory.
* `WF_DEBUG` set "true" to enable debug-mode in wildfly, default: false
  btw. with `DEBUG_PORT` you can change the ip:port for debugging, default: *:8787

## About Health-Check-Strategies
There are 3 strategies built into this docker image.

* Microprofile-Health<br>
  This is the default strategy and only works if the `WF_ADMIN_PASS` variable is set. Then the WildFly management automatically checks all deployments that have the microprofile installed (see https://microprofile.io/project/eclipse/microprofile-health).
* URL-check<br>
  For this strategy at least one accessible URL must be specified as ENV-variable `WF_HEALTHCHECK_URLS`. If a URL is not reachable or does not return the HTTP status code 200, the health status is set to "unhealthly". This strategy can be combined with Microprofile-Health.
* Running-Deployments<br>
  This solution only works if neither of the other two strategies is used. It only checks that none of the deployments has booted incorrectly.

## Current Software-Versions on this Image
* `26.1.2.Final-20221118`, `latest` ([Dockerfile](https://github.com/mosaic-hgw/WildFly/blob/master/Dockerfile))
  - **Debian** 11.5 "bullseye"
  - **openJRE** 17.0.5
  - **WildFly** 26.1.2.Final
  - **KeyCloak-Client** 19.0.2
  - **EclipseLink** 2.7.11
  - **mySQL-connector** 8.0.30
  - vulnerable updates:
    - jackson-databind 2.13.4.2 <small><small>(CVE-2022-42003, CVE-2022-42004)</small></small>
    - protobuf-java 3.19.6 <small><small>(CVE-2022-3171)</small></small>
    - artemis-server 2.24.0 <small><small>(CVE-2022-35278)</small></small>
    - hibernate-core 5.4.24.Final <small><small>(CVE-2020-25638)</small></small>
    - h2database 2.1.210 <small><small>(CVE-2021-23463, CVE-2021-42392, CVE-2022-23221)</small></small>
    - jsoup 1.15.3 <small><small>(CVE-2022-36033)</small></small>
    - snakeyaml 1.32 <small><small>(CVE-2022-25857, CVE-2022-38749, CVE-2022-38750, CVE-2022-38751, CVE-2022-38752)</small></small>
    - woodstox-core 6.4.0 <small><small>(CVE-2022-40153, CVE-2022-40151, CVE-2022-40152, CVE-2022-40154, CVE-2022-40155, CVE-2022-40156)</small></small>
    - xercesImpl 2.12.2 <small><small>(CVE-2022-23437)</small></small>
* [full history](https://github.com/mosaic-hgw/WildFly/blob/master/change_history.md)

## Run Image
* only deployments and add admin with random-password per default
  ```sh
  docker run \
    -p 8080:8080 \
    -v /path/to/your/deployments:/entrypoint-wildfly-deployments \
    mosaicgreifswald/wildfly
  ```

* if you want to set admin-password by self, you can do it over environment variable
  ```sh
  docker run \
    -e WF_ADMIN_PASS=top-secret
    ...
  ```

* or you don't want to create an admin-user
  ```sh
  docker run \
    -e WF_NO_ADMIN=true
    ...
  ```

* with deployments and jboss-batch
  ```sh
  docker run \
    -v /path/to/your/deployments:/entrypoint-wildfly-deployments \
    -v /path/to/your/batch-files:/entrypoint-wildfly-cli \
    ...
  ```

* with healthcheck-urls
  ```sh
  docker run \
    -e WF_HEALTHCHECK_URLS=http://localhost:8080\nhttp://localhost:8080/ths-web/html/public/common/processCompleted.xhtml
    ...
  ```

### Use docker-compose
* over docker-compose with dependent on mysql-db (example)
  ```yaml
  version: '3'
  services:
    wildfly:
      image: mosaicgreifswald/wildfly
      ports:
        - 8080:8080
      volumes:
        - /path/to/your/batch-files:/entrypoint-wildfly-cli
        - /path/to/your/deployments:/entrypoint-wildfly-deployments
  ```

* over docker-compose with dependent on mysql-db (example)
  ```yaml
  version: '3'
  services:
    mysql:
      image: mysql:8.0
      environment:
        MYSQL_ROOT_PASSWORD: top-secret
      volumes:
        - /path/to/your/init-sql-files:/docker-entrypoint-initdb.d
    wildfly:
      image: mosaicgreifswald/wildfly
      ports:
        - 8080:8080
      depends_on:
        - mysql
      environment:
        WF_ADMIN_PASS: admin-secret
        WF_HEALTHCHECK_URLS: |
          http://localhost:8080
          http://localhost:8080/your/own/success/page.html
      volumes:
        - /path/to/your/batch-files:/entrypoint-wildfly-cli
        - /path/to/your/deployments:/entrypoint-wildfly-deployments
      entrypoint: /bin/bash
      command: -c "./wait-for-it.sh mysql:3306 -t 60 && ./run.sh"
  ```

### Examples for create JBoss-CLI-File
* add mysql-datasource
  ```sh
  data-source add \
    --name=MySQLPool \
    --jndi-name=java:/jboss/MySQLDS \
    --connection-url=jdbc:mysql://mysql:3306/dbName \
    --user-name=mosaic \
    --password=top-secret \
    --driver-name=mysql
  ```

* add postgresql-jdbc-driver-module and datasource
  ```sh
  batch

  module add \
    --name=org.postgre \
    --resources=/entrypoint-wildfly-cli/postgresql.jar \
    --dependencies=javax.api,javax.transaction.api

  /subsystem=datasources/jdbc-driver=postgre: \
    add( \
      driver-name="postgre", \
      driver-module-name="org.postgre", \
      driver-class-name=org.postgresql.Driver \
    )

  data-source add \
    --name=PostgreSQLPool \
    --jndi-name=java:/jboss/PostgreSQLDS \
    --connection-url=jdbc:postgresql://app-db:5432/dbName \
    --user-name=mosaic \
    --password=top-secret \
    --driver-name=postgre

  run-batch
  ```
