# Using Q Testbench

## Table of Contents

[Introduction](#Introduction)
[Writing test scripts](#writing-test-scripts)
[Running tests](#running-tests)
[Example test suite](#example-test-suite)
[Function reference](#function-reference)

## Introduction

For the purposes of qtb, a test is a lambda that takes no argument and returns true (1b - test succeeded) or false (0b - test failed). Qtb organizes tests into a tree hierarchy, similar to a filesystem. Paths into the tree are given by symbol lists. The root of the tree is designated by the null symbol (`` ` ``). Test cases are leaf nodes and test suites branches.

Each suite can have additonal lambdas attached to it, a `beforeAll` lambda, a `beforeEach` as well as a `afterEach` and `afterALl`. As the name suggests `beforeAll` lambdas are executed before all any tests in the relevant suite and `afterAll` after all tests in the suite have been run. Similarly, `beforeEach`/`afterEach` lambdas are run before or after each test in the suite. The `beforeEach` and `afterEach` functions cascade down the tree, i.e. for tests in a sub-suite all beforeEaches that are defined in the enclosing suites will be run as well as all afterEaches.

The purpose of the `beforeAll`/`beforeEach` and `afterAll`/`afterEach` lambdas is to allow the user to create and clean up test fixtures.

In addition, suites can also have an override definition. Overrides are given as dictionaries where the keys provide the fully qualified variable names and the values the new value for each target variable to be set. For each test within the scope of the suite the overrides are attached to, qtb will reset the target variables to the values given in the dictionary. Overrides also propagates down into subsuites.

In order to use qtb, the `qtb.q` script has to be loaded from the test script before any test is defined. The root of the test hierarchy is defined implicitly, all other suites have to be declared explicitly via `.qtb.suite`. This function takes a symbol list as argument; the path of the new suite. All path elements except the last one must exist, and the last one must not exist at the time of invoking .qtb.suite. Once a suite (branch) has been created, test cases and other suites can be added to it via `.qtb.addTest`.

The tests can then be executed from within the q session via `.qtb.execute`. Alternatively they can be automatically run by calling `.qtb.run[]` at the end of the script and passing `-qtb-run` at the command-line. The test cases defined in the script will then be run automatically.

## Writing test scripts

A test script should load the `qtb.q` script as well as the actual production code it is targeting before declaring any tests. If desired, individual tests can then be added to the root test suite by calling

    .qtb.addTest[`test;{[] ...}];

Overrides, beforeAll, beforeEach, afterEach and afterAll scripts can also be added by calling the relevant insertion functions:

    .qtb.overrides[`;<dict>];
    .qtb.addBeforeAll[`;{[] ...}];
    .qtb.addBeforeEach[`;{[] ...}];
    .qtb.addAfterEach[`;{[] ...}];
    .qtb.addAfterAll[`;{[] ...}];

Subsuites are declared by calling:

    .qtb.suite`suitename;

There suites can be nested as deeply as desired:

    .qtb.suite`sometests;
    .qtb.suite`sometests`subtests;
    .qtb.suite`sometests`subtests`subsubtests;
    .qtb.suite`sometests`othertests;

The lambda passed to `.qtb.addTest`, i.e. the actual test case code, must return either 1b for test success or 0b for test failure. Any other return value including throwing an exception is considered an error.

The return values of lambdas passed to `.qtb.addBeforeAll`, etc. are ignored during test execution. However, if a beforeXXX lambda throws an exception, all tests within its scope are skipped. The assumption is that required setup for the tests is not present for them to succeed. If an afterXXX lambda raises an exception, all the result of all affected tests is set to `` `broke``.

## Running tests

After all suites and tests have been declared, the user can call `.qtb.run[]` at the end of the script. This will parse the command-line arguments of the script and automatically start executing tests if the flag `-qtb-run` is given on the command-line. The automated execution will only be triggered when script has been run directly from the commandline with the flag present, e.g.:

    ~ $ q <mytests>.q -qtb-run

Alternatively the test script can be loaded into a q session, either via `\l` or by omitting the `-qtb-run` argument. In that case, test execution can be triggered by calling

    q).qtb.execute[]

When triggered, qtb will start at the root of the hierarchy, apply overrides, call beforeAll/beforeEach and afterEach/afterAll as appropriate while executing tests and collecting the results.

By default, qtb will catch and report exceptions that are thrown from the test lambdas. While running qtb interactively from a q session, this can be disabled by running:

    q).qtb.executeDebug[]

instead of `.qtb.execute`. In case of an exception (but not when a test fails) the standard q debugger will be invoked.

It is also possible to limit the execution to a specific suite or test by passing the path as a symbol list:

    q).qtb.execute`sometest`subtests

or

    q).qtb.execute`somtests`mytest

`.qtb.executeDebug` can similarly be limited in execution scope. Note that all overrides and test setup/teardown lambdas in outside of the target test scope will still be applied or executed, respectively.


## Example test suite

For development of qtb, I am using the msglib project as a test project to write unit tests with qtb.q (see `./msglib`). Users are encouraged to read through the spec, the implementation and the resulting unit test scripts. Please note that at this point most features listed in the spec are not implemented.

We will here walk through one particular suite for the function `processRegistration` in msglib/msgsrv.q. It handles the registration of newly connected clients, who must supply us with a uniqe identifier for themselves. The function tracks this in the CONNS global table, which is keyed by handle id.

    processRegistration:{[handle;primAddr]
      if[null primAddr;
	lg "regQuest for null (invalid) handle";
	:0b];

      registeredHandle:CONNS[primAddr;`clientHandle];
      primAddrS:string primAddr;
      if[null registeredHandle;
	lg "Registering client with primary address ",primAddrS;
	`CONNS upsert (primAddr; handle);
	:1b];

      if[isValidConnHandle registeredHandle;
	:$[handle = registeredHandle;
	   [lg "Re-registration from client ",primAddrS;             1b];
	   [lg "Failed registration for primary address ",primAddrS; 0b]]];

      lg "Warning: Found invalid handle for primary address ",primAddrS,", replacing registration";
      connectionDropped registeredHandle;
      `CONNS upsert (primAddr; handle);
      1b };


As can be seen from the code, the function has a few different code paths and modifies global data. So therefore we will want to call it for testing purposes with different states of the outside world. That means we will have different tests for the same function with similar but not quite identical setups. We therefore create a test suite:

    .qtb.suite`processRegistration;

Note: all code described here can be found in `msglib/test-msgsrv.q` from line 10ff.

The function calls the `isValidHandle` function and reads and manipulates the CONNS global table. We will want to change the behavior of the function or the data in the table to suit our test purposes, so best we add overrides for them:

    .qtb.setOverrides[`processRegistration;`isValidConnHandle`CONNS!({[ignore] 1b};0#CONNS)];

Now we can add our first test:

    .qtb.addTest[`processRegistration`successful_add;{[]
      r:processRegistration[22;`me];
      checks:(("CONNS table";([primaryAddress:el `me] clientHandle:el 22i);CONNS);
	      ("logging calls";([] functionName:``lg; arguments:((::);"Registering client with primary address me"));.qtb.getFuncallLog[]));
      all r,.qtb.matchValue ./: checks }];

This declares the test `successful_add` in the `processRegistration` test suite.  When run, this test will call `processRegistration with the handle number 22 and `` `me`` as arguments. The  `CONNS`  table will be empty and `isValidConnHandle` will return true.

In this test case we expect the registration to succeed (return value 1b), that the arguments provided to the function are stored in the `CONNS` table and that the function writes a log message. Note that the log function `lg` has been overriden at the root level of the test tree to not output anything, but to record all calls with their arguments. Qtb provides helper functions that make it easy to create no-op replacement functions that just record their invocation arguments. These calls are logged in a table and can be retrieved via `.qtb.getFuncalllog[]`. Please see the Reference section in this document for a full description of these functions.

We are using the `.qtb.matchValue` helper function to verify the expected side-effects, i.e. the modification of the CONNS table and the log call. The test function uses `all` to collapse the vector of individual check results to one final boolean return value.

The next test in the suite `duplicate` checks the behavior in case of a duplicate registration, i.e. a secondary call with the same connection handle and primary address.

    .qtb.addTest[`processRegistration`duplicate;{[]
      .qtb.override[`CONNS;([primaryAddress:el `me] clientHandle:el 22)];
      r:processRegistration[22;`me];
      checks:(("CONNS table";([primaryAddress:el `me] clientHandle:el 22);CONNS);
	      ("logging calls";([] functionName:``lg; arguments:((::);"Re-registration from client me"));.qtb.getFuncallLog[]));
      all r,.qtb.matchValue ./: checks}];

