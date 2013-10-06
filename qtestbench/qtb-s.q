// Q Test Bench - A framework for writing unit tests in Q
//
// Copyright (C) 2012 Klaas Teschauer
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// Interface
// =========
//
// suite[pathname] - create a new suite (creates subtree)
// addTest[pathname;func] - pathname is a list that gives the suite and
//                          name of the test
// addBeforeAll[pathname;func] - pathname must be an existing suite
//   dto. addBeforeEach, addAfterEach, addAfterAll
// execute[pathname] - run the tests in the suite/tree specified by pathname,
//                     which may be empty.
//
// Design and Implementation notes
//
// We store the tests in a global tree. The user should not touch it directly.
// The special init/cleanup nodes are members of the tree that have special
// names (e.g. `_BEFOREALL). The value of that node is a list of lambdas
// which are executed in order.
//
// Test execution:
// * recurse through all branches, pass down two lists: beforeEach and afterEach
// * at each branch, first execute beforeAll
// * add the branch's beforeEach and afterEach to the lists
// * then execute all tests, i.e. all beforeEach, test and all afterEach
// * recurse into sub-branches, passing down the enhanced beforeEach and afterEach lists
// * execute afterAll

// TODO: Logging/output control, including support for different log levels
// TODO: Consider making arguments to executeSuite and executeTest dictionaries

\l tree.q

\d .qtb

priv.Tags:`$("_BEFOREALL";"_BEFOREEACH";"_AFTEREACH";"_AFTERALL");

priv.BeforeAllTag:priv.Tags 0;
priv.BeforeEachTag:priv.Tags 1;
priv.AfterEachTag:priv.Tags 2;
priv.AfterAllTag:priv.Tags 3;

priv.nameOk:{[path] if[(last path) in priv.Tags; '"qtb: Invalid identifier"]; };

priv.ALLTESTS:.tree.new[];

priv.addSpecial:{[special;path;func] priv.ALLTESTS:.tree.insertLeaf[priv.ALLTESTS;path,special;func] };

priv.pathString:{[path] ".","." sv string path,() };

priv.isEmptyFunc:{[func] 0x100001 ~ @[{first value x};func;{[func;err] -1 "Error, not a function: ",-3!func;`err}[func;]] };

