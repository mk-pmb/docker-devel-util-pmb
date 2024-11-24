
DevDock todo
============

Imagine this typo:

```text
    volumes:
      - ${dd_dirr}'/etc/ssh:/ssh-config'
    command: ['head', '-n', '2', '--', '/ssh-config/ssh_host_rsa_key']
```


Thus: Make ${DD:dirr} (empty variable) a syntax error



Research todo
=============

* Docker-compose `configs` feature:
  https://docs.docker.com/compose/compose-file/05-services/#configs
  https://docs.docker.com/compose/compose-file/08-configs/