This is only a slight variation from the initial test, all we have to change is the contents of the `CONNS` table to create the conflicting primary address and adjust out expected side-effects. We use the `.qtb.override` helper function to get the CONNS table to the right initial state.

The next test checks that a registration for a pre-existing primary address where the old handle turns out to be invalid is handled properly. We modify the `isValidHandle` function to return false. We also have to override the `connectionDropped` function from `msgsrv.q` because it is automatically called by `processRegistration` if an invalid handle is detected.

    .qtb.addTest[`processRegistration`replace;{[]
      .qtb.override[`CONNS;([primaryAddress:el `me] clientHandle:el 22)];
      .qtb.override[`connectionDropped;.qtb.callLogS`connectionDropped];
      .qtb.override[`isValidConnHandle;{[ignore] 0b}];
      r:processRegistration[23;`me];
      checks:(("CONNS table";([primaryAddress:el `me] clientHandle:el 23);CONNS);
	      ("Function calls";
	      ([] functionName:``lg`connectionDropped;
		  arguments:((::);"Warning: Found invalid handle for primary address me, replacing registration";enlist 22));
	      .qtb.getFuncallLog[]));
      all r,.qtb.matchValue ./: checks }];

Another test confirms that the registration fails if an existing one under the respective name is detected. For this thet we have to provide a matching entry in the `CONNS` table, which we do via `.qtb.override`:

    .qtb.addTest[`processRegistration`clash;{[]
      .qtb.override[`CONNS;conns:([primaryAddress:el `me] clientHandle:el 22)];
 
      r:processRegistration[33;`me]; 
      checks:(("CONNS table";conns;CONNS);
              ("Funcall log";
              ([] functionName:``lg; arguments:((::);"Failed registration for primary address me"));
              .qtb.getFuncallLog[]));
      all (not r),.qtb.matchValue ./: checks}];

The last test confirms that we are correctly handling the edge case of a null address registration, which we consider invalid. 

    .qtb.addTest[`processRegistration`nulladdr;{[]
      r:processRegistration[22;`];
      all (not r),.qtb.matchValue["logging calls";
				  ([] functionName:``lg; arguments:((::);"regQuest for null (invalid) handle"));
				  .qtb.getFuncallLog[]] }];

