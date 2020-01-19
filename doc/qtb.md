# Using Q Testbench

## Table of Contents

* [Introduction](#Introduction)
* [Writing test scripts](#writing-test-scripts)
* [Running tests](#running-tests)
* [Example test suite](#example-test-suite)
* [Function reference](#function-reference)

## Introduction

For the purposes of qtb, a test is a lambda that takes no argument that throws an exception to signal failure of the test. Qtb organizes tests into a tree hierarchy, similar to a filesystem. The hierarchy is separate from q's context hierarchy. Paths into the tree are given by symbol lists and the root of the tree is designated by the null symbol (\`). Test cases are leaf nodes and test suites are branches (folders).

Each suite can have additonal lambdas attached to it, a `beforeAll` lambda, a `beforeEach` as well as a `afterEach` and `afterALl`. As the name suggests `beforeAll` lambdas are executed before any of the tests in the relevant suite are run and `afterAll` after all tests in the suite. Similarly, `beforeEach`/`afterEach` lambdas are run before or after each test in the suite. The `beforeEach` and `afterEach` functions cascade down the tree, i.e. for tests in a sub-suite all beforeEaches that are defined in the enclosing suites will be run as well as all afterEaches.

The purpose of the `beforeAll`/`beforeEach` and `afterAll`/`afterEach` lambdas is to allow the user to create and clean up test fixtures. In addition, suites can also have an override definition (commonly called "mocks"). Overrides are given as dictionaries where the keys provide the fully qualified variable names and the values the new value for each target variable to be set. qtb will reset the variables targetd by overrides to the value given by the dictionary for each individual test the suite is attached to. Similar to the `xxxEach` setup functions, overrides propagate down into subsuites. It is possible to set specific values for q's special values in the .z context, even if they are not normally defined. The override function is prepared to handle them appropriately.

In order to use qtb, the `qtb.q` script has to be loaded from the test script before any test is defined. The root of the test hierarchy is defined implicitly, all other suites have to be declared explicitly via `.qtb.suite`. This function takes a symbol list as argument; the path of the new suite. All path elements except the last one must exist, and the last one must not exist at the time of invoking .qtb.suite. Once a suite (branch) has been created, test cases and other suites can be added to it via `.qtb.addTest`.

The tests can then be executed from within the q session via `.qtb.execute`. Alternatively they can be automatically run by calling `.qtb.run[]` at the end of the script and running the test script while passing `-qtb-run` on the command-line. All test cases defined in the script will then be run automatically.

## Writing test scripts

A test script should load the `qtb.q` script as well as the actual production code it is targeting before declaring any tests. If desired, individual tests can then be added to the root test suite by calling

    .qtb.addTest[`test;{[] ...}];

Overrides, beforeAll, beforeEach, afterEach and afterAll scripts can also be added by calling the relevant insertion functions. The following defines some overrides and special handlers in the root test suite, i.e. these will apply to all tests.

    .qtb.overrides[`;<dict>];
    .qtb.addBeforeAll[`;{[] ...}];
    .qtb.addBeforeEach[`;{[] ...}];
    .qtb.addAfterEach[`;{[] ...}];
    .qtb.addAfterAll[`;{[] ...}];

Subsuites are declared by calling:

    .qtb.suite`suitename;

The suites can be nested as deeply as desired:

    .qtb.suite`sometests;
    .qtb.suite`sometests`subtests;
    .qtb.suite`sometests`subtests`subsubtests;
    .qtb.suite`sometests`othertests;

When tests are excuted, any return value from the test is ignored. It is considered successful when no exception is thrown. qtb also ignores any return values from beforeall et al. functions. However, if any of them throw an exception it will be trapped in the same way as for regular test cases and mark the test cases within its scope as `broken`. If a beforeX function raises an exception, none of the associated tests or subsuites are run and the afterX functions are also skipped.

## Running tests

After all suites and tests have been declared, the user can call `.qtb.run[]` at the end of the script. This will parse the command-line arguments of the script and automatically start executing tests if the flag `-qtb-run` is given on the command-line. The automated execution will only be triggered when script has been run directly from the commandline with the flag present, e.g.:

    ~ $ q <mytests>.q -qtb-run

Alternatively the test script can be loaded into a q session, either via `\l` or by omitting the `-qtb-run` argument. In that case, test execution can be triggered by calling

    q).qtb.execute[]

When triggered, qtb will start at the root of the hierarchy, apply overrides, call beforeAll/beforeEach and afterEach/afterAll as appropriate while executing tests and collecting the results.

By default, qtb will catch and report exceptions that are thrown from the test lambdas. While running qtb interactively from a q session, this can be disabled by running:

    q).qtb.executeDebug[]

instead of `.qtb.execute`. In case of an exception the standard q debugger will be invoked.

It is also possible to limit the execution to a specific suite or test by passing the path as a symbol list:

    q).qtb.execute`sometest`subtests

or

    q).qtb.execute`somtests`mytest

`.qtb.executeDebug` can similarly be limited in execution scope. Note that all overrides and test setup/teardown lambdas in outside of the target test scope will still be applied or executed, respectively.

.qtb.execute returns a table describing the results of all test executed:

    q)r:.qtb.execute[]
    .............
    q)r
    path                      result    time    
    --------------------------------------------
     registerFunc ok          succeeded 0.000235
     registerFunc undefined   succeeded 0.000264
     registerFunc notafunc    succeeded 0.000162
     registerFunc argmismatch succeeded 0.000212
     deregister   remove      succeeded 0.000274
     ...

This will allow the user to quickly find any test that failed for further debugging.


## Asserts

Any unit tests executes some production code and makes assertions over the outcome, either the return value or any observable side-effects. For convenience qtb offers a set of pre-defined assertion functions that throw a reasonably descriptive error message:

    .qtb.assert.matches[expected;actual]
    .qtb.assert.equals[expected;actual]
    .qtb.assert.within[<actual value>;<range as accepted by the within operator>]
    .qtb.assert.like[<observed symbol or string>;<string pattern as accepted by the like operator>]
    .qtb.assert.throws[<expression that eval accepts>;<like pattern for the exception expected to be thrown>]

It is not mandatory to use any of the .qtb.assert.* functions; any exception will fail the test.

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


As can be seen from the code, the function has a few different code paths and modifies global variables. So therefore we will want to call it for testing purposes with different states of the outside world. That means we will have different tests for the same function with similar but not quite identical setups. We therefore create a test suite:

    .qtb.suite`processRegistration;

Note: all code described here can be found in `msglib/test-msgsrv.q` from line 10ff.

The function calls the `isValidHandle` function and reads and manipulates the `CONNS` global table. We will want to change the behavior of the function or the data in the table to suit our test purposes, so best we add overrides for them:

    .qtb.setOverrides[`processRegistration;`isValidConnHandle`CONNS!({[ignore] 1b};0#CONNS)];

Now we can add our first test:

    .qtb.addTest[`processRegistration`successful_add;{[]
      .qtb.assert.matches[1b;processRegistration[22;`me]];
      .qtb.assert.matches[([primaryAddress:el `me] clientHandle:el 22i);CONNS];
      .qtb.assert.matches[([] functionName:``lg; arguments:((::);"Registering client with primary address me"));.qtb.getFuncallLog[]];
      }];

This declares the test `successful_add` in the `processRegistration` test suite.  When run, this test will call `processRegistration` with the handle number 22 and `` `me`` as arguments. The  `CONNS`  table will be empty and `isValidConnHandle` will return true.

In this test case we expect the registration to succeed, that the arguments provided to the function are stored in the `CONNS` table and that the function writes a log message. Note that the log function `lg` has been overriden at the root level of the test tree to not output anything, but to record all calls with their arguments. Qtb provides helper functions that make it easy to create no-op replacement functions that just record their invocation arguments. These calls are logged in a table and can be retrieved via `.qtb.getFuncalllog[]`. Please see the Reference section in this document for a full description of these functions.

We are using `.qtb.assert.matches`  to verify the expected side-effects, i.e. the modification of the CONNS table and the log call.

The next test in the suite `duplicate` checks the behavior in case of a duplicate registration, i.e. a secondary call with the same connection handle and primary address.

    .qtb.addTest[`processRegistration`duplicate;{[]
      .qtb.override[`CONNS;([primaryAddress:el `me] clientHandle:el 22)];
      .qtb.assert.matches[1b;processRegistration[22;`me]];
      .qtb.assert.matches[([primaryAddress:el `me] clientHandle:el 22);CONNS];
      .qtb.assert.matches[([] functionName:``lg; arguments:((::);"Re-registration from client me"));.qtb.getFuncallLog[]];
      }];

This is only a slight variation from the initial test, all we have to change is the contents of the `CONNS` table to create the conflicting primary address and adjust the expected side-effects. We use the `.qtb.override` helper function to get the CONNS table to the right initial state.

The next test checks that a registration for a pre-existing primary address where the old handle turns out to be invalid is handled properly. We modify the `isValidHandle` function to return false. We also have to override the `connectionDropped` function from `msgsrv.q` because it is automatically called by `processRegistration` if an invalid handle is detected.

    .qtb.addTest[`processRegistration`replace;{[]
      .qtb.override[`CONNS;([primaryAddress:el `me] clientHandle:el 22)];
      .qtb.override[`connectionDropped;.qtb.callLogNoret`connectionDropped];
      .qtb.override[`isValidConnHandle;{[ignore] 0b}];
      .qtb.assert.matches[1b;processRegistration[23;`me]];
      .qtb.assert.matches[([primaryAddress:el `me] clientHandle:el 23);CONNS];
      .qtb.assert.matches[([] functionName:``lg`connectionDropped;
			      arguments:((::);"Warning: Found invalid handle for primary address me, replacing registration";enlist 22));
			  .qtb.getFuncallLog[]];
      }];

Another test confirms that the registration fails if an existing one under the respective name is detected. For this thet we have to provide a matching entry in the `CONNS` table, which we do via `.qtb.override`:

    .qtb.addTest[`processRegistration`clash;{[]
      .qtb.override[`CONNS;conns:([primaryAddress:el `me] clientHandle:el 22)];

      .qtb.assert.matches[0b;processRegistration[33;`me]];
      .qtb.assert.matches[conns;CONNS];
      .qtb.assert.matches[([] functionName:``lg; arguments:((::);"Failed registration for primary address me"));
			  .qtb.getFuncallLog[]];
      }];

The last test confirms that we are correctly handling the edge case of a null address registration, which we consider invalid. 

    .qtb.addTest[`processRegistration`nulladdr;{[]
      .qtb.assert.matches[0b;processRegistration[22;`]];
      .qtb.assert.matches[([] functionName:``lg; arguments:((::);"regQuest for null (invalid) handle"));
			  .qtb.getFuncallLog[]];
      }];


