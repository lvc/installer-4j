Installer 4J
============

Install/remove Java tools and their dependencies:

| TOOL                    | VERSION | URL                                            |
|-------------------------|---------|------------------------------------------------|
| japi-tracker            | 1.3     | https://github.com/lvc/japi-tracker            |
| japi-monitor            | 1.3     | https://github.com/lvc/japi-monitor            |
| japi-compliance-checker | 2.4     | https://github.com/lvc/japi-compliance-checker |
| pkgdiff                 | 1.7.2   | https://github.com/lvc/pkgdiff                 |

Requires
--------

* Perl 5
* curl

Usage
-----

    make install   prefix=PREFIX target=TOOL
    make uninstall prefix=PREFIX target=TOOL

###### Example

    make install   prefix=/usr target=japi-tracker
    make uninstall prefix=/usr target=japi-tracker
