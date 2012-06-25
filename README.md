# QTB - Q Test Bench

The Q Test Bench provides supporting functions for writing unit tests
in q, the programming language of kdb+ from [Kx
Systems](http://kx.com).

The detailed documentation on how to use it can be found in
[doc/qtb.md](blob/master/doc/qtb.md).

QTB and all supporting components in this repository are licensed
under the GNU Public License v3, which can be found on the [GNU
website](https://www.gnu.org/copyleft/gpl.html).

If you want to simply use qtb for building unit tests in q there is
no need to pull the whole repository, you can simply download
[qtb.q](qtb.q) and put it into a convenient place on your machine.

# Repository Directories

consq      - Source code and unit tests for a Perl script that reads
             a q script and expands all \l expressions, i.e. it inserts
             script referenced via \l with the contents of the script file 
             in its output and removes the \l line. It thereby gets rid
             of external dependencies and creates only one script that
             can be run from any path.

doc        - Detailed documentation.

msglib     - A sample project that uses qtb for its unit tests.

qtestbench - The source of qtb.q plus associated unit tests.

tb         - Some simple helper functions used by the unit tests for qtb.