priv.executeSpecial:{[func;suiteNameS;specialNameS]
  if[(func ~ (::)) or (func ~ ()) or priv.isEmptyFunc[func]; :1b]; // no need to "execute" (::) or () or {}
  -1 "Executing ",specialNameS," for ", suiteNameS;
  ex:@[{[f] f[];`ok};func;{x}];
  $[`ok ~ ex; 1b;
              [-1 suiteNameS," ",specialNameS," threw exception: ",ex; 0b]] };
  
priv.executeSuite:{[nocatch;basePath;be;ae;currPath]
  suitepathS:priv.pathString currPath;
  leaves:.[.tree.getLeaves;(priv.ALLTESTS;currPath);
              {[sp;err] if[err ~ "tree: invalid path"; -1 sp," is not a valid suite or test."; :`invpath]; 'err}[suitepathS;]];
  
  if[`invpath ~ leaves; :0b];  // bail out if we have hit an invalid path
  
  // execute beforeAll
  if[not priv.executeSpecial[leaves priv.BeforeAllTag;suitepathS;"BEFOREALL"];
    :enlist 0b];
  
  beforeEaches:be,leaves priv.BeforeEachTag;
  afterEaches:ae,leaves priv.AfterEachTag;
 
  bpl:count basePath;
  cpl:count currPath;
  mpl:min (bpl;cpl);
  if[not (mpl#basePath) ~ mpl#currPath; '"qtb: invalid test path"];  // sanity check: the current path is within the base path
  
  tests:key[leaves] except priv.Tags;
  nextNode:first mpl _ basePath;
 
  results:$[(bpl = cpl + 1) and nextNode in tests;  // basePath resolves to a single test (leaf)
                         priv.executeTest[nocatch;beforeEaches;afterEaches;suitepathS;`name`func!(nextNode;leaves nextNode)];
 
            bpl > cpl;   .z.s[nocatch;basePath;beforeEaches;afterEaches;(1 + mpl)#basePath]; // full basePath not reached yet, kepp following it
 
            // else execute the tests of this suite and recurse
                         [testResults:priv.executeTest[nocatch;beforeEaches;afterEaches;suitepathS;] each ([] name:tests; func:leaves tests);
                         testResults,raze .z.s[nocatch;basePath;beforeEaches;afterEaches;] each
                                               currPath ,/: .tree.getBranches[priv.ALLTESTS;currPath]]];
                       
  // execute afterAll
  priv.executeSpecial[leaves priv.AfterAllTag;suitepathS;"AFTERALL"];
 
  results };

priv.executeTest:{[nocatch;be;ae;suiteNameS;testDict]
  testnameS:suiteNameS,".",string testDict`name;
  func:testDict`func;
  
  if[1 <> countargs func;
    -1 testnameS," is not a valid test function";
    :0b];
    
  // execute beforeEaches
  if[not all priv.executeSpecial[;testnameS;"BEFOREEACH"] each be;
    :0b];
 
  // execute test
  tr:$[nocatch;{[f] (`success;f[])}[func];catchX[func;`]];
  
  // execute afterEaches
  priv.executeSpecial[;testnameS;"AFTEREACH"] each ae;
  
  $[ `exceptn ~ first tr; [-1 "Test ",testnameS," threw exception: ",last tr;  0b];
    (`success;0b) ~ tr;   [-1 "Test ",testnameS," failed";                     0b];
    (`success;1b) ~ tr;   [-1 "Test ",testnameS," succeeded";                  1b];
    `success ~ first tr;  [-1 "Test ",testnameS," returned an invalid result"; 0b];
                          '"qtb: unexpected test result"] };

priv.execute:{[catchX;basepath] 
  pn:$[any basepath ~/: (`;(::);());`$();basepath,()];
  if[11 <> type pn;'"qtb: invalid inclusion path"];
  res:priv.executeSuite[catchX;pn;();();`$()];
    
  -1 "Tests executed: ",string count res;
  -1 "Tests successful: ",string sum res;
  -1 "Tests failed: ",string sum not res;
  all res,0 < count res };

// Public Interface

suite:{[path]
  priv.nameOk path;
  priv.ALLTESTS:.tree.createBranch[priv.ALLTESTS;path];
  };

addTest:{[path;test]
  priv.nameOk path;
  priv.ALLTESTS:.tree.insertLeaf[priv.ALLTESTS;path;test];
  };

addBeforeAll:priv.addSpecial[priv.BeforeAllTag;;];
addBeforeEach:priv.addSpecial[priv.BeforeEachTag;;];
addAfterEach:priv.addSpecial[priv.AfterEachTag;;];
addAfterAll:priv.addSpecial[priv.AfterAllTag;;];

execute:priv.execute[1b;];
executeDebug:priv.execute[0b;];

// Helper functions for writing tests

// Might need a testpath argument as well
matchValue:{[msg;expValue;actValue]
  if[expValue ~ actValue; :1b];
  -1 msg," does not match. Expected: ",(-3! expValue),", actual: ",-3! actValue;
  0b };

// Wrapper function to catch exceptions
catchX:{[f;args]
  numargs:countargs f;
  cf:$[0 >= numargs;'"catchX: Unexpected number of arguments";
       1 =  numargs; {[f;arg]  (`success;f[arg])}[f;];
       1 <  numargs; {[f;args] (`success;f . args)}[f;]];
  @[cf; args; {(`exceptn;x)}] };

// Check if a function throws an expected exception
checkX:{[f;args;msg]
  res:catchX[f;args];
  $[`success ~ first res; [-1 "No exception was thrown"; 0b];
    (`exceptn;msg) ~ res; 1b;
    `exceptn ~ first res; [-1 "Expected exception \"",msg,"\", but got \"",last[res],"\""; 0b];
      '"qtb: catchX failed to return a valid result"] };

// A logging mechanism for function calls

emptyFuncallLog:{[] ([] functionName:enlist `; arguments:enlist (::)) };

resetFuncallLog:{[] priv.FUNCALL_LOG::emptyFuncallLog[]; };

resetFuncallLog[]; // ensure that the table exists

logFuncall:{[funcname;argList]
  `.qtb.priv.FUNCALL_LOG upsert (funcname;argList);
  };

getFuncallLog:{[] priv.FUNCALL_LOG };

// Wrap a function so that it will record its name and arguments via logFuncall[]
// when invoked.
//
// Implementation notes: Returning a projection has the disadvantage of consuming
// one argument out of the possible 8. In addition, it would require typing out
// all 9 variangs (0 to 8) arguments, because I could not find a way to convert
// the arguments in a function invocation (f[...]) into a list. So the most elegant
// way to solve the problem was to compose a string of the new function definition
// and create it via value. Embedded into the function is the serialized representation
// of the wrapped function, which gets de-serialized before being called. This takes
// care of more complex cases such as projections with tables as fixed arguments being
// passed in.
wrapLogCall:{[name;func]
  nameS:string name;
  numargs:countargs func;
  tail:"-9!0x",raze string -8! func; // create a string from the bytecode representation
  value $[numargs within 0 1;"{[a] .qtb.logFuncall[`",nameS,";a]; (",tail,")[a]}";
          numargs within 2 8;[arglist:";" sv string numargs#`a`b`c`d`e`f`g`h;
                              "{[",arglist,"]",
                              " argl:(",arglist,");",
                              " .qtb.logFuncall[`",nameS,";argl];",
                              " (",tail,") . argl}"];
                  '"Invalid or unsupported number of arguments"] };

countargs:{[fp]
  if[100 > type fp; :-1];  // not a function
  mfp:value fp;
  if[4 = type first mfp; :count mfp 1]; // a simple function
  basef:first mfp;
  if[not (type basef) within 100 104; '"Unsupported function type"];
  // compute the number of arguments of a projection:
  // (num args of base function) less number of arguments provided in the projection
  (count (value basef) 1) - sum not (::) ~/: 1 _ mfp };



priv.SAVEDVALUES:enlist[`]!enlist (::);

saveValue:{[varname]
  origval:@[{(1b;value x)};varname;{[dummy] (0b;`undef)}];
  stack:priv.SAVEDVALUES[varname];
  priv.SAVEDVALUES[varname]:enlist[origval],stack;
  };

// valid arguments for \x:
priv.Expungables:`.z.bm`.z.exit`.z.pc`.z.ph`.z.po`.z.ps`.z.pg`.z.pi`.z.pp`.z.pw`.z.vs`.z.ts;

restoreValue:{[varname]
  varnameS:string varname;
  stack:priv.SAVEDVALUES[varname];
  if[(::) ~ stack;'".qtb.restoreValue: invalid variable name: ",varnameS];
  newstack:1 _ stack;
  $[enlist[(::)] ~ newstack;priv.SAVEDVALUES::![priv.SAVEDVALUES;();0b;enlist varname];
                            priv.SAVEDVALUES[varname]:newstack];
  val:first stack;
  if[(::) ~ val;'".qtb.restoreValue: invalid variable name: ",varnameS];
 
  if[first val; varname set last val; :last val];
  // the variable was undefined before
  if[varname in priv.Expungables; system "x ",varnameS; :(::)];
  // delete a regular variable
  ctxlen:last where "." ~/: varnameS;
  if[null ctxlen; ![`.;();0b;enlist varname]; :(::)]; // no context, top level implied
  // we have a subcontext
  context:`$ctxlen#varnameS;
  vname:`$ (1 + ctxlen) _ varnameS;
  ![context;();0b;enlist vname];
  };

// tests:
// * root context variable, two saves
// * regular qualified variable, two saves
// * deep nested variable, two saves
// * root context variable, undefined before
// * regular qualified variable, undefined before
// * deep nested variable, undefined before
// * defined callback, one save/restore
// * undefined callback, one save/restore
