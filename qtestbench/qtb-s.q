// Q Test Bench - A framework for writing unit tests in Q
//
// Copyright (C) 2012, 2013, 2018 Klaas Teschauer
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

priv.Tags:`$("_BEFOREALL";"_BEFOREEACH";"_AFTEREACH";"_AFTERALL";"_OVERRIDES");

priv.BeforeAllTag:priv.Tags 0;
priv.BeforeEachTag:priv.Tags 1;
priv.AfterEachTag:priv.Tags 2;
priv.AfterAllTag:priv.Tags 3;
priv.OverrideTag:priv.Tags 4;

priv.Expungable:`.z.exit`.z.pc`.z.po`.z.ps`.z.pg`.z.ts`.z.wo`.z.wc`.z.vs`.z.ac`.z.bm`.z.zd`.z.ph`.z.pm`.z.pp`.z.pi`.z.pw;

priv.ALLTESTS:.tree.new[];

priv.CURRENT_OVERRIDES:([] vname:`$(); origValue:(); undef:`boolean$());

priv.genDict:enlist[`]!enlist (::);

priv.nameOk:{[path] if[(last path) in priv.Tags; '"qtb: Invalid identifier"]; };

priv.addSpecial:{[special;path;func] priv.ALLTESTS:.tree.insertLeaf[priv.ALLTESTS;path,special;func] };

priv.pathString:{[path] ".","." sv string path,() };

priv.isEmptyFunc:{[func] 0x100001 ~ @[{first value x};func;{[func;err] -1 "Error, not a function: ",-3!func;`err}[func;]] };

