# WildFly Docker Image
This is a Docker image for the Java application server [WildFly](http://wildfly.org/). The image is based on image [jboss/wildfly](https://hub.docker.com/r/jboss/wildfly/) and prepared for the tools of the MOSAIC-project (but can also be used for all other projects):

* [E-PIX](https://mosaic-greifswald.de/werkzeuge-und-vorlagen/id-management-e-pix.html) (Enterprise Patient Identifier Crossreferencing)
* [gPAS](https://mosaic-greifswald.de/werkzeuge-und-vorlagen/pseudonymverwaltung-gpas.html) (generic Pseudonym Administration Service)
* [gICS](https://mosaic-greifswald.de/werkzeuge-und-vorlagen/einwilligungsmanagement-gics.html) (generic Informed Consent Service)



### Last changes
* `19.1.0.Final-20200602`, `latest` ([Dockerfile](https://github.com/mosaic-hgw/WildFly/blob/master/Dockerfile))
  - from:     jboss/wildfly:19.1.0.Final
  - added:    labels like [opencontainers.org](https://github.com/opencontainers/image-spec/blob/master/annotations.md)
  - updated:  EclipseLink to v2.7.7
  - updated:  mySQL-connector to v8.0.20
* [full history](https://github.com/mosaic-hgw/WildFly/blob/master/change_history.md)

### Run Image
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
    -v /path/to/your/deployments:/entrypoint-deployments \
    -v /path/to/your/batch-files:/entrypoint-jboss-batch \
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
      environment:
        WILDFLY_PASS: admin-secret
        HEALTHCHECK_URLS: |
          http://localhost:8080
          http://localhost:8080/ths-web/html/public/common/processCompleted.xhtml
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
