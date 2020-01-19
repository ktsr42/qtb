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

priv.isEmptyFunc:{[func] 0x100001 ~ @[{first value x};func;{[func;err] priv.println "Error, not a function: ",-3!func;`err}[func;]] };

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
priv.show:show;

priv.testResTree2Tbl:{[cp;tr]
  if[`suitename in key tr;:raze .z.s[cp,tr`suitename]'[tr`tests]];
  if[`testname in key tr;:enlist @[tr;`testname;{y,x};cp]];
  '"qtb: unknown test result value: ",-3!tr;
  };

priv.testResTree2JunitXml:{[idl;cp;r]
  pf:idl#" ";
  pf2:"  ",pf;
  if[`testname in key r;
    bd:pf,"<testcase name=\"",string[r`testname],"\" classname=\"\" time=\"",trim[.Q.fmt[10;3;r`time]],"\"";
    if[`succeeded ~ r`result;:enlist bd," />"];
    if[`failed ~ r`result;:(bd,">";pf2,"<failure type=\"failed\"/>";pf,"</testcase>")];
    :(bd,">";pf2,"<error type=\"broke\"/>";pf,"</testcase>");
  ];
  if[not `suitename in key r;'"qtb: invalid result value"];
  tests:where `testname in/: key each r`tests;
  o:();
  if[0 < count tests;
    alltests:r[`tests;tests];
    h:pf,"<testsuite name=\"",("." sv string cp,r`suitename),"\" ";
    h,:"package=\"\" hostname=\"",string[.z.h],"\" ";
    h,:"errors=\"",string[count select from alltests where not result in `succeeded`failed],"\" ";
    h,:"failures=\"",string[count select from alltests where result=`failed],"\" ";
    h,:"tests=\"",string[count alltests],"\" ";
    h,:"timestamp=\"",(-4 _ @[;10;:;"T"] @[;4 7;:;"-"] string 15h$r`start),"\" ";
    h,:"time=\"",trim[.Q.fmt[10;3;r`time]],"\">";
    b:raze .z.s[2 + idl;cp,r`suitename]'[alltests];
    da:pf2,/:("<properties />";"<system-out />";"<system-err />");
    o:(h;da 0),b,1 _ da;
    o,:enlist pf,"</testsuite>";
  ];
  :o,raze .z.s[idl;cp,r`suitename] each r[`tests] where not `testname in/: key each r`tests;
  };

priv.junitXmlDoc:{[res]
  junitxml:("<?xml version=\"1.0\" encoding=\"UTF-8\"?>";"<testsuites>");
  junitxml,:priv.testResTree2JunitXml[2;`$();res];
  :junitxml,enlist"</testsuites>";
  };

priv.testsComplete:{[verbose;junitfile;res]
  if[not null junitfile; hsym[junitfile] 0: priv.junitXmlDoc res];
  rt:`path xcol priv.testResTree2Tbl[`$();res];
  if[count fails:select from rt where result <> `succeeded; priv.show fails];
  :rt;
  };

priv.testResults:`succeeded`failed`broke`skipped!".EBS";

priv.reportTestResult:{[verbose;testnames;res;reason]
  if[null priv.testResults res;'"qtb: invalid test result: ",string res];
  if[verbose;
    priv.println testnames," ",string[res],$[all (`succeeded <> res;not "" ~ reason);" because of ",reason;""];
    :(::)];
  priv.print priv.testResults res;
  };

priv.executeSpecial:{[func;suiteNameS;specialNameS]
  if[(func ~ (::)) or (func ~ ()) or priv.isEmptyFunc[func]; :1b]; // no need to "execute" (::) or () or {}
  ex:@[{[f] f[];`ok};func;{x}];
  if[not `ok ~ ex;
    priv.println suiteNameS," ",specialNameS," threw exception: ",ex;
    :0b];
  :1b;
  };

priv.durationSeconds:{[s;e] (e - s) % 0D00:00:01};

// params `nocatch`basepath`beforeach`aftereach`overrides`currPath`mode`verbose
priv.executeSuite:{[params]
  pm:priv.matchPaths . params`basepath`currPath;
  if[`mismatch ~ pm;'"qtb: path mismatch"];
  suitepathS:priv.pathString params`currPath;
  errf:{[sp;err] if[err ~ "tree: invalid path"; priv.println sp," is not a valid suite or test."; :`invpath]; 'err}[suitepathS;];
  suitename:last params`currPath;
  subtree:.[.tree.getLeaves;(priv.ALLTESTS;params`currPath);errf];
  if[subtree ~ `invpath; '"qtb: invalid path"];
  if[`value ~ subtree 0;
    if[`skip ~ params`mode;
      priv.reportTestResult[params`verbose;suitepathS;`skipped];
      :`testname`result`time!(suitename;`skipped;0f)];
    if[`exec ~ params`mode;
      :$[pm ~ `subpath;priv.executeTest . (subtree 1;@[params;`tns;:;suitepathS]);()]];
    '"qtb: unknown mode ",string params`mode];

  if[not `nodes ~ subtree 0;'"qtb: Unexpected result from .tree.getLeaves[]"];
 
  suitestart:.z.p;
  // execute beforealls
  if[`exec ~ params`mode;
    if[not priv.executeSpecial[subtree[1;priv.BeforeAllTag];suitepathS;"BEFOREALL"];
      params[`mode]:`skip]];

  // overrides, before- and aftereach trickle down the tree
  xa:@[;`overrides;,[;$[(::) ~ co:subtree[1;priv.OverrideTag];();co]]]   // append the overrides for this suite
       @[;`aftereach;,[;subtree[1;priv.AfterEachTag]]]                   // append the aftereach funcs
         @[;`beforeeach;,[;subtree[1;priv.BeforeEachTag]]] params;       // append the beforeach funcs

  // iterating into subtrees: if we have a defined prefix and not exhausted it, just take the next element in the target path
  //                          otherwise we execute each subelement, branch or leaf (test)
  branches:(),$[pm ~ `prefix;first {[bp;cp] count[cp] _ bp} . params`basepath`currPath;(key subtree 1) except priv.Tags,`];
  res:{[f;p;k] f @[p;`currPath;,[;k]]}[.z.s;xa] each branches;
 
  // execute afteralls
  if[`exec ~ params`mode;
    if[not priv.executeSpecial[subtree[1;priv.AfterAllTag];suitepathS;"AFTERALL"];
      res:update result:`broke from res]];
 
  :`suitename`start`time`tests!(suitename;suitestart;priv.durationSeconds[suitestart;.z.p];res);
  };

// params: `nocatch`beforeeach`aftereach`tns`overrides`verbose`currPath
priv.executeTest:{[tf;params]
  testname:last params`currPath;
  if[1 <> countargs tf;
    priv.reportTestResult . (params`verbose`tns),(`broke;"invalid test function");
    :`testname`result`time!(testname;`broke;0f)];

  // apply overrides
  priv.CURRENT_OVERRIDES:priv.applyOverrides params`overrides;
 
  teststart:.z.p;
  // execute beforeEaches
  if[not all 1b,priv.executeSpecial[;params`tns;"BEFOREEACH"] each params`beforeeach;
    priv.reportTestResult . (params`verbose`tns),(`broke;"beforeeach failure");
    :`testname`result`time!(testname;`broke;priv.durationSeconds[teststart;.z.p])];

  resetFuncallLog[];
 
  // execute test
  tres:$[params`nocatch;(1b;tf[]);try (tf;::)];
 
  // execute afterEaches
 aeres:all 1b,priv.executeSpecial[;params`tns;"AFTEREACH"] each params`aftereach;
 
  // revert all overrides
  priv.revertOverrides priv.CURRENT_OVERRIDES;
  priv.CURRENT_OVERRIDES:0#priv.CURRENT_OVERRIDES;
//  {'"stop!"}[];
  
  res:$[not aeres;      (`broke;"aftereach failure");
        not first tres; (`failed;tres 1);
        first tres;     (`succeeded;"");
                        '"qtb: unexpected test result"];

  priv.reportTestResult . (params`verbose`tns),res;
  :`testname`result`time!(testname;res 0;priv.durationSeconds[teststart;.z.p]);
  };

priv.execute:{[catchX;basepath] 
  pn:$[any basepath ~/: (`;(::);());`$();basepath,()];
  if[11 <> type pn;'"qtb: invalid inclusion path"];
  res:priv.executeSuite `nocatch`basepath`beforeeach`aftereach`overrides`currPath`mode`verbose!(catchX;pn;();();priv.genDict;`$();`exec;0b);
  priv.println"";
  :priv.testsComplete[0b;`;res];
  };

