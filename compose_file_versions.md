
Compose file versions
=====================

### Definitions

* "dependency conditions":
  I'll use this term to describe the syntax feature that allows for a service
  to be started only when another service is ready to be used, e.g.
  `depends_on: database: condition: service_health`.
* "stable versions":
  Compatible with Docker v24.0.7
  (current latest stable release at time of writing)
  and docker-compose v1.26.2
  (the `:latest` [dockerized docker-compose][dodoco-hub] at time of writing,
  according to `docker run docker/compose:latest --version`).

  [dodoco-hub]: https://docker.io/docker/compose:latest


### 2

* ✅ Supported in stable versions.
* ⛔ Doesn't yet support dependency conditions.
* ⛔ The `build` command does not accept global `--build-arg` options:
  ```text
  ERROR: --build-arg is only supported when services are specified for
  API version < 1.25. Please use a Compose file version > 2.2 or specify
  which services to build.
  ```
  * The error message is slightly misleading, as v2.2 is sufficient.
    The author of the error message probably meant `≥` instead of `>`.


### 2.1

* ✅ Supported in stable versions.
* ✅ Supports dependency conditions.
* ⛔ No global `--build-arg`.


### 2.2 🏆

* ✅ Supported in stable versions.
* ✅ Supports dependency conditions.
  * albeit without `service_completed_successfully`,
    but usually you'll want `service_healthy` anyway.
* ✅ Supports global `--build-arg`.


### 3, 3.3

* ✅ Supported in stable versions.
* ⛔ No longer supports dependency conditions.
  You can read more about it
  [on StackOverflow](https://stackoverflow.com/a/71060072)
  or [on GitHub](https://github.com/moby/moby/issues/30404),
  or search for the relevant error message:
  `services.[…].depends_on contains an invalid type, it should be an array`

* ✅ Supports global `--build-arg`.


### 3.9

* ⛔ Not supported in stable versions.
* ✅ Re-introduces support for dependency conditions.
* ✅ Supports global `--build-arg`.








