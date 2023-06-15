hyprovo
=======

**hyprovo** is a minimal (~160 LOC) testing framework for
`Hy <https://github.com/hylang/hy>`__ heavily inspired by the chapter on
`Practical: Building a Unit Test
Framework <https://gigamonkeys.com/book/practical-building-a-unit-test-framework.html>`__
in `Practical Common Lisp <https://gigamonkeys.com/book/>`__.

   provo (Esperanto) ⇔ test (English)

Installation
------------

pypi (recommended)
~~~~~~~~~~~~~~~~~~

.. code:: bash

   pip install hyprovo

Manual
~~~~~~

Install using ``setup.py`` (``--user`` is optional)

.. code:: bash

   python3 setup.py install --user

or in development mode,

.. code:: bash

   python3 setup.py develop --user

API
---

See `tutorial.ipynb <tutorial.ipynb>`__ for the documentation.

Tests
-----

Ensure ``hy`` is in the executable path. Run the ``tests.hy`` command
line script from inside the `tests <tests>`__ directory,

.. code:: bash

   ./tests.hy

A log file with the start timestamp will be created in the
`logs <tests/logs>`__ subdirectory.

--------------

GitHub Repository: https://github.com/prasxanth/hyprovo