// () `x`y  -> b is subpath of a
// `  `x`y  -> b is subpath of a
// `x`y ()  -> prefix
// `x`y `x  -> prefix
// `x `x`y  -> subpath
// `x`y `x`y`z - > subpath
// `x`y `x`y -> subpath
// `x`y `a`b -> mismatch
priv.matchPaths:{[pa;pb]
 pl:{$[any x ~/: (();(::);`);`$();(),x]}'[(pa;pb)];
 cpl:min pls:count'[pl];
 if[(~) . cpl#/: pl; :$[(>) . pls;`prefix;`subpath]];
 :$[0 = pls 0;`subpath;`mismatch];
 };

priv.print:1;
priv.println:-1;

priv.testResults:`succeeded`failed`broke`invalid`skipped!".FBIS";

priv.reportTestResult:{[verbose;testnames;res;reason]
  if[null priv.testResults res;'"qtb: invalid test result: ",string res];
  if[verbose;
    msg:testnames," ",string res;$[all (1 <> res;not "" ~ reason);" because ",reason;""];
    priv.println msg;
    :(::)];
  priv.print priv.testResults res;
  };

priv.executeSpecial:{[func;suiteNameS;specialNameS]
  if[(func ~ (::)) or (func ~ ()) or priv.isEmptyFunc[func]; :1b]; // no need to "execute" (::) or () or {}
  ex:@[{[f] f[];`ok};func;{x}];
  if[not `ok ~ ex;
    -1 suiteNameS," ",specialNameS," threw exception: ",ex;
    :0b];
  :1b;
  };

// params `nocatch`basepath`beforeach`aftereach`overrides`currPath`mode`verbose
priv.executeSuite:{[params]
 pm:priv.matchPaths . params`basepath`currPath;
 if[`mismatch ~ pm;'"qtb: path mismatch"];
 suitepathS:priv.pathString params`currPath;
 errf:{[sp;err] if[err ~ "tree: invalid path"; -1 sp," is not a valid suite or test."; :`invpath]; 'err}[suitepathS;];
 subtree:.[.tree.getLeaves;(priv.ALLTESTS;params`currPath);errf];
 if[subtree ~ `invpath; '"qtb: invalid path"];
 if[`value ~ subtree 0;
   if[`skip ~ params`mode;
     priv.reportTestResult[params`verbose;suitepathS;`skipped];
     :enlist `path`result!(params`currPath;`skipped)];
   if[`exec ~ params`mode;
     :$[pm ~ `subpath;enlist priv.executeTest . (subtree 1; @[params;`tns;:;suitepathS]);`$()]];
   '"qtb: unknown mode ",string params`mode];
 
 if[not `nodes ~ subtree 0;'"qtb: Unexpected result from .tree.getLeaves[]"];
 // execute beforealls
 if[`exec ~ params`mode;
   if[not priv.executeSpecial[subtree[1;priv.BeforeAllTag];suitepathS;"BEFOREALL"];
     params[`mode]:`skip]];

  xa:@[;`overrides;,[;$[(::) ~ co:subtree[1;priv.OverrideTag];();co]]]
       @[;`aftereach;,[;subtree[1;priv.AfterEachTag]]]
         @[;`beforeeach;,[;subtree[1;priv.BeforeEachTag]]] params;

  branches:(),$[pm ~ `prefix;first {[bp;cp] count[cp] _ bp} . params`basepath`currPath;(key subtree 1) except priv.Tags,`];
  res:raze {[f;p;k] f @[p;`currPath;,[;k]]}[.z.s;xa] each branches;
 
  // execute afteralls
  if[`exec ~ params`mode;
    if[not priv.executeSpecial[subtree[1;priv.AfterAllTag];suitepathS;"AFTERALL"];
      :update result:`broke from res]];
 
 :res;
 };

// params: `nocatch`beforeeach`aftereach`tns`overrides`verbose`currPath
priv.executeTest:{[tf;params]
  if[params`verbose;priv.print params`tns];

  if[1 <> countargs tf;
    priv.reportTestResult . (params`verbose`tns),(`broke;"invalid test function");
    :`path`result!(params`currPath;`broke)];
 
  // apply overrides
  priv.CURRENT_OVERRIDES:priv.applyOverrides params`overrides;
 
  // execute beforeEaches
  if[not all 1b,priv.executeSpecial[;params`tns;"BEFOREEACH"] each params`beforeeach;
    priv.reportTestResult . (params`verbose`tns),(`broke;"beforeeach failure");
    :`path`result!(params`currPath;`broke)];

  resetFuncallLog[];
 
  // execute test
  tres:$[params`nocatch;(`success;tf[]);catchX[tf;`]];
 
  // execute afterEaches
  aeres:all 1b,priv.executeSpecial[;params`tns;"AFTEREACH"] each params`aftereach;
 
  // revert all overrides
  priv.revertOverrides priv.CURRENT_OVERRIDES;
  priv.CURRENT_OVERRIDES:0#priv.CURRENT_OVERRIDES;
  
  res:$[not aeres;(`broke;"aftereach failure");
        `exceptn ~ tres 0;(`error;"exception: ",tres 1);
        (`success;0b) ~ tres;(`failed;"");
        (`success;1b) ~ tres;(`succeeded;"");
        `success ~ tres 0;(`broke;"unexpected return value");
                          '"qtb: unexpected test result"];

  priv.reportTestResult . (params`verbose`tns),res;
  :`path`result!(params`currPath;res 0);
  };

priv.execute:{[catchX;basepath] 
  pn:$[any basepath ~/: (`;(::);());`$();basepath,()];
  if[11 <> type pn;'"qtb: invalid inclusion path"];
  :priv.executeSuite `nocatch`basepath`beforeeach`aftereach`overrides`currPath`mode`verbose!(catchX;pn;();();priv.genDict;`$();`exec;0b);
  };

priv.applyOverride:{[vname;newval]
  currval:$[undef:() ~ key vname;(::);eval vname];
  vname set newval;
  :`vname`origValue`undef!$[undef;(vname;(::);1b);(vname;currval;0b)];
  };

priv.applyOverrides:{[od]
  if[od ~ priv.genDict;:()];
  :priv.applyOverride ./: flip (key;value)@\: ` _ od;
  };

priv.revertOverride:{[vname;val;undef]
  if[not undef; vname set val; :(::)];
  // take care of deleting undefined variables
  if[2 > sum "." ~/: string vname;![`.;();0b;enlist vname]; :(::)];
  if[vname in priv.Expungable;system "x ",string vname; :(::)];
  {![x;();0b;enlist y]} . `${("." sv -1 _ x;last x)} "." vs string  vname;
  };

priv.revertOverrides:{[overrides] {[d] priv.revertOverride . d`vname`origValue`undef} each overrides; }

// Public Interface

suite:{[path]
  priv.nameOk path;
  priv.ALLTESTS:.tree.createBranch[priv.ALLTESTS;path];
  :path;
  };

addTest:{[path;test]
  priv.nameOk path;
  priv.ALLTESTS:.tree.insertLeaf[priv.ALLTESTS;path;test];
  };

addBeforeAll:priv.addSpecial[priv.BeforeAllTag;;];
addBeforeEach:priv.addSpecial[priv.BeforeEachTag;;];
addAfterEach:priv.addSpecial[priv.AfterEachTag;;];
addAfterAll:priv.addSpecial[priv.AfterAllTag;;];
setOverrides:priv.addSpecial[priv.OverrideTag;;];

execute:priv.execute[0b;];
executeDebug:priv.execute[1b;];

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
                     {[f;args] (`success;f . args)}[f;]];
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

logFuncall:{[funcname;argList] `.qtb.priv.FUNCALL_LOG upsert (funcname;argList); };

getFuncallLog:{[] priv.FUNCALL_LOG };

override:{[vname;val]
  priv.CURRENT_OVERRIDES:enlist[priv.applyOverride[vname;val]],priv.CURRENT_OVERRIDES;  // insert the per-test override at the beginning of the list, first in line to be reverted.
  };

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
callLogComplex:{[fname;rvof;nargs]
  numargs:$[nargs within 1 8;nargs;countargs value fname];
  if[not numargs within 1 8;'"Invalid or unsupported number of arguments"];
  if[all (99h<;101h <>) @\: type rvof;if[numargs <> countargs rvof;'"argument count does not match"]];
  rs:"-9!0x",(raze string -8! rvof);
  rvs:$[any (100h>;101h=) @\: type rvof;rs;"value enlist[",rs,"],",$[1 = numargs;"enlist[args]";"args"]];
  arglist:";" sv string numargs#(`$)'[.Q.a]; 
  :value "{[",arglist,"] args:(),(",arglist,"); .qtb.logFuncall[`",string[fname],";args];",rvs,"}";
  };
 
callLog:callLogComplex[;;0N];

callLogS:callLogComplex[;(::);0N];

countargs:{[fp]
  if[100 > type fp; :-1];  // not a function
  mfp:value fp;
  if[4 = type first mfp; :count mfp 1]; // a simple function
  basef:first mfp;
  if[not (type basef) within 100 104; '"Unsupported function type"];
  // compute the number of arguments of a projection:
  // (num args of base function) less number of arguments provided in the projection
  (count (value basef) 1) - sum not (::) ~/: 1 _ mfp };

