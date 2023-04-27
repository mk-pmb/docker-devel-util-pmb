
DevDock
=======

… is a template system for managing docker-compose container groups.

Its main purpose is to make docker-compose projects portable,
saving you from having to adjust lots of absolute paths manually.

It also helps you keep secrets like passwords in separate files
distinct from your structural blue print. That way, you can host the
latter in a public git repo while `.gitignore`-ing your secrets.





Installation
------------

DevDock needs some of the other tools in this repo,
so you'll need to install all of it.
See [`../README.md`](../README.md) for how.




How to use
----------

### Project concepts

* Every DevDock project has a name, which you can pick yourself,
  as long as it starts with a letter and consist of only [Basic Latin
  ](https://en.wikipedia.org/wiki/Basic_Latin_%28Unicode_block%29)
  letters (`a-z`), digits (`0-9`), U+002D hyphen-minus (`-`) and
  U+005F low line (`_`).
  * In the container names, hyphen-minus may or may not be converted to
    low line.
* A DevDock project must reside in a directory whose name is the
  project name followed by `.devdock`.
* The project name will be used as a prefix for your docker container names.
* Example projects can be found in the [examples/](examples/) directory.


### Controlling the containers

* start in background: `./dock.sh bgup`
* start in foreground: `./dock.sh`
  * ⚠ Running docker containers in foreground will captivate your terminal.
    There is an un-captivate sequence hidden somewhere in the Docker docs,
    but the easier way is to have another shell ready to stop the container.
* clean shutdown: `./dock.sh down`






Known issues
------------

* Needs more/better tests and docs.




&nbsp;


License
-------

See top level of repo.




