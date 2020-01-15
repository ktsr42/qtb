/////////////////////////////////////
// Unit tests for the Q Test Bench

\l qtb-s.q

\l ../tb/testbench.q

privExecuteN_all:{[]
  executeSuite_orig:.qtb.priv.executeSuite;
  println_orig:.qtb.priv.println;
  `.qtb.priv.println set {};
  xsres:`suitename`start`time`tests!(`p;0Np;1f;([] testname:`a`b`c; result:3#`succeeded; time:1 2 3f));
  `.qtb.priv.executeSuite set {[r;y] r}[xsres];
  r:.qtb.priv.execute[1b;`];
  exp_res:([] path:(`p`a;`p`b;`p`c); result:3#`succeeded; time:1 2 3f);
  `.qtb.priv.executeSuite set executeSuite_orig;
  `.qtb.priv.println set println_orig;
  :exp_res ~ r;
  };


checkOverrides:{[] if[not (v;.ctx.f) ~ (42;{});'"Missing overrides!"]};

initTestSuite:{[]
  .qtb.priv.ALLTESTS:.tree.new[];
  execute_root_beforeAll_flag::0b;
  .qtb.addBeforeAll[`;{[] execute_root_beforeAll_flag::1b;}];
  execute_root_afterAll_flag::0b;
  .qtb.addAfterAll[`;{[] execute_root_afterAll_flag::1b;}];
  execute_root_test_flag::0b;  
  .qtb.addTest[`noexec;{[] execute_root_test_flag::1b; 0b}];
  .qtb.suite `realtests;
  .qtb.setOverrides[`;`v`.ctx.f!(42;{})];
  execute_realtest_beforeAll_flag::0b;
  .qtb.addBeforeAll[`realtests;{[] execute_realtest_beforeAll_flag::1b;}];
  execute_realtest_afterAll_flag::0b;
  .qtb.addAfterAll[`realtests;{[] execute_realtest_afterAll_flag::1b;}];
  execute_realtest_beforeEach_counter::0;  
  .qtb.addBeforeEach[`realtests;{[] execute_realtest_beforeEach_counter+::1;}];
  execute_realtest_afterEach_counter::0;  
  .qtb.addAfterEach[`realtests;{[] execute_realtest_afterEach_counter+::1;}];
  .qtb.addTest[`realtests`a;{[] checkOverrides[];}];
  .qtb.addTest[`realtests`b;{[] checkOverrides[];'"nope!"}];
  `execute_exp_res set ([] path:(``realtests`a;``realtests`b); result:`succeeded`failed);
  `print_orig set .qtb.priv.print;
  `.qtb.priv.print set {};
  `println_orig set .qtb.priv.println;
  `.qtb.priv.println set {};
  `show_orig set .qtb.priv.show;
  `.qtb.priv.show set {};
  };

restoreTestSuite:{[]
  `.qtb.priv.print set print_orig;
  `.qtb.priv.println set println_orig;
  `.qtb.priv.show set show_orig;
  };
 
execute_base:{[]
  initTestSuite[];
  tr:.qtb.execute `realtests;
  if[any {x[;0]} {@[{(1b;x;value x)};x;(0b;)]}'[`v`.ctx.f];'"override left defined"];
  restoreTestSuite[];
  all .qtb.matchValue ./: (("Return value";execute_exp_res;select path, result from tr);
                      ("root_beforeAll_flag";1b;execute_root_beforeAll_flag);
                      ("root_afterAll_flag";1b;execute_root_afterAll_flag);
                      ("root_test_flag";0b;execute_root_test_flag);
                      ("realtest_beforeAll_flag";1b;execute_realtest_beforeAll_flag);
                      ("realtest_afterAll_flag";1b;execute_realtest_afterAll_flag);
                      ("realtest_beforeEach_counter";2;execute_realtest_beforeEach_counter);
                      ("realtest_aferEach_counter";2;execute_realtest_afterEach_counter) ) };


execute_failBeforeAll:{[]
  initTestSuite[];
  .qtb.addBeforeAll[`realtests;{[] execute_realtest_beforeAll_flag::1b;'"fire in the hole!"}];
  tr:.qtb.execute`realtests;
  restoreTestSuite[];
  r:all .qtb.matchValue ./: (("Return value";([] path:(``realtests`a;``realtests`b); result:`skipped`skipped; time:0 0f);tr);
                        ("root_beforeAll_flag";1b;execute_root_beforeAll_flag);
                        ("root_afterAll_flag";1b;execute_root_afterAll_flag);
                        ("root_test_flag";0b;execute_root_test_flag);
                        ("realtest_beforeAll_flag";1b;execute_realtest_beforeAll_flag);
                        ("realtest_afterAll_flag";0b;execute_realtest_afterAll_flag);
                        ("realtest_beforeEach_counter";0;execute_realtest_beforeEach_counter);
                        ("realtest_aferEach_counter";0;execute_realtest_afterEach_counter) );
  r };

execute_alltests:{[]
  initTestSuite[];
  tr:.qtb.execute[];
  restoreTestSuite[];
  expres:([] path:(``noexec;``realtests`a;``realtests`b); result:`succeeded`succeeded`failed);
  r:all .qtb.matchValue ./: (("Return value";expres;delete time from tr);
                        ("root_beforeAll_flag";1b;execute_root_beforeAll_flag);
                        ("root_afterAll_flag";1b;execute_root_afterAll_flag);
                        ("root_test_flag";1b;execute_root_test_flag);
                        ("realtest_beforeAll_flag";1b;execute_realtest_beforeAll_flag);
                        ("realtest_afterAll_flag";1b;execute_realtest_afterAll_flag);
                        ("realtest_beforeEach_counter";2;execute_realtest_beforeEach_counter);
                        ("realtest_aferEach_counter";2;execute_realtest_afterEach_counter) );                    
  r };

execute_single:{[]
  initTestSuite[];
  execute_realtest_a::0b;
  execute_realtest_b::0b;
  .qtb.addTest[`realtests`a;{[] execute_realtest_a::1b; 1b}];
  .qtb.addTest[`realtests`b;{[] execute_realtest_b::0b; 1b}];
  tr:.qtb.execute `realtests`a;
  restoreTestSuite[];
  r:all .qtb.matchValue ./: (("Return value";([] path:enlist ``realtests`a; result:enlist `succeeded);delete time from tr);
                        ("root_beforeAll_flag";1b;execute_root_beforeAll_flag);
                        ("root_afterAll_flag";1b;execute_root_afterAll_flag);
                        ("root_test_flag";0b;execute_root_test_flag);
                        ("realtest_beforeAll_flag";1b;execute_realtest_beforeAll_flag);
                        ("realtest_afterAll_flag";1b;execute_realtest_afterAll_flag);
                        ("realtest_beforeEach_counter";1;execute_realtest_beforeEach_counter);
                        ("realtest_aferEach_counter";1;execute_realtest_afterEach_counter);
                        ("realtest_a";1b;execute_realtest_a);
                        ("realtest_b";0b;execute_realtest_b) );
  r };


execute_SUITE:`execute_base`execute_failBeforeAll`execute_alltests`execute_single;

try_noarg_noerr:{[] (1b;42)    ~ .qtb.try ({[] 42};(::))     };
try_noarg_error:{[] (0b;"Yo!") ~ .qtb.try ({[] '"Yo!"};(::)) };

try_oneargsimple_noerr:{[] (1b;1b) ~ .qtb.try ({x ~ 42};42) };
try_oneargsimple_error:{[] (0b;"42") ~ .qtb.try ({'string x};42) };

try_oneargsym_noerr:{[] (1b;1b) ~ .qtb.try ({x ~ `xx};(),`xx) };
try_oneargsym_error:{[] (0b;"xx") ~ .qtb.try ({'string x};(),`xx) };

try_onearglist_noerr:{[] (1b;1b) ~ .qtb.try ({x ~ 2 1};2 1) };
try_onearglist_error:{[] (0b;"1",()) ~ .qtb.try ({'string x ~ 2 1};2 1) };

try_oneargsymlist_noerr:{[] (1b;1b) ~ .qtb.try ({x ~ `a`b};enlist `a`b) };
try_oneargsymlist_error:{[] (0b;"1",()) ~ .qtb.try ({'string x ~ `x`y};enlist `x`y) };

try_oneargtbl_noerr:{[] tt:([] c:1 2); (1b;tt) ~ .qtb.try ({x};tt) };
try_oneargtbl_error:{[] tt:([] c:1 2); (0b;"1",()) ~ .qtb.try ({[t;x] 'string t ~ x}[tt;];tt) };

try_oneargdict_noerr:{[] d:`a`b!1 2; (1b;d) ~ .qtb.try ({x};d) };
try_oneargdict_error:{[] d:`a`b!1 2; (0b;"1",()) ~ .qtb.try ({[t;x] 'string t ~ x}[d;];d) };

try_twoargsimple_noerr:{[] (1b;42 -1) ~ .qtb.try ({(x;y)};42;-1) };
try_twoargsimple_error:{[] (0b;"42 -1") ~ .qtb.try ({'" " sv string (x;y)};42;-1) };

try_twoarglist_noerr:{[] l1:42 -1; l2:`a`b; (1b;(l1;l2)) ~ .qtb.try ({(x;y)};l1;enlist l2) };
try_twoarglist_error:{[] l1:42 -1; l2:`a`b; (0b;"1",()) ~ .qtb.try ({[e;x;y] 'string e ~ (x;y)}[(l1;l2);;];l1;enlist l2) };

try_SUITE:`try_noarg_noerr`try_noarg_error`try_oneargsimple_noerr`try_oneargsimple_error,
             `try_oneargsym_noerr`try_oneargsym_error`try_onearglist_noerr`try_onearglist_error,
             `try_oneargsymlist_noerr`try_oneargsymlist_error`try_oneargtbl_noerr`try_oneargtbl_error,
             `try_oneargdict_noerr`try_oneargdict_error`try_twoargsimple_noerr`try_twoargsimple_error,
             `try_twoarglist_noerr`try_twoarglist_error;

countargs_funcs:{[]
  all .qtb.matchValue ./: (("No argument function";1;.qtb.countargs {[]});
                      ("One argument function";1;.qtb.countargs {[a] a+1});
                      ("Three argument function";3;.qtb.countargs {[a;b;c] a+b+c})) };

countargs_projections:{[]
  all .qtb.matchValue ./: (("Two arg func with first provided";1;.qtb.countargs {[a;b] a+b}[1]);
                      ("Two arg func with second provided";1;.qtb.countargs {[a;b] a+b}[;1]);
                      ("Five arg func with arg two and four given";3;.qtb.countargs {[a;b;c;d;e] a+b+c+d+e}[;2;;3]);
                      ("Four arg func with first one given";3;.qtb.countargs {[a;b;c;d] a+b+c+d}[1]);
                      ("Four arg func with last one given";3;.qtb.countargs {[a;b;c;d] a+b+c+d}[;;1]);
                      ("Four arg func with second one given";3;.qtb.countargs {[a;b;c;d] a+b+c+d}[;1])) };

countargs_notafunc:{[]
  -1 = .qtb.countargs[42] };

countargs_SUITE:`countargs_funcs`countargs_projections`countargs_notafunc;

logFuncall_all:{[]
  .qtb.resetFuncallLog[];
  .qtb.logFuncall[`noarg;(::)];
  .qtb.logFuncall[`onearg;`asym];
  .qtb.logFuncall[`someargs;(42;`somesym;"yes")];
  .qtb.logFuncall[`onearg;([] c:1 2)];
  .qtb.logFuncall[`onearg;`a`b!2 1];
  expFuncallLog:([] functionName:``noarg`onearg`someargs`onearg`onearg;
                    arguments: ((::);(::);`asym;(42;`somesym;"yes");([] c:1 2);`a`b!2 1));
  actFuncallLog::.qtb.getFuncallLog[];
  .qtb.resetFuncallLog[];
  expFuncallLog ~ actFuncallLog };


\d .isemptyfunc_context

emptyfunc:{};
notemptyfunc:{x+y};
answer:42;

\d .

isEmptyFunc_true:{[] 110b ~ .qtb.priv.isEmptyFunc @/: ({};.isemptyfunc_context.emptyfunc;.isemptyfunc_context.notemptyfunc) };

isEmptyFunc_false:{[] all not .qtb.priv.isEmptyFunc @/: (();(::);`.isemptyfunc_context.answer;{sqrt x}) };

isEmptyFunc_error:{[]
  println:.qtb.priv.println;
  `.qtb.priv.println set {};
  r:all not .qtb.priv.isEmptyFunc @/: (1;`answer;3 4f);
  `.qtb.priv.println set println;
  :r;
  };

isEmptyFunc_SUITE:`isEmptyFunc_true`isEmptyFunc_false`isEmptyFunc_error;


executeSpecial_empty:{[]
  all .qtb.priv.executeSpecial[;"executeSpecial empty";] ./: (((::);"Test ::");(();"Test ()");({};"Test {}")) };

executeSpecial_success:{[]
  executeSpecial_mark::0b;
  r:.qtb.priv.executeSpecial[{ executeSpecial_mark::1b; };"executeSpecial success";"oh my"];
  all (executeSpecial_mark;r) }

executeSpecial_fail:{[]
  executeSpecial_mark::0b;
  r:.qtb.priv.executeSpecial[{ executeSpecial_mark::1b; '"whoops"};"executeSpecial success";"oh my"];
  all (executeSpecial_mark;not r) }

executeSpecial_SUITE:`executeSpecial_empty`executeSpecial_success`executeSpecial_fail;


matchPaths_all:{[]
  :all {.qtb.priv.matchPaths[x;y] ~ z} .' ((();`a`b;`subpath);(`;`a`b;`subpath);(`x`y;();`prefix);(`x`y;`x;`prefix);(`x`y;`x`y`z;`subpath);(`x`y;`x`y;`subpath);(`x`y;`a`b;`mismatch));
  };

\d .executeSuite

executeSpecial_log:();
executeTest_log:();

setup:{[]
  `.executeSuite.alltests_orig set .qtb.priv.ALLTESTS;
  `.qtb.priv.ALLTESTS set 42;
  
  `.executeSuite.tree_getLeaves_orig set .tree.getLeaves;
  override_getLeaves[];
 
  `.executeSuite.executeSpecial_log set ();
  `.executeSuite.executeSpecial_orig set .qtb.priv.executeSpecial;
  `.qtb.priv.executeSpecial set {[f;sp;n] executeSpecial_log,::enlist (f;sp;n); 1b};
  
  `.executeSuite.executeTest_orig set .qtb.priv.executeTest;
  `.executeSuite.executeTest_log set ();
  `.qtb.priv.executeTest set {[tf;params] executeTest_log,::enlist (tf;params); `testname`result`time!(last params`currPath;`succeeded;1.2f)};
  `.executeSuite.dfltargs set `nocatch`basepath`beforeeach`aftereach`overrides`currPath`mode`verbose!(0b;`$();();();(`$())!();`pa`th;`exec;1b);
  `.executeSuite.println_orig set .qtb.priv.println;
  `.qtb.priv.println set {};
  `.executeSuite.durationSeconds_orig set .qtb.priv.durationSeconds;
  `.qtb.priv.durationSeconds set {(x;y); 1.1f};
  };

restore:{[]
  `.qtb.priv.ALLTESTS set alltests_orig;
  `.tree.getLeaves set tree_getLeaves_orig;
  `.qtb.priv.executeSpecial set executeSpecial_orig;
  `.qtb.priv.executeTest set executeTest_orig;
  `.qtb.priv.println set println_orig;
  `.qtb.priv.durationSeconds set .executeSuite.durationSeconds_orig;
  };

beforeall:{[] `beforeeall};
afterall:{[] `afterall};
testa:{[] `testa;1b};
testb:{[] `testb;0b};
beforeeach_l:{[] `beforeeach_local};
aftereach_l:{[] `aftereach_local};
beforeeach:{[] `beforeeach};
aftereach:{[] `aftereach};
overrides:`varA`varB!1 2;

override_getLeaves:{[]
  ll0:(!) . (.qtb.priv[`BeforeAllTag`AfterAllTag`OverrideTag`BeforeEachTag`AfterEachTag],`th`xx;
              .executeSuite[`beforeall`afterall`overrides`beforeeach_l`aftereach_l],((::);(::)));
  ll1:(!) . (.qtb.priv'[`BeforeAllTag`AfterAllTag`OverrideTag`BeforeEachTag`AfterEachTag],`testa`testb;
             .executeSuite'[`beforeall`afterall`overrides`beforeeach`aftereach`testa`testb]);
  getLeaves_data:([] path:(`pa;`pa`th;`pa`xx;`pa`th`testa;`pa`th`testb;`pa`xx`testa;`pa`xx`testb);
                     res:((`nodes;ll0);(`nodes;ll1);(`nodes;ll1);(`value;.executeSuite.testa);(`value;.executeSuite.testb);(`value;.executeSuite.testa);(`value;.executeSuite.testb)));
  .tree.getLeaves:{[tbl;tree;tp] first exec res from tbl where path ~\: tp}[getLeaves_data];
 };

getLeaves2:{[tree;tp]
  if[tp ~`pa`th;:(`nodes;`testa`testb`suite!(.executeSuite.testa;.executeSuite.testb;`testa`tesb!.executeSuite`testa`testb))];
  if[last[tp] ~ `testa;:(`value;.executeSuite.testa)];
  if[last[tp] ~ `testb;:(`value;.executeSuite.testb)];
  if[tp ~ `pa`th`suite;:(`nodes;`testa`testb!.executeSuite`testa`testb)];
  '"Unexpected tp argument: ",-3!tp;
  };

exp_speciallog:((beforeall;".pa";"BEFOREALL");
                (beforeall;".pa.th";"BEFOREALL");
                (afterall; ".pa.th";"AFTERALL");
                (beforeall;".pa.xx";"BEFOREALL");
                (afterall; ".pa.xx";"AFTERALL");
                (afterall; ".pa";"AFTERALL"));

mkExecTestArgs:{[args;v] @[args;`currPath`tns;{x,y};(v;".",string v)]};

\d .

executeSuite_base:{[]
  .executeSuite.setup[];
  .tree.getLeaves:{[t;p] (`value;.executeSuite.testa)};
 
  r:.qtb.priv.executeSuite .executeSuite.dfltargs;
  .executeSuite.restore[];

  :all (r ~ `testname`result`time!(`th;`succeeded;1.2f);
        .executeSuite.executeSpecial_log ~ ();
        .executeSuite.executeTest_log ~ enlist (.executeSuite.testa;@[.executeSuite.dfltargs;`tns;:;".pa.th"]));
  };


executeSuite_recurseOnce:{[]
  .executeSuite.setup[];
  r:.qtb.priv.executeSuite .executeSuite.dfltargs;
  .executeSuite.restore[];
 
  xab:@[.executeSuite.dfltargs;`overrides`tns;:;(.executeSuite.overrides;".pa.th")];
  xab:@[xab;`overrides`beforeeach`aftereach;:;.executeSuite`overrides`beforeeach`aftereach];
  xab:@[xab;`beforeeach`aftereach;enlist];
  exectestlog:{(x;y)}'[.executeSuite[`testa`testb];.executeSuite.mkExecTestArgs[xab] each `testa`testb];
 
  :all ((`th;([] testname:`testa`testb; result:`succeeded`succeeded; time:1.2 1.2f)) ~ r`suitename`tests;
        -12 -9h ~ type each r`start`time;
        .executeSuite.executeSpecial_log ~
        ((.executeSuite.beforeall;".pa.th";"BEFOREALL");(.executeSuite.afterall;".pa.th";"AFTERALL"));
        .executeSuite.executeTest_log ~ exectestlog);
  };

executeSuite_recurseTwice:{[]
  .executeSuite.setup[];
  r:.qtb.priv.executeSuite @[.executeSuite.dfltargs;`currPath;:;`pa]; 
  .executeSuite.restore[];

  xab:@[.executeSuite.dfltargs;`overrides`tns;:;(.executeSuite.overrides;".pa.th")];
  xab:@[xab;`beforeeach`aftereach;:;(.executeSuite each) each (`beforeeach_l`beforeeach;`aftereach_l`aftereach)];
  exectestlog:{(x;y)}'[.executeSuite[`testa`testb];.executeSuite.mkExecTestArgs[xab] each `testa`testb];
  exectestlog,:{(x;y)}'[.executeSuite[`testa`testb];.executeSuite.mkExecTestArgs[@[xab;`tns`currPath;:;(".pa.xx";`pa`xx)]] each `testa`testb];

  tres:([] testname:`testa`testb; result:`succeeded`succeeded; time:1.2 1.2f);
  ssuiteres:(`th`xx; 1.1 1.1; 2#enlist tres);
  :all ((`pa;1.1) ~ r`suitename`time;
         -12h = type r`start;
         ssuiteres ~ r[`tests;`suitename`time`tests];
        .executeSuite.executeSpecial_log ~ .executeSuite.exp_speciallog;
        .executeSuite.executeTest_log ~ exectestlog);
  };

executeSuite_recurseMixed:{[]
  .executeSuite.setup[];
  `.tree.getLeaves set .executeSuite.getLeaves2;
  r:.qtb.priv.executeSuite .executeSuite.dfltargs;
  .executeSuite.restore[];
  tres:([] testname:`testa`testb; result:`succeeded`succeeded; time:1.2 1.2f);
  :all R::((`th;1.1) ~ r`suitename`time;
        -12h = type r`start;
        r[`tests;0 1] ~ tres;
        (`suite;1.1) ~ r[`tests;2;`suitename`time];
        -12h = type r[`tests;2;`start];
        r[`tests;2;`tests] ~ tres);
  };

executeSuite_skip:{[]
 .executeSuite.setup[];
  r:.qtb.priv.executeSuite @[.executeSuite.dfltargs;`currPath`mode;:;`pa`skip];
 
  .executeSuite.restore[];

  tres:([] testname:`testa`testb; result:`skipped`skipped; time:0 0f);
  ssuiteres:(`th`xx; 1.1 1.1; 2#enlist tres);
  :all ((`pa;1.1) ~ r`suitename`time;
        -12h = type r`start;
        ssuiteres ~ r[`tests;`suitename`time`tests];
       .executeSuite.executeSpecial_log ~ ();
       .executeSuite.executeTest_log ~ ());
  };

executeSuite_beforeAllFail:{[]
  .executeSuite.setup[];
  .qtb.priv.executeSpecial::{[f;sns;spns] .executeSuite.executeSpecial_log,::enlist (f;sns;spns); not all (sns ~ ".pa.th";spns ~ "BEFOREALL")};

  r:.qtb.priv.executeSuite @[.executeSuite.dfltargs;`currPath;:;`pa]; 
  .executeSuite.restore[];
  exp_speciallog:.executeSuite.exp_speciallog 0 1 3 4 5;
 
  xab:@[.executeSuite.dfltargs;`overrides`tns;:;(.executeSuite.overrides;".pa.th")];
  xab:@[xab;`beforeeach`aftereach;:;(.executeSuite each) each (`beforeeach_l`beforeeach;`aftereach_l`aftereach)];
  exectestlog:{(x;y)}'[.executeSuite[`testa`testb];.executeSuite.mkExecTestArgs[@[xab;`tns`currPath;:;(".pa.xx";`pa`xx)]] each `testa`testb];
 
  tres_th:([] testname:`testa`testb; result:`skipped`skipped; time:0 0f);
  tres_xx:([] testname:`testa`testb; result:`succeeded`succeeded; time:1.2 1.2f);
  ssuiteres:(`th`xx; 1.1 1.1; (tres_th;tres_xx));
  :all ((`pa;1.1) ~ r`suitename`time;
        -12h = type r`start;
        ssuiteres ~ r[`tests;`suitename`time`tests];
        .executeSuite.executeSpecial_log ~ exp_speciallog;
        .executeSuite.executeTest_log ~ exectestlog);
  };

executeSuite_afterAllFail:{[]
 .executeSuite.setup[];
  .qtb.priv.executeSpecial::{[f;sns;spns] .executeSuite.executeSpecial_log,::enlist (f;sns;spns); not all (sns ~ ".pa.th";spns ~ "AFTERALL")};

  r:.qtb.priv.executeSuite @[.executeSuite.dfltargs;`currPath;:;`pa]; 
  .executeSuite.restore[];

  xab:@[.executeSuite.dfltargs;`overrides`tns;:;(.executeSuite.overrides;".pa.th")];
  xab:@[xab;`beforeeach`aftereach;:;(.executeSuite each) each (`beforeeach_l`beforeeach;`aftereach_l`aftereach)];
  exectestlog:{(x;y)}'[.executeSuite[`testa`testb];.executeSuite.mkExecTestArgs[@[xab;`tns;:;".pa.th"]] each `testa`testb];
  exectestlog,:{(x;y)}'[.executeSuite[`testa`testb];.executeSuite.mkExecTestArgs[@[xab;`tns`currPath;:;(".pa.xx";`pa`xx)]] each `testa`testb];

  tres_th:([] testname:`testa`testb; result:`broke`broke; time:1.2 1.2f);
  tres_xx:([] testname:`testa`testb; result:`succeeded`succeeded; time:1.2 1.2f);
  ssuiteres:(`th`xx; 1.1 1.1; (tres_th;tres_xx));
  :all ((`pa;1.1) ~ r`suitename`time;
        -12h = type r`start;
        ssuiteres ~ r[`tests;`suitename`time`tests];
        .executeSuite.executeSpecial_log ~ .executeSuite.exp_speciallog;
        .executeSuite.executeTest_log ~ exectestlog);
 };


executeSuite_basepathSuite:{[]
  .executeSuite.setup[];
  r:.qtb.priv.executeSuite oa:@[.executeSuite.dfltargs;`basepath`currPath;:;(`pa`th;`pa)];
 
  .executeSuite.restore[];
  exp_speciallog:.executeSuite.exp_speciallog 0 1 2 5;
 
  xab:@[oa;`overrides`tns;:;(.executeSuite.overrides;".pa.th")];
  xab:@[xab;`beforeeach`aftereach;:;(.executeSuite each) each (`beforeeach_l`beforeeach;`aftereach_l`aftereach)];
  exectestlog:{(x;y)}'[.executeSuite[`testa`testb];.executeSuite.mkExecTestArgs[@[xab;`tns`currPath;:;(".pa.th";`pa`th)]] each `testa`testb];

  tres:([] testname:`testa`testb; result:`succeeded`succeeded; time:1.2 1.2f);
  ssuiteres:(enlist `th; enlist 1.1;enlist tres);
  :all ((`pa;1.1) ~ r`suitename`time;
        -12h = type r`start;
        ssuiteres ~ r[`tests;`suitename`time`tests];
        .executeSuite.executeSpecial_log ~ exp_speciallog;
        .executeSuite.executeTest_log ~ exectestlog);
  };

executeSuite_basepathTest:{[]
 .executeSuite.setup[];
  r:.qtb.priv.executeSuite oa:@[.executeSuite.dfltargs;`basepath`currPath;:;(`pa`th`testb;`pa)];
 
  .executeSuite.restore[];
  exp_speciallog:.executeSuite.exp_speciallog 0 1 2 5;

  xab:@[oa;`overrides`tns;:;(.executeSuite.overrides;".pa.th")];
  xab:@[xab;`beforeeach`aftereach;:;(.executeSuite each) each (`beforeeach_l`beforeeach;`aftereach_l`aftereach)];
  exectestlog:enlist (.executeSuite[`testb];.executeSuite.mkExecTestArgs[@[xab;`tns`currPath;:;(".pa.th";`pa`th)]] each `testb);

  tres:enlist `testname`result`time!(`testb;`succeeded;1.2f);
  ssuiteres:(enlist `th;enlist 1.1;enlist tres);
  :all ((`pa;1.1) ~ r`suitename`time;
        -12h = type r`start;
        ssuiteres ~ r[`tests;`suitename`time`tests];
        .executeSuite.executeSpecial_log ~ exp_speciallog;.executeSuite.executeTest_log ~ exectestlog);
  };

executeSuite_invalidpath:{[]
  .executeSuite.setup[];
  .tree.getLeaves::{[tree;path] '"tree: invalid path"};
  
  r:@[.qtb.priv.executeSuite;@[.executeSuite.dfltargs;`currPath;:;`pa];{x}];
  
  .executeSuite.restore[];
  :("qtb: invalid path" ~ r) and (.executeSuite.executeTest_log ~ ()) and (.executeSuite.executeSpecial_log ~ ());
  };

executeSuite_SUITE:`executeSuite_base`executeSuite_recurseOnce`executeSuite_recurseTwice`executeSuite_recurseMixed,
                   `executeSuite_beforeAllFail`executeSuite_afterAllFail`executeSuite_basepathSuite`executeSuite_basepathTest,
                   `executeSuite_invalidpath`executeSuite_skip;

executeTestN_stdOverrides:{[]
  .orig.resetFuncallLog:.qtb.resetFuncallLog;
  .test.resetFuncallLog_calls:0;
  .qtb.resetFuncallLog::{[] .test.resetFuncallLog_calls+:1;};

  .orig.applyOverrides:.qtb.priv.applyOverrides;
  .test.applyOverrides_calls::();
  .qtb.priv.applyOverrides:{[x] .test.applyOverrides_calls,:enlist x; ([] vname:`$(); origValue:(); undef:`boolean$())};

  .test.revertOverrides_calls:();
  .orig.revertOverrides:.qtb.priv.revertOverrides;
  .qtb.priv.revertOverrides:{.test.revertOverrides_calls,:enlist x;};
  .orig.reportTestResult:.qtb.priv.reportTestResult;
  .test.reportTestResult_calls::();
  .qtb.priv.reportTestResult:{[a;b;c;d] .test.reportTestResult_calls,::enlist (a;b;c;d); };
  .orig.durationSeconds:.qtb.priv.durationSeconds;
  .qtb.priv.durationSeconds:{[x;y] 42f};
  };

executeTestN_resetStdOverrides:{[]
  .qtb.resetFuncallLog:.orig.resetFuncallLog;
  .qtb.priv.applyOverrides:.orig.applyOverrides;
  .qtb.priv.revertOverrides:.orig.revertOverrides;
  .qtb.priv.reportTestResult:.orig.reportTestResult;
  .qtn.priv.durationSeconds:.orig.durationSeconds;
  };

executeTestN_success:{[]
  executeTestN_stdOverrides[];
  r:.qtb.priv.executeTest[{};`nocatch`beforeeach`aftereach`tns`overrides`verbose`currPath!(0b;();();"executeTestN";(`$())!();0b;`he`re)];
  executeTestN_resetStdOverrides[];
  all (r ~ `testname`result`time!(`re;`succeeded;42f);
       1 = .test.resetFuncallLog_calls;
       .test.applyOverrides_calls ~ enlist (`$())!();
       .test.revertOverrides_calls ~ enlist ([] vname:`$(); origValue:(); undef:`boolean$());
       .test.reportTestResult_calls ~ enlist (0b;"executeTestN";`succeeded;"")) };

executeTestN_fail:{[]
  executeTestN_stdOverrides[];
  r:.qtb.priv.executeTest[{'"failing!"};`nocatch`beforeeach`aftereach`tns`overrides`verbose`currPath!(0b;();();"executeTestN";(`$())!();0b;`the`re)];
  executeTestN_resetStdOverrides[];
  all (r ~ `testname`result`time!(`re;`failed;42f);
       1 = .test.resetFuncallLog_calls;
       .test.applyOverrides_calls ~ enlist (`$())!();
       .test.revertOverrides_calls ~ enlist ([] vname:`$(); origValue:(); undef:`boolean$());
       (.test.reportTestResult_calls) ~ enlist (0b;"executeTestN";`failed;"failing!")) };

executeTestN_nocatch_success:{[]
  executeTestN_stdOverrides[];
  r:.qtb.priv.executeTest[{1b};`nocatch`beforeeach`aftereach`tns`overrides`verbose`currPath!(1b;();();"executeTestN";(`$())!();0b;`$())];
  executeTestN_resetStdOverrides[];
  r ~ `testname`result`time!(`;`succeeded;42f) };

executeTestN_nocatch_exception:{[]
  executeTestN_stdOverrides[];
  r:.test.checkException[.qtb.priv.executeTest;
                         ({'"jump!"};`nocatch`beforeeach`aftereach`tns`overrides`verbose!(1b;();();"executeTestN";(`$())!();0b));
                         "jump!"];
  executeTestN_resetStdOverrides[];
  r };

executeTestN_notafunc:{[]
  executeTestN_stdOverrides[];
  r:.qtb.priv.executeTest[42;`nocatch`beforeeach`aftereach`tns`overrides`verbose`currPath!(0b;();();"executeTestN";(`$())!();0b;`a`b)];
  executeTestN_resetStdOverrides[]; 
  r ~ `testname`result`time!(`b;`broke;0f)};

executeTestN_toomanyargs:{[]
  executeTestN_stdOverrides[];
  r:.qtb.priv.executeTest[{x+y};`nocatch`beforeeach`aftereach`tns`overrides`verbose`currPath!(0b;();();"executeTestN";(`$())!();0b;`x`y`z)];
  executeTestN_resetStdOverrides[]; 
  r ~ `testname`result`time!(`z;`broke;0f)};

.executeTestN.executeSpecial_log:();

executeTestN_beforeandafter:{[]
  executeTestN_stdOverrides[];
  .executeTestN.executeSpecial_log::();
  executeSpecial_orig:.qtb.priv.executeSpecial;
  .qtb.priv.executeSpecial:{[f;n;t] .executeTestN.executeSpecial_log,::enlist (f;n;t); 1b};
 
  beforeeaches:({[] `beforeeach_1};{[] `beforeeach_2};{[] `beforeeach_3});
  aftereaches:({[] `aftereach_1};{[] `aftereach_2});
 
  r:.qtb.priv.executeTest[{};`nocatch`beforeeach`aftereach`tns`overrides`verbose`currPath!(1b;beforeeaches;aftereaches;"executeTestN.beforeandafter";(`$())!();0b;`he`re)];
  executeTestN_resetStdOverrides[];
  testname:"executeTestN.beforeandafter";
  .qtb.priv.executeSpecial:executeSpecial_orig;
  all (r ~ `testname`result`time!(`re;`succeeded;42f);
       .executeTestN.executeSpecial_log ~
       ((;testname;"BEFOREEACH") each beforeeaches),(;testname;"AFTEREACH") each aftereaches) };

executeTestN_notest_beforeeacherr:{[]
  executeTestN_stdOverrides[];
  .executeTestN.executeSpecial_log::();
  executeSpecial_orig:.qtb.priv.executeSpecial;
  .qtb.priv.executeSpecial:{[f;n;t] .executeTestN.executeSpecial_log,::enlist (f;n;t); not f ~ {[] '"dingdong"} };
  
  beforeeaches:({[] `beforeeach_1};{[] '"dingdong"};{[] `beforeeach_3});
  aftereaches:({[] `aftereach_1};{[] `aftereach_2});
 
  r:.qtb.priv.executeTest[{[] 1b};`nocatch`beforeeach`aftereach`tns`overrides`verbose`currPath!(1b;beforeeaches;aftereaches;"executeTestN.notest_beforeerr";(`$())!();0b;`th`ere)];
  .qtb.priv.executeSpecial::executeSpecial_orig;
  executeTestN_resetStdOverrides[];
 
  :all (r ~ `testname`result`time!(`ere;`broke;42f);
       .executeTestN.executeSpecial_log ~ (;"executeTestN.notest_beforeerr";"BEFOREEACH") each beforeeaches;
       .test.reportTestResult_calls ~ enlist (0b;"executeTestN.notest_beforeerr";`broke;"beforeeach failure"));
  };

executeTestN_restoreOverrides_afterEachError:{[]
  executeTestN_stdOverrides[];
  executeSpecial_orig:.qtb.priv.executeSpecial;
  .executeTestN.executeSpecial_log::();
  .qtb.priv.executeSpecial:{[f;n;t] .executeTestN.executeSpecial_log,::enlist (f;n;t); not f ~ {[] '"dingdong"} };
  
  beforeeaches:({[] `beforeeach_1};{[] `beforeeach_3});
  aftereaches:({[] `aftereach_1};{[] '"dingdong"};{[] `aftereach_2});
 
  r:.qtb.priv.executeTest[{[] 1b};`nocatch`beforeeach`aftereach`tns`overrides`verbose`currPath!(1b;beforeeaches;aftereaches;"executeTestN.aftereach_error";(`$())!();0b;`a`b)];
  executeTestN_resetStdOverrides[];
  .qtb.priv.executeSpecial::executeSpecial_orig;
  :all (r ~ `testname`result`time!(`b;`broke;42f);
        .executeTestN.executeSpecial_log ~ ((;"executeTestN.aftereach_error";"BEFOREEACH") each beforeeaches),
                                            (;"executeTestN.aftereach_error";"AFTEREACH") each  aftereaches;
        .test.revertOverrides_calls ~ enlist ([] vname:`$(); origValue:(); undef:`boolean$());
        .test.reportTestResult_calls ~ enlist (0b;"executeTestN.aftereach_error";`broke;"aftereach failure"));
 };

executeTestN_SUITE:`executeTestN_success`executeTestN_fail`executeTestN_notafunc`executeTestN_toomanyargs,
                   `executeTestN_beforeandafter`executeTestN_notest_beforeeacherr`executeTestN_nocatch_success,
                   `executeTestN_nocatch_exception`executeTestN_restoreOverrides_afterEachError;

applyOverrides_all:{[]
  applyOverride_orig:.qtb.priv.applyOverride; 
  .qtb.priv.applyOverride:{[vn;vv] applyOverride_log,::enlist (vn;vv); `vname`origValue`undef!(vn;42;0b)};
  applyOverride_log::();
  r1:.qtb.priv.applyOverrides `a`b`c!(`x;42;"lo");
  log1:applyOverride_log;
  applyOverride_log::();
  r2:.qtb.priv.applyOverrides .qtb.priv.genDict;
  .qtb.priv.applyOverride::applyOverride_orig;
  :all (r1 ~ ([] vname:`a`b`c; origValue:42 42 42; undef:000b);(`a`x;(`b;42);(`c;"lo")) ~ log1;
        r2 ~ ();applyOverride_log ~ ());
 
  };

applyOverride_all:{[]
  OVERRIDETARGET1::42;
  r1:.qtb.priv.applyOverride[`OVERRIDETARGET1;`hello];
  r2:.qtb.priv.applyOverride[`OVERRIDETARGET2;`hello];
  .test.OVERRIDETARGET1::43;
  r3:.qtb.priv.applyOverride[`.test.OVERRIDETARGET1;`hello];
  r4:.qtb.priv.applyOverride[`.test.OVERRIDETARGET2;`hello];
  checkvalue:{[vn;val] $[() ~ key vn;0b;val ~ value vn]};
  tr:all (r1 ~ `vname`origValue`undef!(`OVERRIDETARGET1;42;0b);
          checkvalue[`OVERRIDETARGET1;`hello];
          r2 ~ `vname`origValue`undef!(`OVERRIDETARGET2;(::);1b);
          checkvalue[`OVERRIDETARGET2;`hello];
          r3 ~ `vname`origValue`undef!(`.test.OVERRIDETARGET1;43;0b);
          checkvalue[`.test.OVERRIDETARGET1;`hello];
          r4 ~ `vname`origValue`undef!(`.test.OVERRIDETARGET2;(::);1b);
          checkvalue[`.test.OVERRIDETARGET2;`hello]);
  delete OVERRIDETARGET1 from `.;
  delete OVERRIDETARGET2 from `.;
  delete OVERRIDETARGET1 from `.test;
  delete OVERRIDETARGET2 from `.test;
  :tr;
  };

revertOverride_all:{[]
  OVERRIDETARGET1::42;
  OVERRIDETARGET2::`xxx;
  .z.exit:{[] `exit;};
  .test.OTGT1:`a`b`c;
  .test.sctx.OTGT2:{};
  .qtb.priv.revertOverride[`OVERRIDETARGET1;0;0b];
  .qtb.priv.revertOverride[`.z.exit;42;0b];
  .qtb.priv.revertOverride[`.test.OTGT1;"lolo";0b];
  .qtb.priv.revertOverride[`.test.sctx.OTGT2;([] c:1 2);0b];
  alltgts:`OVERRIDETARGET1`OVERRIDETARGET2`.z.exit`.test.OTGT1`.test.sctx.OTGT2;
  rvals1:get each alltgts;
  .qtb.priv.revertOverride[;(::);1b] each alltgts;
  undefs:key each alltgts;
  delete OVERRIDETARGET1 from `.;
  delete OVERRIDETARGET2 from `.;
  system "x .z.exit";
  delete OTGT1 from `.test;
  delete OTGT2 from `.test.sctx;
  :all (rvals1 ~' (0;`xxx;42;"lolo";([] c:1 2))),undefs ~' (count alltgts)#enlist ();
  };

testf1:{[] 42};
testf2:{(`f1;x)};
testf3:{(`f2;x;y)};

callLog_all:{[]
  .qtb.resetFuncallLog[]; 
  r11:(.qtb.callLogNoret`testf1)[]; 
  r12:(.qtb.callLogSimple[`testf1;`x])[];
  r13:(.qtb.callLog[`testf1;{(`a;x)}])[];
  e1:.[.qtb.callLog;(`testf1;{x+y});(::)];
  r21:(.qtb.callLogSimple[`testf2;([] c:1 2 3)])[3];
  r22:(.qtb.callLog[`testf2;{(`b;x)}])[4];
  r23:(.qtb.callLog[`testf2;{(`b;x)}])[(`x;4)];
  e2:.[.qtb.callLog;(`testf2;{x+y});(::)];
  r31:(.qtb.callLogSimple[`testf3;`a`b!1 2])[`x;2];
  r32:(.qtb.callLog[`testf3;{(`x;x;y)}])[`x;2];
  r33::(.qtb.callLog[`testf3;{(`x;x;y)}])[1 2;`x`y];
  e3:.[.qtb.callLog;(`testf3;{x+y+z});(::)];
  exp_callLog:([] functionName:``testf1`testf1`testf1`testf2`testf2`testf2`testf3`testf3`testf3;
                   arguments:(::),enlist'[((::);(::);(::);3;4)],((`x;4);(`x;2);(`x;2);(1 2;`x`y)));
  :all (r11 ~ (::);
        r12 ~ `x;
        r13 ~ (`a;(),(::));
        r21 ~ ([] c:1 2 3);
        r22 ~ (`b;enlist 4);
        r23 ~ (`b;(`x;4));
        r31 ~ `a`b!1 2;
        r32 ~ (`x;`x;2);
        r33 ~ (`x;1 2;`x`y)),
        ((e1;e2;e3) ~\: "argument count does not match"),
       enlist exp_callLog ~ .qtb.getFuncallLog[];
  };

parseCmdline_all:{[]
  baseres:`run`verbose`junit`debug!(0b;0b;`;0b);
  r1:baseres ~ .qtb.priv.parseCmdline ();
  r2:@[baseres;`verbose;:;1b] ~ .qtb.priv.parseCmdline enlist "-qtb-verbose";
  r3:@[baseres;`verbose;:;1b] ~ .qtb.priv.parseCmdline ("-qtb-verbose";(),"1");
  r4:@[baseres;`run;:;1b] ~ .qtb.priv.parseCmdline enlist "-qtb-run";
  r5:@[baseres;`debug;:;1b] ~ .qtb.priv.parseCmdline enlist "-qtb-debug";
  r6:@[baseres;`junit`run;:;(`xxx;1b)] ~ .qtb.priv.parseCmdline ("-qtb-junit";"xxx";"-qtb-run");
  .q.system:{1i};
  r7:@[baseres;`run`debug;:;11b] ~ .qtb.priv.parseCmdline enlist "-qtb-run";
  r8:@[baseres;`debug;:;1b] ~ .qtb.priv.parseCmdline enlist "-qtb-debug";
  .q.system:system;
  :all (r1;r2;r3;r4;r5;r6;r7;r8);
  };

testResTree2Tbl_all:{[]
  tres:([] testname:`testa`testb; result:`succeeded`failed; time:1.2 0.01f),(::);
  subsuite1:enlist `suitename`start`time`tests!(`te;2018.11.11D11:11:11.0;1.1;-1 _ tres);
  subsuite2:enlist `suitename`start`time`tests!(`st;2018.02.02D02:02:02.0;2.2;-1 _ tres);
  basesuite:`suitename`start`time`tests!(`root;2018.03.03D03:03:03.0;0.3;(subsuite1,tres,subsuite2) 0 1 2 4);
  r:.qtb.priv.testResTree2Tbl[(),`x;basesuite];
  :r ~ ([] testname:(`x`root`te`testa;`x`root`te`testb;`x`root`testa;`x`root`testb;`x`root`st`testa;`x`root`st`testb);
           result:`succeeded`failed`succeeded`failed`succeeded`failed;
           time:1.2 0.01 1.2 0.01 1.2 0.01);
  };

testResTree2JunitXml_all:{[]
  tres:([] testname:`testa`testb`testc; result:`succeeded`failed`error; time:1.2 0.01 0f),(::);
  subsuite1:enlist `suitename`start`time`tests!(`te;2018.11.11D11:11:11.0;1.1;-1 _ tres);
  subsuite2:enlist `suitename`start`time`tests!(`st;2018.02.02D02:02:02.0;2.2;-1 _ tres);
  basesuite:`suitename`start`time`tests!(`root;2018.03.03D03:03:03.0;0.3;(subsuite1,tres,subsuite2) 0 1 2 3 5);
  tresdoc:("  <testcase name=\"testa\" classname=\"\" time=\"1.200\" />";
           "  <testcase name=\"testb\" classname=\"\" time=\"0.010\">";"    <failure type=\"failed\"/>";"  </testcase>";
           "  <testcase name=\"testc\" classname=\"\" time=\"0.000\">";   "    <error type=\"broke\"/>";"  </testcase>");
  rootsuite:"<testsuite name=\"root\" package=\"\" hostname=\"",string[.z.h],"\" errors=\"1\" failures=\"1\" tests=\"3\" timestamp=\"2018-03-03T03:03:03\" time=\"0.300\">";
  te_suite:"<testsuite name=\"root.te\" package=\"\" hostname=\"",string[.z.h],"\" errors=\"1\" failures=\"1\" tests=\"3\" timestamp=\"2018-11-11T11:11:11\" time=\"1.100\">";
  st_suite:"<testsuite name=\"root.st\" package=\"\" hostname=\"",string[.z.h],"\" errors=\"1\" failures=\"1\" tests=\"3\" timestamp=\"2018-02-02T02:02:02\" time=\"2.200\">";
  expdoc:raze {[td;ste] (ste;"  <properties />"),td,("  <system-out />";"  <system-err />";"</testsuite>")}[tresdoc] each (rootsuite;te_suite;st_suite);
  :expdoc ~ .qtb.priv.testResTree2JunitXml[0;`$();basesuite];
  };

assertStr_all:{[]
  `V set `u#`x`y;
  ev:`V$`y`x`x`y;
  data:([] v:(0Ng;1b;`x;42f;(`x;42);"lolo";`a`b;.z.d;ev 0;til 3;ev 0 1);
           estr:("00000000-0000-0000-0000-000000000000";(),"1";(),"x";"42";"(`x;42)";"lolo";"`a`b";string .z.d;(),"y";"0 1 2";"`V$`y`x"));
  out:update astr:.qtb.assert.str each v from data;
  delete V from `.;
  mm::select from out where not estr~'astr;
  if[0 = count mm;:1b];
  -1 "Unexpected output from assert.str:";
  show mm;
  :0b;
 };

catchx:{[f;args]
  cf:$[1 = {count x 1} value f;@;.];
  :.[{[w;f;a] (1b;w[f;a])};(cf;f;args);(0b;)];
  };

assertfunc_all:{[]
  r1:(1b;::) ~ catchx[.qtb.assert.wrapassert;({[x;y] 1b};"checkfunc";1 2)];
  r2:(0b;"Expected '1' checkfunc '2'") ~ catchx[.qtb.assert.wrapassert;({[x;y] 0b};"checkfunc";1 2)];
  r3:(0b;"foo") ~ catchx[.qtb.assert.wrapassert;({[x;y] 0b};{[x;y] "foo"};1 2)];
  :all (r1;r2;r3);
  };


assert_throws_ok:{[] (1b;::) ~ catchx[.qtb.assert.throws;(({[x] '"boom!"};42);"boom!")] };

testfunc:{[x] 42};
assert_throws_notok:{[]
  :(0b;"(`testfunc;42) did not throw any exception") ~ catchx[.qtb.assert.throws;((`testfunc;42);"catch me!")];
  };

assert_throws_other:{[] not first catchx[.qtb.assert.throws;(({[dummy] '"catch me!"};42);"hey!")] };

assert_throws_SUITE:`assert_throws_ok`assert_throws_notok`assert_throws_other;

otherasserts_all:{[]
  r1:(1b;(::)) ~ catchx[.qtb.assert.matches .;1 1];
  r2:(0b;"Expected '1' to match '2'") ~ catchx[.qtb.assert.matches .;1 2];
  r3:(0b;"Expected '1' to be equal to '2'") ~ catchx[.qtb.assert.equals .;1 2];
  r4:(0b;"Expected '1' to be within '5 10'") ~ catchx[.qtb.assert.within .;(1;5 10)];
  r5:(0b;"Expected 'xx' to match the pattern 'ab'") ~ catchx[.qtb.assert.like .;(`xx;"ab")];
  :all (r1;r2;r3;r4;r5);
  };

override_simple:{[tgt;val] curr:get tgt;tgt set val; curr};

run_overrides:{[]
  `TESTARGS set `run`debug!00b;
  `CALLOG set ();
  `RESULTS set ([] result:2#`succeeded);
  :((`scriptWithArgs;override_simple[`.qtb.priv.scriptWithArgs;{1b}]);
    (`parseCmdline;override_simple[`.qtb.priv.parseCmdline;{[x] TESTARGS}]);
    (`start;override_simple[`.qtb.priv.start;{CALLOG,::enlist (`start;x);RESULTS}]);
    (`println;override_simple[`.qtb.priv.println;{CALLOG,::enlist (`println;x);(::)}]);
    (`exit;override_simple[`.qtb.priv.exit;{CALLOG,::enlist(`exit;x);:(::)}]));
  };

run_restore:{[origs]
  delete TESTARGS from `.;
  delete CALLOG from `.;
  delete RESULTS from `.;
  .[set]'[origs];
  };
  

run_norun:{[]
  origs:run_overrides[];
  .qtb.run[];
  r:CALLOG ~ ();
  run_restore origs;
  :r;
  };

run_normal_aok:{[]
  origs:run_overrides[];
  TESTARGS[`run]:1b;
  .qtb.run[];
  r:CALLOG ~ ((`start;TESTARGS);(`exit;1b));
  run_restore origs;
  :r;
  };

run_normal_fail:{[]
  origs:run_overrides[];
  TESTARGS[`run]:1b;
  .[`RESULTS;(1;`result);:;`failed];
  .qtb.run[];
  r:CALLOG ~ ((`start;TESTARGS);(`exit;0b));
  run_restore origs;
  :r;
  };

run_debug_aok:{[]
  origs:run_overrides[];
  TESTARGS[`run]:1b;TESTARGS[`debug]:1b;
  .qtb.run[];
  r:CALLOG ~ enlist (`start;TESTARGS);
  run_restore origs;
  :r;
  };

run_debug_fail:{[]
  origs:run_overrides[];
  TESTARGS[`run]:1b;TESTARGS[`debug]:1b;
  .[`RESULTS;(1;`result);:;`failed];
  .qtb.run[];
  r:CALLOG ~ enlist (`start;TESTARGS);
  run_restore origs;
  :r;
  };

run_normal_ex:{[]
  origs:run_overrides[];
  TESTARGS[`run]:1b;
  `.qtb.priv.start set {[x] CALLOG,::enlist (`start;x);'"duh!"};
  .qtb.run[];
  r:CALLOG ~ ((`start;TESTARGS);(`println;"Caught exception: duh!");(`exit;0b));
  run_restore origs;
  :r;
  };

run_debug_ex:{[]
  origs:run_overrides[];
  TESTARGS[`run]:1b;TESTARGS[`debug]:1b;
  `.qtb.priv.start set {[x] CALLOG,::enlist (`start;x);'"duh!"};
  rr:catchx[.qtb.run;::];
  r:all (CALLOG ~ enlist (`start;TESTARGS);rr ~ (0b;"duh!"));
  run_restore origs;
  :r;
  };

run_SUITE:`run_norun`run_normal_aok`run_normal_fail`run_debug_aok`run_debug_fail`run_normal_ex`run_debug_ex;


ALLTESTS:`privExecuteN_all,execute_SUITE,try_SUITE,countargs_SUITE,isEmptyFunc_SUITE,executeSpecial_SUITE,
         `matchPaths_all,executeSuite_SUITE,executeTestN_SUITE,`applyOverrides_all,`applyOverride_all,
         `revertOverride_all`callLog_all`parseCmdline_all`testResTree2Tbl_all`testResTree2JunitXml_all,
          `assertStr_all`assertfunc_all,assert_throws_SUITE,`otherasserts_all,run_SUITE;

