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
* `/entrypoint-java-cacerts` to change the cacerts with your own (read-only access)

## About Health-Check-Strategies
There are 3 strategies built into this docker image.

* Microprofile-Health<br>
  This is the default strategy and only works if the `WILDFLY_PASS` variable is set. Then the WildFly management automatically checks all deployments that have the microprofile installed (see https://microprofile.io/project/eclipse/microprofile-health).
* URL-check<br>
  For this strategy at least one accessible URL must be specified as ENV-variable `HEALTHCHECK_URLS`. If a URL is not reachable or does not return the HTTP status code 200, the health status is set to "unhealthly". This strategy can be combined with Microprofile-Health.
* Running-Deployments<br>
  This solution only works if neither of the other two strategies is used. It only checks that none of the deployments has booted incorrectly.

## Current Software-Versions on this Image
* `24.0.1.Final-20210917`, `latest` ([Dockerfile](https://github.com/mosaic-hgw/WildFly/blob/master/Dockerfile))
  - **Debian** 11 "bullseye"
  - **openJRE** 11.0.12
  - **WildFly** 24.0.1.Final
  - **KeyCloak-Client** 15.0.2
  - **EclipseLink** 2.7.9
  - **mySQL-connector** 8.0.26
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
    -e WILDFLY_PASS=top-secret
    ...
  ```

* or you don't want to create an admin-user
  ```sh
  docker run \
    -e NO_ADMIN=true
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
    -e HEALTHCHECK_URLS=http://localhost:8080\nhttp://localhost:8080/ths-web/html/public/common/processCompleted.xhtml
    ...
  ```

### Use docker-compose
* over docker-compose with dependent on mysql-db (example)
  ```yaml
  version: '2'
  services:

    app:
      image: mosaicgreifswald/wildfly
      ports:
        - 8080:8080
      volumes:
        - /path/to/your/batch-files:/entrypoint-wildfly-cli
        - /path/to/your/deployments:/entrypoint-wildfly-deployments
  ```

* over docker-compose with dependent on mysql-db (example)
  ```yaml
  version: '2'
  services:

    db:
      image: mysql:5.7
      environment:
        MYSQL_ROOT_PASSWORD: top-secret
      volumes:
        - /path/to/your/init-sql-files:/docker-entrypoint-initdb.d

    app:
      image: mosaicgreifswald/wildfly
      ports:
        - 8080:8080
      depends_on:
        - db
      links:
        - db:app-db
      environment:
        WILDFLY_PASS: admin-secret
        HEALTHCHECK_URLS: |
          http://localhost:8080
          http://localhost:8080/your/own/success/page.xhtml
      volumes:
        - /path/to/your/batch-files:/entrypoint-wildfly-cli
        - /path/to/your/deployments:/entrypoint-wildfly-deployments
      entrypoint: /bin/bash
      command: -c "./wait-for-it.sh app-db:3306 -t 60 && ./run.sh"
  ```

### Examples for create JBoss-CLI-File
* add mysql-datasource
  ```sh
  data-source add \
    --name=MySQLPool \
    --jndi-name=java:/jboss/MySQLDS \
    --connection-url=jdbc:mysql://app-db:3306/dbName \
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
