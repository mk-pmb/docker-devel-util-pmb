
<!--#echo json="package.json" key="name" underline="=" -->
docker-devel-util-pmb
=====================
<!--/#echo -->

<!--#echo json="package.json" key="description" -->
Some docker utilities for software developers.
<!--/#echo -->




Install instructions
--------------------

The lazy way:<br>
`git clone https://github.com/mk-pmb/docker-devel-util-pmb /tmp/d && sudo -E /tmp/d/install_globally.sh`

The proper way:

1.  Use Ubuntu focal or later.
1.  Clone this directory somewhere:<br>
    `git clone https://github.com/mk-pmb/docker-devel-util-pmb`
1.  If you need a specific version, check `package.json` for
    the version number. It should be within the first few lines.
    If it's out of range, you may need to rewind the repo.
1.  Optionally, read the source of
    the script that you'll be using in the next step.
1.  `sudo -E /path/to/docker-devel-util-pmb/install_globally.sh`



Known issues
------------

* Needs more/better tests and docs.




&nbsp;


License
-------
<!--#echo json="package.json" key=".license" -->
GPL-3.0
<!--/#echo -->