We can now run the suite to make sure everything works as expected:

    q)\l test-msgsrv.q
    q).qtb.execute`processRegistration
    .....
    path                                result    time    
    ------------------------------------------------------
     processRegistration successful_add succeeded 0.000268
     processRegistration duplicate      succeeded 0.000249
     processRegistration replace        succeeded 0.000587
     processRegistration clash          succeeded 0.000219
     processRegistration nulladdr       succeeded 0.000163
    q)

Or from the command line:

    ~ $ q test-msgsrv.q -qtb-run
    KDB+ 3.6 2018.05.17 Copyright (C) 1993-2018 Kx Systems
    l32/ 4()core 7858MB klaas folio 127.0.1.1 NONEXPIRE  

    ...................
    klaas@folio:~/Projects/qtb/main/msglib$

Note that test-msgsrv.q includes other tests and there is no means to restrict the test execution scope from the command-line.

When run from the command-line, the test runner can also write the test results to a file in junit xml format, which is understood by most continuous integration system:

    ~ $ q test-msgsrv.q -q -qtb-run -qtb-junit tests.xml
    ...................
    ~ $ head tests.xml
    <?xml version="1.0" encoding="UTF-8"?>
    <testsuites>
      <testsuite name=".processRegistration" package="" hostname="folio" errors="0" failures="0" tests="5" timestamp="2020-01-17T23:44:20" time="0.001">
	<properties />
	<testcase name="successful_add" classname="" time="0.000" />
	<testcase name="duplicate" classname="" time="0.000" />
	<testcase name="replace" classname="" time="0.000" />
	<testcase name="clash" classname="" time="0.000" />
	<testcase name="nulladdr" classname="" time="0.000" />
	<system-out />


## Function reference

### Test suite and test case declaration

`.qtb.suite`

Takes one argument, a symbol or list identifying the path and name of test suite to be created. Will throw an error if the target suite aready exists or any intermediate test suite in the path does not exist.


`.qtb.addTest`

Must be called with two arguments, a path into a test suite and a lambda that is to executed as that test. As long as the function does not throw an exception, the test is considered successful.


`.qtb.addBeforeAll`
`.qtb.addAfterAll`
`.qtb.addBeforeEach`
`.qtb.addAfterEach`
`.qtb.setOverrides`

All of these functions bar `setOverrides` expect a path and a lambda as arguments. The path must resolve to an existing test suite. The lambda will be called at the relevant point in the test execution cycle. Any return value is ignored and an exception marks all test cases in that suite as "broken".

Instead of a lambda, setOverrides expectes a dictionary the the symbol keys designate global variables (including fuctions) and the values provide the value that each symbol should resolve to during the execution of the respective test suite. The values are re-assigned before each test case within the scope of the suite. The target variables may be any valid global, i.e. values or lambdas in the root context (`` `x ``) or any subcontext (`` `.my.test.data``).

The target variables may or may not exist. In either case, qtb will revert the state of each target to the state it had before the test execution started after the execution of all test cases within the scope of the target test suite completes. This extends to `.z` special variables, which will be properly expunged (by calling `system "x .z.XX"` if necessary).

### Test case construction

`.qtb.override`

Requires a symbol and an override value. Allows to override individual global variables at the time of invocation, i.e. to apply overrides while executing a test case.


`.qtb.logFuncall`
`.qtb.getFuncallLog`
`.qtb.emptyFuncallLog`
`.qtb.resetFuncallLog`

This provides generic machinery to record calls to overriden (mocked) functions in a consolidated manner. It will allow the test case to verify that the expected other functions are called, with the expected arguments and in the right order. `.qtb.logFuncall` requires a symbol and a list as arguments and records the values in an internal table for later retrieval via `.qtb.getFuncallLog`. Here is the schema of the table:

    ([] functionName:`$(); arguments:())

