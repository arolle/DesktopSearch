DesktopSearch
=============

A WebApp to browse directories in a cool fashion. It is written in XQuery using RESTXQ-API of [BaseX](http://basex.org)-Server-Architecture. This is a web application to be used with BaseX, to launch refer aswell to [BaseX Web Applications](http://docs.basex.org/wiki/Web_Application).

![screenshot of DesktopSearch interface](https://raw.github.com/arolle/DesktopSearch/master/screenshot.png)

Getting Started
---------------
Check out the project using

	$ git clone git://github.com/arolle/DesktopSearch.git

And start the web server inside the project via

	$ cd DesktopSearch && mvn jetty:run

Head your browser to http://admin:admin@localhost:8984/ (default credentials are admin/admin)


Add custom Databases
--------------------
To create new databases representing a directory structure use the [FSML](https://github.com/holu/fsml/ "FileSystemML") project:

	$ git clone git://github.com/holu/fsml.git

package it with Maven (`$ mvn package`) and create the XML using

	$ java -jar fsml-1.0-SNAPSHOT-jar-with-dependencies.jar [dbname] [path] [exclude-from-path]

Place the created database inside the `data` folder of the DesktopSearch project. It will then be selectable as data source in the frontend.
