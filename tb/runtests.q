// A simple helper script for running tests
//
// This is to bootstrap the Q test bench code, i.e. to provide some
// support for the unit tests of the test bench itself.
//
// We use a simple convention: the script loaded must provide the
// "ALLTESTS" variable. This is expected to be a list of symbols
// with the names of all test functions to run.

if[(not null .z.f) and 0 < count .z.x;
  script:first .z.x;
  @[{system "l ",x};script;{[script;msg] -2 "Failed to load ",script,": ",msg; exit 1}[script;]];
 
  @[value;`.test.execute;{[script;msg] -2 "The script ",script," does not load the testbench.q file."; exit 1}[script;]];
  @[value;`ALLTESTS;{[script;msg] -2 "The script ",script," does not provide the ALLTESTS variable."; exit 1}[script;]];
 
  -1 "Executing ",script;
 
  res:@[{[] .test.execute each ALLTESTS};
        `;
        {[script;msg] -2 "The test execution of ",script," threw an exception: ",msg; exit 1}[script;]];
 
  -1 "";
  -1 "Total number of tests executed: ",string count res;
  -1 "              Successful tests: ",string sum res;
  -1 "                  Failed tests: ",string sum not res;
  exit neg 1 + $[all res;-1 "Execution of ",script," completed successfuly";-2 "Execution of ",script," failed"]];
