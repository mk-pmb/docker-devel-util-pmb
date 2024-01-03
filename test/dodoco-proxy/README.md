
Please debug: Docker seems to ignore `service_healthy`.
=======================================================

Related discussion in issue tracker:
[issue #1](https://github.com/mk-pmb/docker-devel-util-pmb/issues/1)


### Software used

```text
$ lsb_release -d; docker --version; docompose --version
Description:    Ubuntu 20.04.6 LTS
Docker version 24.0.7, build afdd53b
docker-compose version 1.26.2, build eefe0d3
```

Output below is from testing with `docompose rebup`.
The equivalent for regular `docker-compose` should be something like:
`docker-compose down &&`
`docker-compose build --no-cache --force-rm &&`
`docker-compose up`


### Expectation

From the `depends_on: app_init: condition: service_healthy` in
[`docker-compose.yaml`](docker-compose.yaml) we would expect `app_main_1`
to be started only after `app_init_1` has set its health flag.


### Observation

Instead, `app_main_1` starts and finishes its command almost immediately,
long before the health flag file has been created:

```text
Creating dodoco-proxy_app_init_1 ... done
Creating dodoco-proxy_app_main_1 ... done
Attaching to dodoco-proxy_app_init_1, dodoco-proxy_app_main_1
app_init_1  | >>> env summary @ init >>>
app_main_1  | >>> env summary @ main >>>
app_main_1  | <<< env summary @ main <<<
app_init_1  | <<< env summary @ init <<<
app_init_1  | ls: /tmp/healthy: No such file or directory
app_init_1  | 07:49:40 …zZz…
app_init_1  | ls: /tmp/healthy: No such file or directory
app_init_1  | 07:49:50 …zZz…
app_init_1  | 07:50:00 …zZz…
```

However, for an unknown reason, `app_main_1` seems to stay around idle
_until_ the health check succeeds:

```text
app_init_1  | 07:50:10 …zZz…
app_init_1  | ls: /tmp/healthy: No such file or directory
app_init_1  | -rw-r--r--    1 root     root             0 Jan  3 07:50 /tmp/healthy
dodoco-proxy_app_main_1 exited with code 0
app_init_1  | 07:50:15 …zZz…
app_init_1  | 07:50:20 quit init.
dodoco-proxy_app_init_1 exited with code 0
```


### Almost correct behavior

Idling around until the health check succeeds is indeed part of the
desired behavior, but how can we swap the phases around so it
_first_ waits for the health check and _then_ runs its command?





