/////////////////////////////////////
// Test infrastructure
//
// This is to bootstrap the Q test bench code, i.e.
// to provide some support for the unit tests of the
// test bench itself.

\d .test

execute:{[testName]
  testNameS:@[{s:string x; $[10 = type s;s;'""]};testName;"???"];
  func:@[eval;testName;`];
  if[(` ~ func) or 100 > type func;
    -1 testNameS," is invalid or not a function";
    :0b];
  r:@[func;`;{[testNameS;excptn] -1 "Test ",testNameS," threw exception: ",excptn; 0b}[testNameS;]];
  -1 "Test ",testNameS,$[-1h = type r;$[r;" succeeded.";" FAILED."];" is invalid."];
  $[-1h = type r; r; 0b] };


numargs:{[f] count (value f) 1};

checkException:{[func;args;expExcept]
  arg:$[1 = numargs func; enlist args;
        (type args) within 0 20h; args;
        '"Invalid arguments"];
  r:@[{[func;args] func . args}[func;]; arg; {(`excptn;x)}];
  if[not `excptn ~ first r; :0b];
  actExcept:last r;
  ((count expExcept) <= count actExcept) and expExcept ~ (count expExcept)#actExcept };
