Preparation {#PagPreparation}
===========
\tableofcontents

This package ships the source code of \Proj. In order to use the
application, it has to get compiled first. Therefor at least the FB
compiler has to get installed on the users system. Other tools are used
by the author, here's how to get all components working.


# Tools # {#SecTools}

The following table lists all dependencies for \Proj and their
category. The FreeBASIC compiler and the dependency libraries are
mandatory (M), the others are optional. Some are recommended (R) in
order to make use of all package features. Some are helpful for testing
(T) purposes. LINUX users may find some packages in their distrubution
management system (D).

|                                             Name  | Type |  Function                                                      |
| ------------------------------------------------: | :--: | :------------------------------------------------------------- |
| [fbc](http://www.freebasic.net)                   | M    | FreeBASIC compiler to compile the source code                  |
| [Gtk-3](http://www.gtk.org)                       | M  D | GimpToolKit: GUI library                                       |
| [osm_gps_map](http://github.com/nzjrs/osm-gps-map)| M  D | OpenStreetMap widget for Gtk                                   |
| [GIT](http://git-scm.com/)                        | R  D | version control system to organize the files                   |
| [CMake](http://www.cmake.org)                     | R  D | build management system to build executables and documentation |
| [cmakefbc](http://github.com/DTJF/cmakefbc)       | R    | FreeBASIC extension for CMake                                  |
| [fbdoc](http://github.com/DTJF/fbdoc)             | R    | FreeBASIC documentation tool                                   |
| [Doxygen](http://www.doxygen.org/)                | R  D | documentation generator (ie. for this text)                    |
| [Graphviz](http://www.graphviz.org/)              | R  D | Graph Visualization Software (caller/callee graphs)            |
| [LaTeX](https://latex-project.org/ftp.html)       | R  D | A document preparation system (PDF output)                     |
| [Geany](http://www.geany.org/)                    | T  D | Integrated development environment (ie. to test templates)     |
| [devscripts & tools](https://www.debian.org/doc)  | R  D | Scripts for building Debian packages (for target deb)          |

It's beyond the scope of this guide to describe the installation for
those programming tools for all operating systems. Find detailed
installation instructions on the related websides, linked by the name
in the first column.

As an example the preparation of a Debian Linux system is shown here

-# In order to install the FreeBASIC compiler, follow (the installation
   instructions)[https://www.freebasic.net/wiki/CompilerInstalling].

-# Then install the distributed (D) packages of your choise. Ie. on
   Debian LINUX execute:
   ~~~{.txt}
   sudo apt-get install libgtk-3-dev libosmgpsmap-1.0-dev
   sudo apt-get install git cmake doxygen graphviz doxygen-latex texlive geany debhelper
   ~~~
   \note The first line is mandatory. In the second line you can omit
   unwanted packages.

-# Make cmakefbc working, if wanted. That's easy, when you have GIT and
   CMake. Execute (in your projects folder) the commands
   ~~~{.txt}
   git clone https://github.com/DTJF/cmakefbc
   cd cmakefbc
   mkdir build
   cd build
   cmake .. -DCMAKE_MODULE_PATH=../cmake/Modules
   make
   sudo make install
   cd ../..
   ~~~
   \note Omit `sudo` in case of non-LINUX systems.

-# Make fbdoc working, if wanted. That's easy, when you have GIT and
   CMake. Execute (in your projects folder) the commands
   ~~~{.txt}
   git clone https://github.com/DTJF/fbdoc
   cd fbdoc
   mkdir build
   cd build
   cmakefbc ..
   make
   sudo make install
   cd ../..
   ~~~
   \note Omit `sudo` in case of non-LINUX systems.


# Get Package # {#SecGet}

Assuming you installed the recommended GIT software, get your copy of
the \Proj package by

~~~{.txt}
git clone https://github.com/DTJF/pavi
~~~

Now your copy of the source tree should be in the pavi folder under
your projects path.

\note As an alternative you can download a Zip archive by clicking the
	  [Download ZIP](https://github.com/DTJF/pavi/archive/master.zip)
	  button on the \Proj website, and use your local Zip software to
	  unpack the archive.


# Build # {#SecBuild}

Manual builds are possible, but laborious. Better use the recommended
tools CMake and CMakeFbc. From the root (projects) folder execute:

~~~{.txt}
cd pavi
mkdir build
cd build
cmakefbc ..
make
~~~

The newly compiled executable should be at
`pavi/build/src/bas/pavi[.exe]` and can get executed and tested from
there.


# Install # {#SecInstall}

In order to install the binary on your system, so that you can use it
from any path, execute (in the `pavi/build` folder)

~~~{.txt}
sudo make install
~~~

\note Omit `sudo` in case of non-LINUX systems.


# Uninstall # {#SubUninstall}

CMake doesn't support the `uninstall` target, find details in [CMake
FAQ](https://cmake.org/Wiki/CMake_FAQ#Can_I_do_.22make_uninstall.22_with_CMake.3F).
In order to purge that application from your system, remove the files
listed in the file `pavi/build/install_manifest.txt`. Ie. on Unix
systems execute

~~~{.txt}
cd pavi/build
sudo xargs rm < install_manifest.txt
~~~


# Documentation #  {#SubBuildDoc}

The package is prepared to build a documentation in form of a HTML tree
and/or a PDF file. Both get created by the \Doxygen generator, using the
\FbDoc tool to extract (filter) the documentation context from the \FB
source code. Generate both (PDF-file and HTML-tree) by executing

~~~{.txt}
make doc
~~~

Find the output in file `doxy/cmakefbc.pdf` and the HTML startpage in
file `doxy/html/index.html`. Both outputs can also get build separately
by building the targets

~~~{.txt}
make doc_pdf
make doc_htm
~~~

A further target is implemented to upload the html tree to a web
server, by executing

~~~{.txt}
make doc_www
~~~

\note The `doc_www` target needs some configuration first, since the
      target and its login needs to get specified.