We can now run the suite to make sure everything works as expected:

    q)\l test-msgsrv.q
    q).qtb.execute`processRegistration
    .....
    path                               result   
    --------------------------------------------
    processRegistration successful_add succeeded
    processRegistration duplicate      succeeded
    processRegistration replace        succeeded
    processRegistration clash          succeeded
    processRegistration nulladdr       succeeded
    q)

Or from the command line:

    klaas@folio:~/Projects/qtb/main/msglib$ q test-msgsrv.q -qtb-run
    KDB+ 3.6 2018.05.17 Copyright (C) 1993-2018 Kx Systems
    l32/ 4()core 7858MB klaas folio 127.0.1.1 NONEXPIRE  

    ...................
    klaas@folio:~/Projects/qtb/main/msglib$

Note that test-msgsrv.q includes other tests and there is no means to restrict the test execution scope from the command-line.

## Function reference

### Test suite and test case declaration

`.qtb.suite`

Takes one argument, a symbol or list identifying the path and name of test suite to be created. Will throw an error if the target suite aready exists or any intermediate test suite in the path does not exist.


`.qtb.addTest`

Must be called with two arguments, a path into a test suite and a lambda that is to executed as that test. The lambda must return a boolean value when called, anything else is considered an error, including exceptions.


`.qtb.addBeforeAll`
`.qtb.addAfterAll`
`.qtb.addBeforeEach`
`.qtb.addAfterEach`
`.qtb.setOverrides`

All of these functions bar `setOverrides` expect a path and a lambda as arguments. The path must resolve to an existing test suite. The lambda will be called at the relevant point in the test execution cycle. Any return value is ignored and an exception marks all test cases in that suite as "broken".

Instead of a lambda, setOverrides expectes a dictionary the the symbol keys designate global variables (including fuctions) and the values provide the value that each symbol should resolve to during the execution of the respective test suite. The values are re-assigned before each test case within the scope of the suite. The target variables may be any valid global, i.e. values or lambdas in the root context (`` `x ``) or any subcontext (`` `.my.test.data``).

The target variables may or may not exist. In either case, qtb will revert the state of each target to the state it had before the test execution started after the execution of all test cases within the scope of the target test suite completes. This extends to `.z` special variables, which will be properly expunged (by calling system "x .z.XX") if necessary.

### Test case construction

.qtb.override

Requires a symbol and an override value. Allows it to override individual global variables at the time of invocation, i.e. to apply overrides from a test case lambda.

`.qtb.logFuncall`
`.qtb.getFuncallLog`
`.qtb.emptyFuncallLog`
`.qtb.resetFuncallLog`

qtb provides generic machinery to record events in a consolidated, typical function calls. `.qtb.logFuncall` requires a symbol and a list as arguments and records the values in an internal table for later retrieval via `.qtb.getFuncallLog`. Here is the schema of the table:

    ([] functionName:`$(); arguments:())