Note that qtb ensures that the first row in this table is a sentinel entry (functionName = \` and arguments = (::)) to avoid any kind of automatic type promotion of columns. This empty table is returned by `.qtb.emptyFuncallLog`, which takes no arguments.

The sentinel needs to be taken into account when creating an expected log of subfunction calls for a particular test case. So if no subfunction calls are expected, the assertion to check is:

    .qtb.getFuncallLog[] ~ .qtb.emptyFuncallLog[]

The call log is automatically flushed after each individual test case. If necessary, this can be done manually by calling `.qtb.resetFuncallLog`.

### Automatic call recording

qtb provides functions to generate override functions that automatically record their invocation arguments in the call log described in the previous section. Typically the generated function becomes a override value in the dictionary passed to `.qtb.setOverrides` or as the second argument to `.qtb.override`.


.qtb.callLogNoret

The simplest override function just records its invocation and arguments but otherwise does nothing. It can be easily generated via `.qtb.callLogNoret`, which only takes the name of the target function as an argument. 


.qtb.callLogSimple

Another freqently occurring situation is that the override function should simply return a particular value, regardless of its arguments. Such a lamdba can be created by calling `.qtb.callLogSimple` and giving it the name of the target function and the return value as arguments.  The return value may be anything that is not a function (q type >= 100h).

.qtb.callLog

If the override function needs to perform some computation, a lambda performing this it can be wrapped via .qtb.callLog to record its invocation first. `.qtb.callLog` takes the target function identifier as first argument and the relevant lambda as the second.

.qtb.callLogComplex

All callLog* functions described above take the name of the target function as the first argument and use that as the functionName value when logging invocations. Note that the implementation uses .qtb.countargs (see below) to ensure that the generated function takes the same number of arguments as the original. However, sometimes countargs is not able to determine the correct valence of the target; for example for q builtin functions.  In that case, `.qtb.callLogComplex` can be used to generate the wrapped function. It requires three arguments, the target function name, the override function lambda or standard return value and the valence of the target function as a third.


.qtb.countargs

This is a helper function that tries to determine the number of arguments a given lambda takes. It also supports projections. However, it cannot deal with q's builtin functions or functions from binary plugins. `.qtb.countargs` simply takes the function body as argument and returns a number or throws an exception.

### Assertions

As mentioned in the introduction, .qtb provides a few asserts as convenience functions. The most important ones are clearly `.qtb.assert.matches` and `.qtb.assert.throws`. The first confirms that the first arguement is identicaly to the second using q's `~` operator. For the error reporting the first argument is considered the expected value and the second the actual value. `.qtb.assert.throws` takes a expression tree that can be passed to q's eval function, runs it under protected evaluation and confirms that the exception that is thrown matches is second argument using the `like` operator. Note that `eval` can be run directly on the return value of `parse`. Note that literal symbols in the expression tree that are literals (i.e. are to be taken as symbol values instead as references to others) have to be escaped by enlisting them. For example, "`x,`y" will become `(,;enlist`x;enlist`y)`.

In addtion to matches and throws, .qtb also provides three other assertion functions, equals, within and like. These use the respective q function for comparing the expected and actual values.


### Command-line argument processing

.qtb.run

.qtb.run should be called at the end of a test script. It will process the command-line arguments when the script is run and start the test execution if requested.

Command-line arguments recognized:

* `-qtb-run`: Automatically execute all tests and exit
* `-qtb-verbose`: Provide more debugging output while executing tests
* `-qtb-debug`: Execute all tests and stop in the debugger when the first exception is throw. If no exception is thrown, don't exit. Passing `-e 1` on the command-line is synonymous with -qtb-debug.
* `-qtb-junit <filename>`: Write a junit-compatible xml file with the test results.
   
