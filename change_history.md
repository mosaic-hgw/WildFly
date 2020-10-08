### Change-History
* `20.0.1.Final-20201008`, `latest` ([Dockerfile](https://github.com/mosaic-hgw/WildFly/blob/master/Dockerfile))
  - from:     alpine:3.12
  - updated:  WildFly 20.0.1.Final
  - updated:  mySQL-connector to v8.0.21
  - improved: separeted script for jboss-batches
  - removed:  mariaDB-connector
* `19.1.0.Final-20200602`, `latest` ([Dockerfile](https://github.com/mosaic-hgw/WildFly/blob/master/Dockerfile))
  - from:     jboss/wildfly:19.1.0.Final
  - added:    labels like [opencontainer.org](https://github.com/opencontainers/image-spec/blob/master/annotations.md)
  - updated:  EclipseLink to v2.7.7
  - updated:  mySQL-connector to v8.0.20
* `19.0.0.Final-20200327`
  - added:    script healthcheck.sh for check deployment-states
  - updated:  mySQL-connector to v8.0.19
  - updated:  mariaDB-connector to v2.6.0
  - updated:  EclipseLink to v2.7.6
  - updated:  wait-for-it.sh from Feb 01, 2020
  - changed:  repository-domain
  - changed:  script wildfly_started.sh, use curl
  - changed:  docker-healthcheck, use healthcheck.sh
* `18.0.1.Final-20191213`
  - from:     jboss/wildfly:18.0.1.Final
  - updated:  mySQL-connector to v8.0.18
  - updated:  mariaDB-connector to v2.5.2
  - updated:  EclipseLink to v2.7.5
* `16.0.0.Final-20190306`
  - from:     jboss/wildfly:16.0.0.Final
  - fixed:    Docker-Healthcheck
* `15.0.1.Final-20190204` (deleted on 2020-01-29)
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
* `13.0.0.Final-20180830`
  - from:     jboss/wildfly:13.0.0.Final
  - updated:  mySQL-connector to v8.0.11
  - updated:  mariaDB-connector to v2.2.6
  - updated:  EclipseLink to v2.7.3
  - installed:'which' for wait-for-it.sh
* `12.0.0.Final-20180515`
  - updated:  mySQL-connector to v5.1.46
  - updated:  mariaDB-connector to v2.2.4
  - fixed:    creating admin-user
* `12.0.0.Final-20180307`
  - from:     jboss/wildfly:12.0.0.Final
  - updated:  mariaDB-connector to v2.2.2
  - updated:  EclipseLink to v2.7.1
* `11.0.0.Final-20171204`
  - from:     jboss/wildfly:11.0.0.Final
  - updated:  mySQL-connector to v5.1.45
  - updated:  mariaDB-connector to v2.2.0
  - updated:  EclipseLink to v2.7.0
  - updated:  wait-for-it.sh from Jul 20, 2017
* `10.1.0.Final-20170707`
  - updated:  mySQL-connector to v5.1.42
  - added:    mariaDB-connector 2.0.3
  - improved: changed all sha1sum to sha256sum
* `10.1.0.Final-20170418`
  - updated:  mySQL-connector to v5.1.41
  - updated:  EclipseLink to v2.6.4
  - added:    script to check wildfly is complete started
  - added:    Docker-Healthcheck
* `10.1.0.Final-20160930`
  - updated:  mySQL-connector to v5.1.40
  - added:    script to create admin-user with given or random password at first run
  - improved: jboss-completed-files moved into container
* `10.1.0.Final-20160913`
  - added:    sha1-hash to check mySQL-connector download
  - added:    sha1-hash to check wait-for-it.sh download
  - renamed:  command startWildfly.sh to run.sh
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
