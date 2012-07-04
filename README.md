# QTB - Q Test Bench

The Q Test Bench provides supporting functions for writing unit tests
in q, the programming language of kdb+ from [Kx
Systems](http://kx.com).

The detailed documentation on how to use it can be found in
[doc/qtb.md](https://github.com/ktsr42/qtb/blob/master/doc/qtb.md).

QTB and all supporting components in this repository are licensed
under the GNU Public License v3, which can be found on the [GNU
website](https://www.gnu.org/copyleft/gpl.html).

If you want to simply use qtb for building unit tests in q there is
no need to pull the whole repository, you can simply download
[qtb.q](qtb.q) and put it into a convenient place on your machine.

# Repository Directories

* **consq** - Source code and unit tests for a Perl script that reads
  a q script and expands all \l expressions, i.e. it inserts script
  referenced via \l with the contents of the script file in its output
  and removes the \l line. It thereby gets rid of external dependencies
  and creates only one script that can be run from any path.

* **doc** - Detailed documentation.

* **msglib** - A sample project that uses qtb for its unit tests.

* **qtestbench** - The source of qtb.q plus associated unit tests.

* **tb** - Some simple helper functions used by the unit tests for qtb.

# Todos

Future releases may add the following features:

* Change the behaviour of `.qtb.execute` so that the failure of a
  _afterEach_ or _afterAll_ function skips all subsequent tests. The
  argument for this is that the cleanup after the first test is
  incomplete, thus potentially impacting the validity of all following
  tests.

* Add a second argument to `.qtb.suite`, a list of symbols. Each
  symbol in the list designates a global variable, including
  callbacks. `.qtb.execute` will automatically preserve the current
  value of each variable, including situations where it is
  undefined. The objective is to remove a lot of boilerplate code from
  test suites.

* Automatically call `.qtb.resetFuncallLog` before each test. This tends
  to appear in almost every test suite I have written so far, making
  it implicit will remove repetitive code.

