# Writing Unit Tests with QTB

## Table of Contents

* [Introduction](#intro)
* [Overview over QTB](#overview)
* [Using qtb.q](#using_qtb)
  + [Core functions](#core_functions)
  + [Support functions](#support_functions)
    - [matchValue](#matchvalue)
    - [catchX](#catchx)
    - [checkX](#checkx)
    - [Logging of function calls](#funcalllogging)
* [Sample Project with Unit Tests](#sample_project)
  + [Live unit test example](#live_example)
    - [Suite setup](#example_suite_setup)
    - [Unit tests](#example_unit_tests)

<a name="intro">
## Introduction
</a>

The Q Test Bench is a framework/platform/utility (pick any overused
buzzword of your liking) to simplify the creation of unit tests in Q,
similar to Java's Junit or C#'s Nunit. It is based on ideas
implemented in Simon Garland's k4unit.q (see
[code.kx.com](http://code.kx.com/wiki/Contrib#Simon_Garland).  I
created the Q Test Bench (qtb) to better support my own personal style
of writing unit tests.

It is my conviction that any serious programming project should be
executed with the help of unit tests. Serious here means anything that
is meant to be used for more than a few times or that is not trivial
to implement. Anything that is expected to be used in production
certainly falls into this category.

From my reading of various sources, online and on dead trees, the
definition of unit tests seems to be fairly uncontroversial. However,
for the sake of clarity, here is what I have in mind when I use the
term "unit test".

A unit test is a program that executes a defined component (a function
or class method) of a project's body of code and determines if the
output of the component is consistent with the behavior expected from
that component for the inputs provided by the unit test. Usually
any function of the final deliverable will be covered by a number of
unit tests.

Unit tests are an integral part of the source code of a project and
are committed to the code repository alongside the code that delivers
desired features of the project. There should be some way to run all
unit tests of the project with one command, for example via a separate
target in the project's makefile. It is good practice to execute all
unit tests during a full build of the project and to stop the build if
any of them breaks.

The unit tests help to create and maintain the final deliverable of
the project as received by the user, but are usually not part of it.

Each unit test tests its target function _in isolation_ from all other
functions of the project and also from external dependencies, for
example server processes that are not created during the tests
execution time.  The assumption is that all other functions do perform
their task in accordance with the expectations embedded in the target
function (In other words: In accordance with the other
function's interface and contract).

I tend to think of a unit test as taking a component of a larger
machine, e.g. a CPU chip or a motor, putting it into a test jig that
supplies power and any other necessary inputs to elicit a certain
result and then observing that the expected result is indeed the
outcome of the given inputs.

Manual "unit testing" usually does the same, but in a less structured
and certainly not repeatable fashion.

Each unit test must be self-contained that it can be re-run any number
of times with the same result. It will provide the same result on any
machine that can run the development environment and it will not
require resources than memory, CPU time, file storage and loopback
networking. Essentially, it must be possible to put a fresh checkout
of the source tree onto a laptop and run all unit tests while
disconnected from the network.

Many people have written about why you should have unit tests. One
recent article is
["I scream, you scream, we all scream for unit tests"](http://mattspitz.me/post/16397940902/i-scream-you-scream-we-all-scream-for-unit-tests).  OOP-Programmers can find some good tips in the book
["The Art of Unit Testing"](http://www.manning.com/osherove/). Another
article from a recent convert is
["The Logic of Testing and the Testing of Logic"](http://www.melbourne.co.uk/blog/2012/05/24/the-logic-of-testing-and-the-testing-of-logic/).

<a name="howiwrite">
### How I Write Unit Tests
</a>

The purists of agile programming tend to advocate that the unit test
should be written before the code that delivers the desired
functionality. The unit tests are put together first and will all fail
when run. They are then "debugged" by adding the missing features. The
cycle is complete when all unit tests pass, i.e. all targeted features
have been implemented.

From a theoretical standpoint this makes sense, but in practice it
does not work for me. When I go into a significant development effort,
I do not know at the beginning how I will divide things up into
separate functions or how their interfaces will look like. Sometimes I
make radical changes or factor out and consolidate code. As I get
deeper into the problem space, I sometimes discover constraints or
otherwise revise and refine the requirements, again prompting heavy
revisions of the existing code. This means that the implementation
tends to be fluid until I get close to the finish line.

With this approach it is impractical for me to set up the unit tests
before the code is written. At the start of the project or cycle I
just don't know how the finished code will look like. Furthermore, my
unit tests are designed to automate the testing that I used to do
manually. The tests are "white box" tests, designed to follow specific
execution paths in the code.

However, as I said at the beginning, I do believe that unit tests are
mandatory. Once I have created the main body of code I switch over to
creating unit tests for each function. This tends to be the tedious
part of the job, but it is well worth the effort. Lots of ink has been
spilled on the benefits of having unit tests, so I won't repeat them
here.

After having finished writing the main code, I revisit each function
and first consider if there really needs to be covered by unit
tests. I don't create unit tests for functions that are trivial and
obviously correct. The classic example for such trivial functions
are getters and setters that are typical for OOP languages.

Declaring a function to be trivial is a judgment call. Anything that
has a conditional, including throwing or catching an exception, is
clearly not trivial. So is anything with side-effects or dependencies
on other parts of the program. Also, if a bug is discovered in the
function it is clearly not correct and requires its own unit tests,
including one for the bug.

As mentioned before, the unit tests for a particular function will try
to cover all possible execution paths. This means creating tests so
that the branch in each conditional (including loops) as well as
exception handlers is executed at least once. In most cases all tests
for the function are put into the same test suite because they share a
lot of the infrastructure for test setup, results validation and
cleanup.

Creating unit tests for pure functions that have no side-effects or
call other functions of the program is usually straightforward. All
variants in the behavior of the function can be reached by varying
the arguments passed in. As it is a pure function, all we need to
validate that the return value is the expected one.

A lot more work has to be done when the target function has
dependencies on libraries or other functions. To test it in isolation,
all these external functions have to replaced so that the test can
control the results and effects that the function under test sees. The
technical terms in the literature are to "stub" or to "mock"
sub-functions. I think the distinction is not that important in
practice, at least not for functional programming languages.

In Q it is easy to redefine a function at any point in time during a
program's runtime because functions (lambdas) are first class data
objects in Q. It is also possible (though not recommended for production
code) to redefine core Q operators or functions with some fiddling.

The replacement functions are usually simple, the most complex I have
had to set up was a large conditional that lets the arguments passed
in drive the return value if the function is called repeatedly. Given
that we know for each unit test what the inputs are we can also derive
how any subfunction will (should) be called. If something unexpected is
received, the stub/mock simply fails the test by throwing an
exception.

The Q Test Bench provides features that help simplify or remove
tedious setup or initialization code that is necessary for the target
function to be tested. Usually a particular function is covered by
more than one unit tests, especially if the function has
side-effects. It also provides some help in tracking the side-effects
of the function under test and checking the outcomes and the result
returned by it against expectations.

<a name="overview">
## Overview over QTB
</a>

The Q test bench offers features to organize the set of unit tests
into a tree-hierarchy. Each node in the tree is either a unit test (a
leaf) or a branch (a suite). A suite contains a collection of tests
and/or additional sub-suites. The tree is closely modeled on the Unix
filesystem. Each node has a name that is unique within the enclosing
suite. Subsuites have to be created explicitly before tests are added
to them. From the perspective of the test bench, tests are simply
lambdas that take no arguments and that return either true or false.

The path to a given node in the tree is designated by a symbol list
that contains the name of each node in the path as a symbol. The test
bench can execute all tests in the tree or a selected suite, as
directed by the path given as a parameter.

The test bench provides a function to execute all or a certain sub-tree
of all unit tests that are defined. QTB will iterate from the root of
the tree through all sub-suites and execute any test it finds. It is a
breadth-first execution.

QTB recognizes certain special node types in the tree that help with
factoring out repeated initialization or cleanup code and ensure that
each of them is executed at the appropriate time.

Any QTB test suite, including the root node, can have certain special
nodes:

* _before all_
* _before each_
* _after each_
* _after all_

The special nodes are not named, only the suite that they are part of
is designated when they are created. The value of these special nodes
is again a lambda with no arguments. As the name suggests, the _before
all_ node of a suite is executed once before all tests within the
suite. The _before each_ node is executed repeatedly, every time
before a unit test contained in the suite is being run. Similarly, the
_after each_ function is executed repeatedly after each unit test
execution. The _after all_ node is executed once after the end of all
unit test runs. Any return value from these special nodes is ignored.

The purpose of the special nodes is to provide facilities to factor
out setup and cleanup functions that are common to all unit tests in
the suite. The boundaries between before all and before each (or after
each/all) is not well-defined, usually it is possible to put all
actions that are part of before all also into before each.

When only a sub-tree of the unit tests is run, all special nodes along
the path are executed by the framework at the appropriate point in
time, including the special nodes at a higher level from the targeted
sub-tree. Specifically, the beforeAll functions are executed before any
subsuites are touched. Similarly, the afterAll functions are run at
the appropriate point in time.

The before- and afterEach functions are inherited along a path in the
tree. In other words, when executing tests, the test bench will
execute all before- and afterEach functions that were encountered on
the along the path from the tree root, including the ones defined
in the same suite as the tests being executed. The \*Each nodes are
cumulative, whereas the \*All functions are not.

When a unit test function is executed, it is expected to return either
true or false (`1b` or `0b`). Any other return value, including any
exception being thrown causes qtb to consider the test to have
failed. If a before all or before each node throws an exception, none
of the tests in the affected suite are run and counted as failed,
including the tests of any sub-suites. If an exception is thrown in a
after each or after all function, only a warning message is printed,
but the test results are not affected.

<a name="using_qtb">
## Using qtb.q
</a>

In order to utilize the Q Test Bench, a script must load the qtb.q
file via \\l. This file is self-contained, it provides all code that is
necessary. I tend to separate the unit tests for the production script
into a new file. This file loads the production code and qtb.q and
then defines the required tests and suites.

<a name="core_functions">
### Core functions
</a>

QTB maintains only one tree of tests per session, all tests live in
the same tree. The tree is initialized to have a root suite.

New suites (sub-trees) are created by calling `.qtb.suite` and passing
a symbol list with the suite path as an argument. The last element of
the symbol list provided defines the name of the new suite. The full
path must be specified and an error is thrown when any intermediate
path element does not exist. Conversely, it is an error to create an
existing suite a second time.

Test are added to the tree by calling `.qtb.addTest`, which takes two
parameters. The first argument gives the name and path of the suite as
a symbol list, the second the test lambda. As when creating suites,
the last element of the path provides the name of the test, which must
not exist.

Example:

    .qtb.suite`myfunc;
    .qtb.addTest[`myfunc`normal;{[] ... }];
    .qtb.addTest[`myfunc`error;{[] ... }];

This script creates the test suite myfunc and adds two tests to it,
normal and error.

Once the test tree has been set up, tests are executed by calling
`.qtb.execute`. `.qtb.execute` takes one optional argument, the path to
the sub-tree of tests that are to be executed. If no argument is given,
all tests in the tree are executed. The path argument may designate a
single test to run. `.qtb.execute` will either return `1b` if all unit
tests that were executed were successful or `0b` if any one of them
returned an error or threw an exception. It will also print a log of
the tests and special functions that it runs to stdout.

By default, qtb will catch exceptions that are thrown from the unit
tests. This can be avoided by calling `.qtb.executeDebug` for
debugging. When run via executeDebug, no execeptions are being caught
by qtb, thus allowing the first exception to bubble up to the q
prompt so that the error can be investigated more easily.

Any of the special nodes are added to a suite via the functions

    .qtb.addBeforeAll[`pa`th;{[] ...}]
    .qtb.addBeforeEach[`pa`th;func]
    .qtb.addAfterEach[`pa`th;func]
    .qtb.addAfterAll[`pa`th;func]

Each of these functions take two arguments; the first is the path to
the suite they apply to as a symbol list, the second the lambda that
is to be called during test execution.  It is possible to add special
nodes (and tests) to the root suite. The root suite is designated with
a null symbol as the path.

<a name="support_funcs">
### Support functions
</a>

In addition to the core functions for building the test tree and
executing tests, qtb provides some supporting functions that simplify
writing unit tests. When writing unit tests, certain patterns tend to
occur frequently in unit test code. These functions stand alone, it is
not mandatory to use them with the core tree-related functions
explained above.

<a name="matchvalue">
#### matchValue
</a>

When checking return values or variables changed as a side-effect of
the function being tested. `.qtb.matchValue` provides a standard way of
performing this match. matchValue takes three arguments, the first is
a designator string, the second is the expected value and the last one
actual value. The designator string is purely for human consumption, it is
meant to provide a reference for the programmer as to which variable did not
take its expected value.

`matchValue` will simply us the q `~` operator to compare the second and
third arguments. If the result is false, an error message is printed
to stdout, prefixed with the designator string from the first
argument. matchValue uses `-3!` to generate string representations
of the expected and actual values when generating the error
message. No output is written when a match is observed.

<a name="catchx">
#### catchX
</a>

`.qtb.catchX` will call a function (lambda) with the given list of
arguments and catch any exception generated from that invocation.
catchX returns a list with two elements. The first is either the
symbol ```success`` or the symbol ``excptn`, indicating whether the
execution of the function resulted in an exception or not. If there
was no exception, the second element will contain the result returned
by the function. When an exception is thrown, the second element
provides the string of the exception.

<a name="checkx">
#### checkX
</a>

In most cases, a unit test catches an exception to confirm that it
actually occurred and that it was the right one. `.qtb.checkX` is built
on top of `.qtb.catchX` and provides that functionality. checkX takes
three arguments. The first two are as for catchX, the third is the
string of the exception being expected.

If the expected exception occurs, checkX will not write and messages
to stdout and return 1b. In all other cases, checkX will write an
error message and return 0b.

<a name="funcalllogging">
#### Logging of function calls
</a>

As mentioned in the introduction, I write unit tests so that each
function being tested (the target function) is tested largely in
isolation of functions it depends upon. This means that all
non-trivial functions that the target function can call during a
particular test have to be replaced by stub or mock functions.

In the simplest form, the stub function can be written so that it
processes its arguments only to the extent necessary to determine
which pre-determined value to return so that the test progresses in
the right direction. However, I find it usually desirable to log each
invocation of sub-functions of the test target and have the unit test
assert that the function has been invoked the expected number of times
with the expected arguments at each point. This provides a degree of
certainty that the target function behaved as expected.

QTB provides the function `.qtb.wrapLogCall` that wraps another function
so that the arguments that are passed into the function when invoked
are recorded in an internal table. After that, the original function
is invoked as normal and the result returned back to the caller. This
provides a common means of tracking function invocations and
evaluating them after the fact. The result of wrapLogCall is a new
function that can be used to override a function called by the test
target.

In other words, the function passed into wrapLogCall provides the
unique behavior of the stub, for example checking its arguments and
returning different results for specific cases. wrapLogCall just
enhances it with the argument logging facilities, avoiding the need to
code them explicitly into each stub.

The first argument to wrapLogCall is a symbol with the name or
identifier of the function being wrapped. This identifier will be used
to record the function calls in the internal tracking table. The
tracking table is a global table and thus shared between all functions
that are wrapped. Therefore, the tracking table must be explicitly
cleaned before each individual test via `.qtb.resetFuncallLog`, otherwise
log entries from other unit tests will pollute the log of function
calls done by the current tests.

The current state of the tracking table can be retrieved via
`.qtb.getFuncallLog[]`. This returns a copy of the tracking table, which
has two columns, functionName and arguments. The functionName column
is populated from the name symbol argument given to wrapLogCall.
Typically the name symbol given to wrapLogCall is the name of the
function that is being overridden with it. The arguments column
receives a list with the values of all arguments as they have been
passed in.

In order to stop any automatic type promotion the empty log table is
always populated with one row that has `` ` `` as the function name and the
identity object `::` as the value. getFuncallLog[] returns the log table
with this stub entry included.

Generally, wrapLogCall and its friends are used in the following
pattern for a single test. The function f is the function being
tested. It is expected that it calls the functions sfa an d sfb
(subfunction a and b) for this particular test.

1. Test setup, including a call to .qtb.resetFuncallLog;

2. Override relevant functions called by the test target, e.g.

        sfa::.qtb.wrapLogCall[`sfa;{[x;y] ...}];
        sfb::.qtb.wrapLogCall[`sfb;{[a;b;c] ...}];

3. Invoke the target function, which in turn will call sfa and sfb:

        f[...]

4. Checking of the target function's return value and other outputs, including
   the function call log via something like:

        ([] functionName:``sfa`sfb; arguments:((::);(1;`example);(1b;0Nf;19))) ~ .qtb.getFuncallLog[]

<a name="sample_project">
## Sample Project with Unit Tests
</a>

As a demonstration of how the Q Test Bench can be used (and also as a
"dogfooding" exercise) I implemented a separate project and used qtb
for writing all the unit tests.

The project is to write a messaging server in q that simplifies the
messaging between processes. A process is dedicated to forwarding
messages between separate q processes and each client process is
relieved of the connection management requirements. Instead, each
client process maintains only a connection to the forwarding agent.
This connection is hidden inside a client library that is loaded and
initialized. Communication partners are no longer designated by the
host and port but instead via symbolic name that must be unique across
all clients of the forwarding agent. It is the responsibility of the
system administrator to ensure that all names are unique.

This relieves the client code to deal with connection handling and
basic message validation. All other processes in the system can be
reached just by sending a message to the correct address. Message
reception is implemented in Erlang-style, meaning that the incoming
messages are queued and the client code has to explicitly ask for the
next one.

The implementation of this system is split into three parts. One
script, `msgsrvr.q`, implements the forwarding agent and is a
standalone program. The client (`msgclient.q`) is a script that
expects to be loaded into another q program. Both server and client
share the library "`dispatch.q`". This module dispatches messages,
i.e. it inspects the message and calls the handler function defined
for the type of message.

The unit tests for each component are defined in separate scripts,
`test-dispatch.q`, `test-msgsrv.q` and `test-msgclient.q`. Each of
them loads the script it is targeted at from the same directory.

<a name="live_example">
### Live unit test example
</a>

As a real-world example on how to write and run unit tests with qtb we
describe the unit tests for the function `receiveMsg` in
`msgsrvr.q`. As mentioned above, the unit tests for this function live
in `test-msgsrv.q`.

Below is the definition of the function in `msgsrvr.q`.  It is
responsible for processing incoming messages in the messaging server.

    receiveMsg:{[ch;msg]
      lg "Received msg ",(-3!msg);
      req:$[10 = type msg; parse msg; msg];

      resp:@[{[args] (1b;) .dispatch.call@args}; first[req],ch,1 _ req; {[err] (0b;err)}];
      $[first resp;     lg "Successfully processed request, result: ",-3!last resp;
        not first resp; lg "Error evaluating request: ",last resp;
                        lg "Internal error, invalid evaluation result: ",-3!resp];
      lg "Request processing complete";
      };

The function is called from the q asynchronous message handler
`.z.ps`.  It receives the file handle of the communication socket as
the first argument and the raw message as it was received by `.z.ps`
as the second. It first logs the reception of the message and its
contents.  If the message is a string, it uses the q parse function to
turn it into a structure that can be passed to q's `eval`, i.e. a
general list where the first element is a symbol identifying the
function to call and the remainder the arguments to pass to that
function.

`receiveMsg` inserts the socket file handle on which the message came
in as the first argument to the function to be called and then uses
the library function `.dispatch.call` to process the message. The
dispatch library uses the first element of the list passed to
`.dispatch.call` to find the function to call. Each function that can
be called via `.dispatch.call` has to be registered with the
library. When registering a function to be called, the argument types
of the function (commonly called the signature) must also be defined.
`.dispatch.call` checks the arguments passed to it against this
signature and throws an exception if there is a mismatch.

`receiveMsg` catches any exception thrown from `.dispatch.call` and
logs the outcome of the call. It is designed not to throw any
exceptions of its own because it is typically called when processing
asynchronous messages where there is no obvious top level to which
exceptions can be bubbled up to.

<a name="example_suite_setup">
#### Suite setup
</a>

All unit tests for the `receiveMsg` functions are grouped together
into the suite `receiveMsg. Here are the definition of the suite and
the creation of a beforeAll special node:

    .qtb.suite`receiveMsg;
    .qtb.addBeforeAll[`receiveMsg;{[]
      lg_orig::lg;
      lg::.qtb.wrapLogCall[`lg;{[msg]}];
      dispatch_call_orig::.dispatch.call;
      .dispatch.call::.qtb.wrapLogCall[`.dispatch.call;{[args]}];
    }];

`receiveMsg` calls the functions `lg` and `.dispatch.call`. Before any
tests are executed, we preserve the original definitions in global
variables (`lg_orig` and `dispatch_call_orig`) and override each
function with a dummy that logs each invocation with the help of
`.qtb.wrapLogCall`. Once all tests are complete, we have qtb restore
the original definition of both functions in the _afterAll_ event:

    .qtb.addAfterAll[`receiveMsg;{[]
      .dispatch.call::dispatch_call_orig;
      lg::lg_orig;
    }];

Lastly, as we use logging functions provided by `.qtb.wrapLogCall` we
have qtb clean out the call log before each unit test in the suite.

    .qtb.addBeforeEach[`receiveMsg;{[] .qtb.resetFuncallLog[]; }];

<a name="example_unit_tests">
#### Unit tests
</a>

The first test, called `ok` confirms that `receiveMsg` behaves as
expected when a message is successfully received. For that purpose, it
is invoked with some arbitrary test arguments (10 and and a list with
the symbols `afunc` and `arg`. In order to confirm that the
function has performed its intended purpose, the call log of the
overridden functions is examined. We check that each overridden
function is called in the right order with the right parameters. First
we expect the function call ``lg["Received msg `afunc`arg"]``, then
``.dispatch.call[`afunc;10;`arg]``, then `lg["Successfully processed request, result: ::"]`
and lastly the call `lg["Request processing complete"]`.

The current log of all functions that have been called via a logging
wrapper from `.qtb.wrapLogCall` can be retrieved using
`.qtb.getFuncallLog`.  This function simply returns a copy of the
table where the call log is maintained. The first column provides the
name of the function that was called as a symbol. This is the symbol
that was passed into `.qtb.wrapLogCall`. The second column holds the
list of arguments. In order to ensure that there is never any
automatic type promotion of the arguments column, the empty table is
always populated with a dummy row. This dummy row is also returned
from `.qtb.getFuncallLog`, so we have a to account for it when checking
the table in the test.

We use `.qtb.matchValue` to compare the actual call log table to the
expected one. In order to do that, we have to write the expected call
log as a table.

    .qtb.addTest[`receiveMsg`ok;{[]
      receiveMsg[10;(`afunc;`arg)];
      .qtb.matchValue["Function call log";
		      ([] functionName:``lg`.dispatch.call`lg`lg;
			  arguments:((::);
				     "Received msg `afunc`arg";
				     (`afunc;10;`arg);
				     "Successfully processed request, result: ::";
				     "Request processing complete"));
		       .qtb.getFuncallLog[]]}];

`.qtb.matchValue` returns true or false depending on whether the
expected and actual values match or not. This becomes the overall
result of the test as it is the last expression in the test function.

The second unit test `error` confirms that `receiveMsg` behaves as
expected when an exception is thrown from `.dispatch.call`. For that
purpose the test overrides it with a different function from the one
used by the suite. The override function also uses the call log
wrapper, but it throws the exception "whoops!". We only use this
override for this particular unit tests so we first have to preserve
the current definition of `.dispatch.call` and restore it after
calling `receiveMsg`.

    .qtb.addTest[`receiveMsg`error;{[]
      dispatch_call_orig:.dispatch.call;
      .dispatch.call::.qtb.wrapLogCall[`.dispatch.call;{[req] '"whoops!"}];
      receiveMsg[3;(`afunc;`xx)];
      .dispatch.call::dispatch_call_orig;
      .qtb.matchValue["Function call log";
		      ([] functionName:``lg`.dispatch.call`lg`lg;
			  arguments:((::);
				     "Received msg `afunc`xx";
				     (`afunc;3;`xx);
				     "Error evaluating request: whoops!";
				     "Request processing complete"));
		       .qtb.getFuncallLog[]]}];

As in the `ok` unit test, we use `.qtb.matchValue` to inspect the
call logs and confirm that `receiveMsg` has behaved the way we want it to.

The last unit test `string` simply test the wrinkle that the
incoming message can also be a string instead of a general list and
that `receiveMsg` applies `parse` to incoming strings.

    .qtb.addTest[`receiveMsg`string;{[]
      receiveMsg[13;"afunc[`arg]"];
      .qtb.matchValue["Function call log";
		      EL::([] functionName:``lg`.dispatch.call`lg`lg;
			  arguments:((::);
				     "Received msg \"afunc[`arg]\"";
				     (`afunc;13;enlist `arg);
				     "Successfully processed request, result: ::";
				     "Request processing complete"));
		       .qtb.getFuncallLog[]]}];

Via these three unit tests, we have covered all execution paths
through `receiveMsg` except the else branch in the last conditional
`lg "Internal error, invalid evaluation result: ",-3!resp`. We have
skipped that because it is only a safety catch in case the function
itself has a serious internal bug and because there is no reasonable
way to reach that branch by manipulating the inputs to `receiveMsg`
and the subfunctions it calls.

Here is the output of qtb when running the `receiveMsg` suite:

    q)\l test-msgsrv.q
    q).qtb.execute`receiveMsg
    Executing BEFOREALL for .receiveMsg
    Executing BEFOREEACH for .receiveMsg.ok
    Test .receiveMsg.ok succeeded
    Executing BEFOREEACH for .receiveMsg.error
    Test .receiveMsg.error succeeded
    Executing BEFOREEACH for .receiveMsg.string
    Test .receiveMsg.string succeeded
    Executing AFTERALL for .receiveMsg
    Tests executed: 3
    Tests successful: 3
    Tests failed: 0
    1b
    q)
