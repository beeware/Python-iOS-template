cookiecutter-Python-iOS
=======================

A cookiecutter template for running Python apps under iOS.

Using this template
-------------------

1. Install `cookiecutter`_. This is a tool used to bootstrap complex project
   templates::

    $ pip install cookiecutter

2. Run `cookiecutter` on the Python-iOS template::

    $ cookiecutter git://github.com/pybee/cookiecutter-Python-iOS

3. Download and extract the following support frameworks:

     * `ffi.framework`_

     * `Python.framework`_

   These framework directories should be extracted in the same directory as
   the ``src`` and ``app_packages`` directories.

If you've done this correctly, a project called ``myproject`` should have a
directory structure that looks something like::

    iOS/
        app_packages/
        ffi.framework/
            ...
        Python.framework/
            ...
        myproject/
            ...
        myproject.xcodeproj/
        src/
            myproject/
                __init__.py
                main.py

You're now ready to open the XCode project file, build and run your project!

Next steps
----------

Of course, just running Python code isn't very interesting by itself - you'll
be able to output to the console, and see that output in XCode, but if you
run tap the icon on your phone, you won't see anything - because there isn't a
visible console on an iPhone.

To do something interesting, you'll need to work with the native iOS system
libraries to draw widgets and respond to screen taps.

Or, you could use a library like `toga`_ that provides a cross-platform widget
toolkit that supports iOS.

If you have any external library dependencies (like `toga`, or anything other
third-party library), you should install the library code into the
``app_packages`` directory. This directory is the same as a  ``site_packages``
directory on a desktop Python install.

It's also worth noting that the ``src`` and ``app_packages`` code don't need
to contain the **actual** code. If it's more convenient to keep the code
somewhere else, you can symlink to the actual code inside the ``src`` or
``app_packages`` directory. At compile time, the symlink will be resolved and
copied to the app bundle, but during development, you can avoid having copies
of code in your source repositories.

One pattern for doing this is to have a top level project directory that
contains the source module, and an iOS directory at the same level that
links in the project source::

    myproject/
        iOS/
           src/
               myproject -> ../../myproject
        myproject/
            __init__.py
            main.py
            other.py
        setup.py

.. _cookiecutter: http://github.com/audreyr/cookiecutter
.. _ffi.framework:
.. _Python.framework:
.. _toga: http://pybee.org/toga
