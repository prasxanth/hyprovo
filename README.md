# hyprovo
**hyprovo** is a minimal (~160 LOC) testing framework for [Hy](https://github.com/hylang/hy) heavily inspired by the chapter on [Practical: Building a Unit Test Framework](https://gigamonkeys.com/book/practical-building-a-unit-test-framework.html) in [Practical Common Lisp](https://gigamonkeys.com/book/).

> provo (Esperanto) ⇔ test (English)

## Installation

Install using `setup.py` (`--user` is optional)

```bash
python3 setup.py install --user
```

or in development mode,

```bash
python3 setup.py develop --user
```

## API
See [README.ipynb](README.ipynb) for the documentation.

## Tests
Ensure `hy` is in the executable path. Run the `tests.hy` command line script from inside the [tests](tests) directory,

```bash
./tests.hy
```

A log file with the start timestamp will be created in the [logs](tests/logs) subdirectory.
