# WildFly Docker Image
This is a Docker image for the Java application server [WildFly](http://wildfly.org/). The image is based on image [jboss/wildfly](https://hub.docker.com/r/jboss/wildfly/) and prepared for the tools of the MOSAIC-project (but can also be used for all other projects):

* [E-PIX](https://mosaic-greifswald.de/werkzeuge-und-vorlagen/id-management-e-pix.html) (Enterprise Patient Identifier Crossreferencing)
* [gPAS](https://mosaic-greifswald.de/werkzeuge-und-vorlagen/pseudonymverwaltung-gpas.html) (generic Pseudonym Administration Service)
* [gICS](https://mosaic-greifswald.de/werkzeuge-und-vorlagen/einwilligungsmanagement-gics.html) (generic Informed Consent Service)



### Tags
* `15.0.1.Final-20190204`, `15.0.1.Final`, `15`, `latest` ([Dockerfile](https://github.com/mosaic-hgw/WildFly/blob/master/Dockerfile))
  - from:     jboss/wildfly:15.0.1.Final
  - updated:  mySQL-connector to v8.0.15
  - updated:  mariaDB-connector to v2.4.0
  - updated:  EclipseLink to v2.7.4
  - updated:  wait-for-it.sh from Nov 04, 2018
  - added:    debug-mode on port 8787
  - fixed:    script run.sh
  - improved: generated admin-password without special characters
  - improved: deployment-scanner
  - improved: which-installation
* `13.0.0.Final-20180830`, `13.0.0.Final`, `13`
  - from:     jboss/wildfly:13.0.0.Final
  - updated:  mySQL-connector to 8.0.11
  - updated:  mariaDB-connector to 2.2.6
  - updated:  EclipseLink to 2.7.3
  - installed:'which' for wait-for-it.sh
* `12.0.0.Final-20180515`, `12.0.0.Final`
  - updated:  mySQL-connector to 5.1.46
  - updated:  mariaDB-connector to 2.2.4
  - fixed:    creating admin-user
* `12.0.0.Final-20180307`
  - from:     jboss/wildfly:12.0.0.Final
  - updated:  mariaDB-connector to 2.2.2
  - updated:  EclipseLink to 2.7.1
* `11.0.0.Final-20171204`
  - from:     jboss/wildfly:11.0.0.Final
  - updated:  mySQL-connector to 5.1.45
  - updated:  mariaDB-connector to 2.2.0
  - updated:  EclipseLink to 2.7.0
  - updated:  wait-for-it.sh from Jul 20, 2017
* `10.1.0.Final-20170707`
  - updated:  mySQL-connector to 5.1.42
  - added:    mariaDB-connector 2.0.3
  - improved: changed all sha1sum to sha256sum
* `10.1.0.Final-20170418`
  - updated:  mySQL-connector to 5.1.41
  - updated:  EclipseLink to 2.6.4
  - added:    script to check wildfly is complete started
  - added:    Docker-Healthcheck
* `10.1.0.Final-20160930`
  - updated:  mySQL-connector to 5.1.40
  - added:    script to create admin-user with given or random password at first run
  - improved: jboss-completed-files moved into container
* `10.1.0.Final-20160913`
  - added:    sha1-hash to check mySQL-connector download
  - added:    sha1-hash to check wait-for-it.sh download
  - renamed:  command `startWildfly.sh` to `run.sh`
  - few improvements
* `10.1.0.Final-20160912`
  - from:     jboss/wildfly:10.1.0.Final
  - added:    mySQL-connector 5.1.39
  - added:    wait-for-it.sh from Apr 11, 2016
  - added:    script to execute automatical jboss-batch-files
* `10.0.0.Final-20160601`
  - from:     piegsaj/wildfly
  - added:    mysql-connector 5.1.38
  - added:    EclipseLink 2.6.2

### Run your Image
* only deployments and add admin with random-password per default
  ```sh
  docker run \
    -p 8080:8080 \
    -v /path/to/your/deployments:/entrypoint-deployments \
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
    -p 8080:8080 \
    -v /path/to/your/deployments:/entrypoint-deployments \
    -v /path/to/your/batch-files:/entrypoint-jboss-batch \
    mosaicgreifswald/wildfly
  ```

* over docker-compose
  ```yaml
  version: '2'
  services:

    app:
      image: mosaicgreifswald/wildfly
      ports:
        - 8080:8080
      volumes:
        - /path/to/your/batch-files:/entrypoint-jboss-batch
        - /path/to/your/deployments:/entrypoint-deployments
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
      volumes:
        - /path/to/your/batch-files:/entrypoint-jboss-batch
        - /path/to/your/deployments:/entrypoint-deployments
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
    --resources=/entrypoint-jboss-batch/postgresql.jar \
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