priv.start:{[ca]
  xp:`nocatch`basepath`beforeeach`aftereach`overrides`currPath`mode`verbose!(ca`debug;`$();();();priv.genDict;`$();`exec;ca`verbose);
  res:priv.executeSuite xp;priv.println "";
  :(priv.testsComplete . ca`verbose`junit) res;
 };

priv.scriptWithArgs:{[] all (not null .z.f;0 < count .z.x)};

priv.exit:{exit not x};

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


priv.tbl2dict:{[cls;t] (!) . (0!t) cls };
priv.dict2tbl:{[cls;d] 1!flip cls!(key;value) @\: d};

priv.CmdlineFlags:([param:`run`verbose`junit`debug] dflt:(0b;0b;`;0b));
priv.CmdlineFlagsD:priv.tbl2dict[`param`dflt;priv.CmdlineFlags];

priv.parseCmdline:{[zx]
  args0:{delete from x where not "qtb-" ~/: 4#/:param} update param:string param from 0!priv.dict2tbl[`param`arg] priv.genDict,.Q.opt zx;
  args1:priv.CmdlineFlags lj 1!([] param:enlist`; arg:enlist(::)),update `$4_/:param from args0;
  args2:update argv:{[dflt;args] $[(::) ~ args;dflt;all (() ~ args;-1h = type dflt);not dflt;type[dflt]$first args]}'[dflt;arg] from args1;
  :@[;`debug;or[0 <> .q.system"e"]] priv.tbl2dict[`param`argv] args2;
  };


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

.qtb.assert.str:{[o] :(`s#(-0W 0 10 11h!(string;-3!;(::);-3!)))[type o] o};
.qtb.assert.assertfunc:{[checkf;cfname;expv;actv]
  if[checkf[expv;actv];:(::)];
  '$[10h <> type cfname;cfname[expv;actv];"Expected '",.qtb.assert.str[expv],"' ",cfname," '",.qtb.assert.str[actv],"'"];
  };

.qtb.assert.wrapassert:{[cf;cfname;args]
  .qtb.assert.assertfunc . $[2 = count args;(cf;cfname);enlist[cfg]],args;
 };

.qtb.assert.matches:.qtb.assert.assertfunc[~;"to match"];
.qtb.assert.equals:.qtb.assert.assertfunc[=;"to be equal to"];
.qtb.assert.within:.qtb.assert.assertfunc[within;"to be within"];
.qtb.assert.like:.qtb.assert.assertfunc[like;"to match the pattern"];
.qtb.assert.throws:{[expr;errpat]
  r:@[(1b;)eval@;expr;(0b;)];
  if[first r;'.qtb.assert.str[expr]," did not throw any exception"];
  if[not last[r] like errpat;'.qtb.assert.str[expr]," did not throw exception '",errpat,"', but '",last[r],"'"];
  };

/
// Might need a testpath argument as well
matchValue:{[msg;expValue;actValue]
  if[expValue ~ actValue; :1b];
  priv.println msg," does not match. Expected: ",(-3! expValue),", actual: ",-3! actValue;
  0b };
\

// Wrapper function to catch exceptions
try:@[(1b;)eval@;;(0b;)];

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
 
callLog:{[fname;wrapf]
  if[100h > type wrapf;'".qtb.callLog: not a function"];
  :callLogComplex[fname;wrapf;0N];
  };

callLogSimple:{[fname;retval]
  if[100h < type retval;'".qtb.callLogSimple: not value"];
  :callLogComplex[fname;retval;0N];
  };

callLogNoret:callLogComplex[;(::);0N];

countargs:{[fp]
  if[100 > type fp; :-1];  // not a function
  mfp:value fp;
  if[4 = type first mfp; :count mfp 1]; // a simple function
  basef:first mfp;
  if[not (type basef) within 100 104; '"Unsupported function type"];
  // compute the number of arguments of a projection:
  // (num args of base function) less number of arguments provided in the projection
  (count (value basef) 1) - sum not (::) ~/: 1 _ mfp };


///////////////////////////////
// run with command-line paramaters
run:{[]
  if[not priv.scriptWithArgs[];:(::)];
  args:priv.parseCmdline .z.x;
  if[not args`run;:(::)];
  runfunc:{(1b;.qtb.priv.start x)};
  r:$[args`debug;runfunc;@[runfunc;;(0b;)]] args;
  if[not r 0;priv.println "Caught exception: ",r 1];
  success:$[not r 0;0b;0 = count select from r[1] where result<>`succeeded];
  if[not args`debug;priv.exit success];
  };

// in non-debug mode, always exit, set status from exception or test result
// in debug mode, exit only if there is success