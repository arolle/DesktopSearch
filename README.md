DesktopSearch
=============

A WebApp to browse directories in a cool fashion. It is written in XQuery using RESTXQ-API of [BaseX](http://basex.org)-Server-Architecture.


Getting Started
---------------
Check out the project using

	$ git clone git://github.com/arolle/DesktopSearch.git

And start the web server inside the project via

	$ mvn jetty:run 

Head your browser to http://localhost:8984/


Add custom Databases
--------------------
To create new databases representing a directory structure use the [FSML](https://github.com/holu/fsml/ "FileSystemML") project:

	$ git clone git://github.com/holu/fsml.git

package it with Maven (`$ mvn package`) and create the XML using

	$ java -jar fsml-1.0-SNAPSHOT-jar-with-dependencies.jar [dbname] [path] [exclude-from-path]

Place the created database inside the `data` folder. It will then be selectable as data source in the frontend.