Note that qtb ensures that the first row in this table is a sentinel entry (functionName = ` and arguments = (::)) to avoid any kind of automatic type promotion of columns. This empty table is returned by `.qtb.emptyFuncallLog`, which takes no arguments.

The sentinel needs to be taken into account when creating an expected log of subfunction calls for a particular test case. So if no subfunction calls are expected, the assertion to check is:

    .qtb.getFuncallLog[] ~ .qtb.emptyFuncallLog[]

The call log is automatically flushed after each individual test case. If necessary, this can be done manually by calling `.qtb.resetFuncallLog`.

### Automatic call recording

qtb provides functions to generate override functions that automatically record their invocation arguments in the call log described in the previous section. Typically the generated function becomes a override value in the dictionary passed to `.qtb.setOverrides` or as the second argument to `.qtb.override`.


`.qtb.callLogNoret`

The simplest override function just records its invocation and arguments but otherwise does nothing. It can be easily generated via `.qtb.callLogNoret`, which only takes the name of the target function as an argument. 


.qtb.callLogSimple

Another freqently occurring situation is that the override function should simply return a particular value, regardless of its arguments. Such a lamdba can be created by calling `.qtb.callLogSimple` and giving it the name of the target function and the return value as arguments.  The return value may be anything that is not a function (q type >= 100h).

.qtb.callLog

If the override function needs to perform some computation, a lambda performing this it can be wrapped via .qtb.callLog to record its invocation first. `.qtb.callLog` takes the target function identifier as first argument and the relevant lambda as the second.

.qtb.callLogComplex

All callLog* functions described above take the name of the target function as the first argument and use that as the functionName value when logging invocations. Note that the implementation uses .qtb.countargs (see below) to ensure that the generated function takes the same number of arguments as the original. However, sometimes countargs is not able to determine the correct valence of the target; for example for q builtin functions.  In that case, `.qtb.callLogComplex` can be used to generate the wrapped function. It requires three arguments, the target function name, the override function lambda or standard return value and the valence of the target function as a third.

### Other simple helper functions

.qtb.checkX

`.qtb.catchX` will call a function (lambda) with the given list of arguments and catch any exception generated from that invocation. `catchX` returns a list with two elements. The first is either the symbol ```success`` or the symbol ``excptn`, indicating whether the execution of the function resulted in an exception or not. If there was no exception, the second element will contain the result returned by the function. When an exception is thrown, the second element provides the string of the exception.


.qtb.catchX

In most cases, a unit test that catches an exception to confirm that it actually occurred and that it was the right one. `.qtb.checkX` is built on top of `.qtb.catchX` and provides that functionality. checkX takes three arguments. The first two are as for catchX, the third is the string of the exception being expected.

If the expected exception occurs, checkX will not write and messagesto stdout and return 1b. In all other cases, checkX will write an error message and return 0b.


.qtb.matchValue

When checking return values or variables changed as a side-effect of the function being tested. `.qtb.matchValue` provides a standard way of performing this match. matchValue takes three arguments, the first is a designator string, the second is the expected value and the last one actual value. The designator string is purely for human consumption, it is meant to provide a reference for the programmer as to which variable did not take its expected value.

`matchValue` will simply us the q `~` operator to compare the second and third arguments. If the result is false, an error message is printed to stdout, prefixed with the designator string from the first argument. matchValue uses `-3!` to generate string representations of the expected and actual values when generating the error message. No output is written when a match is observed.

.qtb.countargs

This is a helper function that tries to determine the number of arguments a given function takes. It also supports projections. However, it cannot deal with q's builtin functions or functions from plugins. `.qtb.countargs` simply takes the function body as argument and returns a number or throws an exception.


### Command-line argument processing

.qtb.run

.qtb.run should be called at the end of a test script. It will process the command-line arguments when the script is run and start the test execution if requested. The automatic test execution and termination of the script is only triggered if the script name and the necessary argument has been passed on the command-line while running q. This means that nothing will happen if the script is loaded into a running q session even if it has the right command-line argument.

Command-line arguments recognized:

* `-qtb-run`: Automatically execute all tests and exit
* `-qtb-verbose`: Provide more debugging output while executing tests
* `-qtb-debug`: Stop in the debugger when the first exception is throw.
* `-qtb-junit <filename>`: Write a junit-compatible xml file with the test results.
   
