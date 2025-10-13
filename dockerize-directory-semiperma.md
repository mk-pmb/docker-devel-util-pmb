
dockerize-directory-semiperma (DDSP, dkdirsemi)
===============================================

DDSP simplifies the management of a docker container for simple projects.



Benefits of dockerization
-------------------------

When you develop a software project, it can be useful to
[dockerize](https://docs.docker.com/)
tasks like your linter, the build process, and tests:

* __Enhanced security:__
  Running in an unprivileged docker container, while not a real sandbox,
  can mitigate some low-grade supply chain attacks.
  If later you want to upgrade security (at the cost of speed),
  you can configure docker to use a hardened sandbox for its containers,
  e.g. [gVisor](https://en.wikipedia.org/wiki/GVisor).

* __Consistency:__
  The container's separation from your developer machine ensures can help
  verify that you've correctly specified all dependencies and preconditions.

* __Resource limitations:__
  In a CI pipeline, usually you want build and test scripts to run at
  maximum speed, using all the resources allocated for your CI runner.
  For development though, you usually want them tamed, so you can still
  work on other stuff while the build runs, and not worry about having
  your web browser killed due to memory exhaustion.
  A docker container is an easy way to limit the scripts' resource usage
  in a way they can detect and adjust to.

* __Privacy:__
  Hiding lots of details (e.g. paths) about your developer machine not only
  helps with consistency, but also provides a level of privacy, which in turn
  may help mitigate some security risks,
  especially if they involve social engineering.
  * Device names will still show up in the output of the `mount` command
    inside the container, which may leak hardware information and/or partition
    table details. It still reduces the attack surface though,
    and of the build tools that happily leak paths a lot,
    most don't collect device details for those paths.



Usage
-----

To create and start the docker container for the current working directory
(ideally, your project's root directory):

```bash
dockerize-directory-semiperma ctnr:image='python:3' init
```

If you omit the docker image name, it will guess the image based on heuristics
like whether you have a `package.json`, whether it specifies a mininum node.js
version, and which docker images you currently have available.

To see all available init options:

```bash
dockerize-directory-semiperma --help`
```

If something changes, you can stop and recreate the container with:

```bash
dockerize-directory-semiperma reinit
```

The `reinit` action takes the same options as `init` would.

To work inside the container:

```bash
dockerize-directory-semiperma sh
```

Or if you want a specific shell:

```bash
dockerize-directory-semiperma --tty --interactive exec dash -i
```

Once you're done, you can stop and remove the container:

```bash
dockerize-directory-semiperma stop
```


Advanced configuration
----------------------

In addition to config parameters for the `init`/`reinit` action,
some config can be expressed via the file system:



Automatically bind-mounted volumes (bindvol)
--------------------------------------------

### Motivation: Deduplication of shared files

(For the basics, see [Wikipedia: Data deduplication][wp-data-dedupe].)

  [wp-data-dedupe]: https://en.wikipedia.org/wiki/Data_deduplication

Many of my projects have shared dependencies, so keeping copies in each
project directory would waste a lot of disk space.
Fortunately, symbolic links (symlinks) are an easy way to solve that.
Usually, those symlinks point to locations outside of my project directory,
so when viewed from inside the DDSP container, they would be dead links.
Even if they would work, they would leak unnecessary details about my
developer machine paths into debug artifacts like source maps or traces.


### A solution

Docker can almost easily solve that though:
Inside the container, replace the symlinks with read-only bind-mounts.
Except, docker can't do that, because symlinks cannot be used as mountpoints.
Only real directories can become mountpoints.
We can work around that though:

1.  Have a real directory that contains all the outward-pointing symlinks.
    Let's call that the "border zone".
    * The symlinks may be in subdirectories in order to help you keep them
      neatly organized, and also to help accomodate applications that have
      special expectations on directory structure.
2.  Inside the container, mount a tiny virtual disk onto the border zone.
3.  Inside that virtual disk, create mountpoints with the same name and
    same target as the symlink had.


### Simplifying the solution

To make it easy for DDSP to know which symlinks shall become mountpoints
inside the container, it has some pre-defined border zones that you can use:

* `.dkdirsemi/bindvol`
* `.git/dkdirsemi/bindvol`
* `node_modules/.dkdirsemi/bindvol`
* and a lot more that I can't find a concise way of describing here.
  (`function cfg_scan_bindvol_dirs` &rarr; `BV_DIRS=`)

In the top level of a border zone, entries whose names start with `.tmp.`
are reserved for use by DDSP. Most notably, the `.tmp.overlay` subdirectory
will be used as the virtual disk to hold the mountpoints.


### Using bindvol for `node_modules`

For the examples we'll assume you have these bindvol symlinks
(unfortunately, the `ln` command requires we write the target first):

```bash
mkdir -p .git/dkdirsemi/bindvol/{home,sys}.nm node_modules/@
ln -fsT /usr/lib/node_modules     .git/dkdirsemi/bindvol/sys.nm/node_modules
ln -fsT ~/.node_modules           .git/dkdirsemi/bindvol/home.nm/node_modules
ln -fsT ../../.git/dkdirsemi/bindvol  node_modules/@/.bv
ln -fsT .bv/sys.nm/node_modules   node_modules/@/sys
ln -fsT .bv/home.nm/node_modules  node_modules/@/home
```

* In theory, each dependency could even have its own bindvol,
  but that would result in a very lengthy `docker run` invocation
  and a bloated container config, so try to keep it pragmatic.
* You can then symlink the dependencies like this:
  `node_modules/eslint` &rarr; `@/sys/eslint`
  * You could symlink directly to
    `../.git/dkdirsemi/bindvol/sys.nm/node_modules/eslint`,
    but having the `node_modules/@/sys` indirection makes it easier to mock
    if you want to debug DDSP, or to adapt if a new version of DDSP might
    use another config path.
* Using `node_modules` as the name of the symlinks in the border zone ensures
  that the external modules will find their peer dependencies where they
  expect them.
* The `node_modules/@/[a-z]*` symlinks in the example are picked up by the
  [guess-js-deps](https://github.com/mk-pmb/guess-js-deps-bash)
  tool, so it can automatically arrange symlinks for missing dependencies
  when you run `guess-js-deps usy` (usy = update symlinks).






