\d .a
avar:42;
afunc:{};
\d .
l1:42;

\d .otherctx

\d .b
avar:"42";


\d .otherctx
l2:"42";

\d .c
avar:`42;

\d .d
avar:42j;
\d .c
\d .otherctx
l3:`42;

xvar:`somevalue;
\d .otherctx

// Unit tests

\d .loadtests

toString:{[v] $[10 = type v;v;string v]};

check_variableValue:{[vname;expval]
  r:@[{(0b;value x)};vname;(1b;)];
  if[first r; -1 "Variable ",string[vname]," is undefined"; :0b];
  actval:last r;
  if[not actval ~ expval;
    -1 "Variable ",string[vname]," has the wrong value. Expected: ",toString[expval],", actual: ",toString actval];
  actval ~ expval };

check_variableValues:{[]
  all check_variableValue ./: ((`.a.avar;42);(`.b.avar;"42");(`.c.avar;`42);(`.d.avar;42j);(`l1;42);(`.otherctx.l2;"42");(`.otherctx.l3;`42))
  };

match_context:{[ctxName;expMembers]
  actMembers:key[ctxName] where not null key ctxName;
  expMembers1:(),expMembers;
  missing:expMembers1 except actMembers;
  if[0 < count missing;
    -1 "Missing elements in context ",string[ctxName],": "," " sv string missing];
  unexpected:actMembers except expMembers1;
  if[0 < count unexpected;
    -1 "Unexpected members in context ",string[ctxName],": "," " sv string unexpected];
  all 0 = count each (missing;unexpected) };

check_contexts:{[]
  all match_context ./: ((`.a;`avar`afunc);(`.b;`avar);(`.c;`avar);(`.d;`avar);(`.otherctx;`l2`l3`xvar))  };

ALL:`.loadtests.check_variableValues`.loadtests.check_contexts;

\d .


/////////////////////////////////////
// Test infrastructure (in its own context)

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

/// Autorun if the script was not loaded into a running q session
\d .
if[not null .z.f;
  r:@[{[] .test.execute each .loadtests.ALL};`;{-1 "Exception while executing tests: ",x;0b}];
  if[0 > type r; exit 1]; // an exception was thrown
  -1 "Total number of tests: ",string count r;
  -1 "     Successful tests: ",string sum r;
  -1 "         Failed tests: ",string sum not r;
  exit $[all r;0;1]];
