/////////////////////////////////////
// Unit tests for the Q Test Bench

\l qtb-s.q

\l ../tb/testbench.q

privExecuteN_all:{[]
  executeSuite_orig:.qtb.priv.executeSuite;
  .qtb.priv.executeSuite::{[x] 3#`success};
  
  res1::.qtb.priv.execute[1b;`];
  .qtb.priv.executeSuite::{[x] `success`error`success};
  res2::.qtb.priv.execute[1b;`a`b];
 
  .qtb.priv.executeSuite::executeSuite_orig;
   :all (res1;not res2);
   };


initTestSuite:{[]
  .qtb.priv.ALLTESTS:.tree.new[];
  execute_root_beforeAll_flag::0b;
  .qtb.addBeforeAll[`;{[] execute_root_beforeAll_flag::1b;}];
  execute_root_afterAll_flag::0b;
  .qtb.addAfterAll[`;{[] execute_root_afterAll_flag::1b;}];
  execute_root_test_flag::0b;  
  .qtb.addTest[`noexec;{[] execute_root_test_flag::1b; 0b}];
  .qtb.suite `realtests;
  execute_realtest_beforeAll_flag::0b;
  .qtb.addBeforeAll[`realtests;{[] execute_realtest_beforeAll_flag::1b;}];
  execute_realtest_afterAll_flag::0b;
  .qtb.addAfterAll[`realtests;{[] execute_realtest_afterAll_flag::1b;}];
  execute_realtest_beforeEach_counter::0;  
  .qtb.addBeforeEach[`realtests;{[] execute_realtest_beforeEach_counter+::1;}];
  execute_realtest_afterEach_counter::0;  
  .qtb.addAfterEach[`realtests;{[] execute_realtest_afterEach_counter+::1;}];
  .qtb.addTest[`realtests`a;{[] 0b}];
  .qtb.addTest[`realtests`b;{[] 1b}];
  };

execute_base:{[]
  initTestSuite[];
  tr:.qtb.execute `realtests;
  all .qtb.matchValue ./: (("Return value";0b;tr);
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
  r:all .qtb.matchValue ./: (("Return value";0b;tr);
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
  r:all .qtb.matchValue ./: (("Return value";0b;tr);
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
  r:all .qtb.matchValue ./: (("Return value";1b;tr);
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

catchX_noarg_noerr:{[] (`success;42)    ~ .qtb.catchX[{[] 42};(::)]     };
catchX_noarg_error:{[] (`exceptn;"Yo!") ~ .qtb.catchX[{[] '"Yo!"};(::)] };

catchX_oneargsimple_noerr:{[] (`success;1b) ~ .qtb.catchX[{x ~ 42};42] };
catchX_oneargsimple_error:{[] (`exceptn;"42") ~ .qtb.catchX[{'string x};42] };

catchX_oneargsym_noerr:{[] (`success;1b) ~ .qtb.catchX[{x ~ `xx};`xx] };
catchX_oneargsym_error:{[] (`exceptn;"xx") ~ .qtb.catchX[{'string x};`xx] };

catchX_onearglist_noerr:{[] (`success;1b) ~ .qtb.catchX[{x ~ 2 1};2 1] };
catchX_onearglist_error:{[] (`exceptn;"1",()) ~ .qtb.catchX[{'string x ~ 2 1};2 1] };

catchX_oneargsymlist_noerr:{[] (`success;1b) ~ .qtb.catchX[{x ~ `a`b};`a`b] };
catchX_oneargsymlist_error:{[] (`exceptn;"1",()) ~ .qtb.catchX[{'string x ~ `x`y};`x`y] };

catchX_oneargtbl_noerr:{[] tt:([] c:1 2); (`success;tt) ~ .qtb.catchX[{x};tt] };
catchX_oneargtbl_error:{[] tt:([] c:1 2); (`exceptn;"1",()) ~ .qtb.catchX[{[t;x] 'string t ~ x}[tt;];tt] };

catchX_oneargdict_noerr:{[] d:`a`b!1 2; (`success;d) ~ .qtb.catchX[{x};d] };
catchX_oneargdict_error:{[] d:`a`b!1 2; (`exceptn;"1",()) ~ .qtb.catchX[{[t;x] 'string t ~ x}[d;];d] };

catchX_twoargsimple_noerr:{[] (`success;42 -1) ~ .qtb.catchX[{(x;y)};42 -1] };
catchX_twoargsimple_error:{[] (`exceptn;"42 -1") ~ .qtb.catchX[{'" " sv string (x;y)};42 -1] };

catchX_twoarglist_noerr:{[] l1:42 -1; l2:`a`b; (`success;(l1;l2)) ~ .qtb.catchX[{(x;y)};(l1;l2)] };
catchX_twoarglist_error:{[] l1:42 -1; l2:`a`b; (`exceptn;"1",()) ~ .qtb.catchX[{[e;x;y] 'string e ~ (x;y)}[(l1;l2);;];(l1;l2)] };

catchX_SUITE:`catchX_noarg_noerr`catchX_noarg_error`catchX_oneargsimple_noerr`catchX_oneargsimple_error,
             `catchX_oneargsym_noerr`catchX_oneargsym_error`catchX_onearglist_noerr`catchX_onearglist_error,
             `catchX_oneargsymlist_noerr`catchX_oneargsymlist_error`catchX_oneargtbl_noerr`catchX_oneargtbl_error,
             `catchX_oneargdict_noerr`catchX_oneargdict_error`catchX_twoargsimple_noerr`catchX_twoargsimple_error,
             `catchX_twoarglist_noerr`catchX_twoarglist_error;

checkX_ok:{[] .qtb.checkX[{[dummy] '"catch me!"};42;"catch me!"] };

checkX_notok:{[] not .qtb.checkX[{[dummy]};42;"catch me!"] };

checkX_other:{[] not .qtb.checkX[{[dummy] '"catch me!"};42;"hey!"] };

checkX_error:{[]
  catchX_orig:.qtb.catchX;
  .qtb.catchX::{[f;args]}; // just do nothing
  r:.test.checkException[.qtb.checkX;(`f;`arg;"somex");"qtb: catchX failed to return a valid result"];
  .qtb.catchX::catchX_orig;
  r };

checkX_SUITE:`checkX_ok`checkX_ok`checkX_error`checkX_other;

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

isEmptyFunc_error:{[] all not .qtb.priv.isEmptyFunc @/: (1;`answer;3 4f)};

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
  alltests_orig::.qtb.priv.ALLTESTS;
  .qtb.priv.ALLTESTS::42;
  
  tree_getLeaves_orig::.tree.getLeaves;
  override_getLeaves[];
 
  executeSpecial_log::();
  executeSpecial_orig::.qtb.priv.executeSpecial;
  .qtb.priv.executeSpecial::{[f;sp;n] executeSpecial_log,::enlist (f;sp;n); 1b};
  
  executeTest_orig::.qtb.priv.executeTest;
  executeTest_log::();
  .qtb.priv.executeTest::{[tf;params] executeTest_log,::enlist (tf;params); `success};
  dfltargs::`nocatch`basepath`beforeeach`aftereach`overrides`currPath`mode`verbose!(0b;`$();();();(`$())!();`pa`th;`exec;1b);
  };

restore:{[]
  ALLTESTS::alltests_orig;
  .tree.getLeaves::tree_getLeaves_orig;
  .qtb.priv.executeSpecial::executeSpecial_orig;
  .qtb.priv.executeTest::executeTest_orig;
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

  :all (`success ~ r;.executeSuite.executeSpecial_log ~ ();
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
 
  :all (`success`success ~ r;
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
 
  :all (`success`success`success`success ~ r;
        .executeSuite.executeSpecial_log ~ .executeSuite.exp_speciallog;
        .executeSuite.executeTest_log ~ exectestlog);
  };

executeSuite_skip:{[]
 .executeSuite.setup[];
  r:.qtb.priv.executeSuite @[.executeSuite.dfltargs;`currPath`mode;:;`pa`skip];
 
  .executeSuite.restore[];
 
  :all (`skipped`skipped`skipped`skipped ~ r;.executeSuite.executeSpecial_log ~ ();.executeSuite.executeTest_log ~ ());
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
 
  :all (`skipped`skipped`success`success ~ r;.executeSuite.executeSpecial_log ~ exp_speciallog;.executeSuite.executeTest_log ~ exectestlog);
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
 
  :all (`broke`broke`success`success ~ r;.executeSuite.executeSpecial_log ~ .executeSuite.exp_speciallog;.executeSuite.executeTest_log ~ exectestlog);
 };


executeSuite_basepathSuite:{[]
  .executeSuite.setup[];
  r:.qtb.priv.executeSuite oa:@[.executeSuite.dfltargs;`basepath`currPath;:;(`pa`th;`pa)];
 
  .executeSuite.restore[];
  exp_speciallog:.executeSuite.exp_speciallog 0 1 2 5;
 
  xab:@[oa;`overrides`tns;:;(.executeSuite.overrides;".pa.th")];
  xab:@[xab;`beforeeach`aftereach;:;(.executeSuite each) each (`beforeeach_l`beforeeach;`aftereach_l`aftereach)];
  exectestlog:{(x;y)}'[.executeSuite[`testa`testb];.executeSuite.mkExecTestArgs[@[xab;`tns`currPath;:;(".pa.th";`pa`th)]] each `testa`testb];
 
  :all (`success`success ~ r;.executeSuite.executeSpecial_log ~ exp_speciallog;.executeSuite.executeTest_log ~ exectestlog);
  };

executeSuite_basepathTest:{[]
 .executeSuite.setup[];
  r:.qtb.priv.executeSuite oa:@[.executeSuite.dfltargs;`basepath`currPath;:;(`pa`th`testb;`pa)];
 
  .executeSuite.restore[];
  exp_speciallog:.executeSuite.exp_speciallog 0 1 2 5;

  xab:@[oa;`overrides`tns;:;(.executeSuite.overrides;".pa.th")];
  xab:@[xab;`beforeeach`aftereach;:;(.executeSuite each) each (`beforeeach_l`beforeeach;`aftereach_l`aftereach)];
  exectestlog:enlist (.executeSuite[`testb];.executeSuite.mkExecTestArgs[@[xab;`tns`currPath;:;(".pa.th";`pa`th)]] each `testb);
 
  :all (((),`success) ~ r;.executeSuite.executeSpecial_log ~ exp_speciallog;.executeSuite.executeTest_log ~ exectestlog);
  };

executeSuite_invalidpath:{[]
  .executeSuite.setup[];
  .tree.getLeaves::{[tree;path] '"tree: invalid path"};
  
  r:@[.qtb.priv.executeSuite;@[.executeSuite.dfltargs;`currPath;:;`pa];{x}];
  
  .executeSuite.restore[];
  :("qtb: invalid path" ~ r) and (.executeSuite.executeTest_log ~ ()) and (.executeSuite.executeSpecial_log ~ ());
  };


executeSuite_SUITE:`executeSuite_base`executeSuite_recurseOnce`executeSuite_recurseTwice`executeSuite_beforeAllFail,
                   `executeSuite_afterAllFail`executeSuite_basepathSuite`executeSuite_basepathTest`executeSuite_invalidpath,
                   `executeSuite_skip;

executeTestN_stdOverrides:{[]
  .orig.catchX:.qtb.catchX;
  .qtb.catchX::{[f;a] (`success;1b)};
 
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
  .qtb.priv.reportTestResult:{[a;b;c;d] .test.reportTestResult_calls,::enlist (a;b;c;d)};
  };

executeTestN_resetStdOverrides:{[]
  .qtb.catchX:.orig.catchX;
  .qtb.resetFuncallLog:.orig.resetFuncallLog;
  .qtb.priv.applyOverrides:.orig.applyOverrides;
  .qtb.priv.revertOverrides:.orig.revertOverrides;
  .qtb.priv.reportTestResult:.orig.reportTestResult;
  };

executeTestN_success:{[]
  executeTestN_stdOverrides[];
  r:.qtb.priv.executeTest[{1b};`nocatch`beforeeach`aftereach`tns`overrides`verbose!(0b;();();"executeTestN";(`$())!();0b)];
  executeTestN_resetStdOverrides[];
  all (r ~ `success;
       1 = .test.resetFuncallLog_calls;
       .test.applyOverrides_calls ~ enlist (`$())!();
       .test.revertOverrides_calls ~ enlist ([] vname:`$(); origValue:(); undef:`boolean$());
       .test.reportTestResult_calls ~ enlist (0b;"executeTestN";`success;"")) };

executeTestN_fail:{[]
  executeTestN_stdOverrides[];
  .qtb.catchX::{[f;a] (`success;0b)};
  r:.qtb.priv.executeTest[{};`nocatch`beforeeach`aftereach`tns`overrides`verbose!(0b;();();"executeTestN";(`$())!();0b)];
  executeTestN_resetStdOverrides[];
  all (r ~ `failed;
       1 = .test.resetFuncallLog_calls;
       .test.applyOverrides_calls ~ enlist (`$())!();
       .test.revertOverrides_calls ~ enlist ([] vname:`$(); origValue:(); undef:`boolean$());
       .test.reportTestResult_calls ~ enlist (0b;"executeTestN";`failed;"")) };

executeTestN_exception:{[]
  executeTestN_stdOverrides[];
  .qtb.catchX::{[f;a] (`exceptn;"poof")};
  r:.qtb.priv.executeTest[{};`nocatch`beforeeach`aftereach`tns`overrides`verbose!(0b;();();"executeTestN";(`$())!();0b)];
  executeTestN_resetStdOverrides[];
  all (r ~ `error;
       1 = .test.resetFuncallLog_calls;
       .test.applyOverrides_calls ~ enlist (`$())!();
       .test.revertOverrides_calls ~ enlist ([] vname:`$(); origValue:(); undef:`boolean$());
       .test.reportTestResult_calls ~ enlist (0b;"executeTestN";`error;"exception: poof")) };

executeTestN_other:{[]
  executeTestN_stdOverrides[];
  .qtb.catchX::{[f;a] (`success;42)};
  r:.qtb.priv.executeTest[{42};`nocatch`beforeeach`aftereach`tns`overrides`verbose!(0b;();();"executeTestN";(`$())!();0b)];  
  executeTestN_resetStdOverrides[];
  all (r ~ `broke;
       1 = .test.resetFuncallLog_calls;
       .test.applyOverrides_calls ~ enlist (`$())!();
       .test.revertOverrides_calls ~ enlist ([] vname:`$(); origValue:(); undef:`boolean$());
       .test.reportTestResult_calls ~ enlist (0b;"executeTestN";`broke;"unexpected return value")) };

executeTestN_nocatch_success:{[]
  executeTestN_stdOverrides[];
  r:.qtb.priv.executeTest[{1b};`nocatch`beforeeach`aftereach`tns`overrides`verbose!(1b;();();"executeTestN";(`$())!();0b)];
  executeTestN_resetStdOverrides[];
  r ~ `success };

executeTestN_nocatch_exception:{[]
  executeTestN_stdOverrides[];
  r:.test.checkException[.qtb.priv.executeTest;
                         ({'"jump!"};`nocatch`beforeeach`aftereach`tns`overrides`verbose!(1b;();();"executeTestN";(`$())!();0b));
                         "jump!"];
  executeTestN_resetStdOverrides[];
  r };

executeTestN_notafunc:{[]
  executeTestN_stdOverrides[];
  r:.qtb.priv.executeTest[42;`nocatch`beforeeach`aftereach`tns`overrides`verbose!(0b;();();"executeTestN";(`$())!();0b)];
  executeTestN_resetStdOverrides[]; 
  r ~ `broke};

executeTestN_toomanyargs:{[]
  executeTestN_stdOverrides[];
  r:.qtb.priv.executeTest[{x+y};`nocatch`beforeeach`aftereach`tns`overrides`verbose!(0b;();();"executeTestN";(`$())!();0b)];
  executeTestN_resetStdOverrides[]; 
  r ~ `broke};

.executeTestN.executeSpecial_log:();

executeTestN_beforeandafter:{[]
  executeTestN_stdOverrides[];
  .executeTestN.executeSpecial_log::();
  executeSpecial_orig:.qtb.priv.executeSpecial;
  .qtb.priv.executeSpecial:{[f;n;t] .executeTestN.executeSpecial_log,::enlist (f;n;t); 1b};
 
  beforeeaches:({[] `beforeeach_1};{[] `beforeeach_2};{[] `beforeeach_3});
  aftereaches:({[] `aftereach_1};{[] `aftereach_2});
 
  r:.qtb.priv.executeTest[{0b};`nocatch`beforeeach`aftereach`tns`overrides`verbose!(1b;beforeeaches;aftereaches;"executeTestN.beforeandafter";(`$())!();0b)];
  executeTestN_resetStdOverrides[];
  testname:"executeTestN.beforeandafter";
  .qtb.priv.executeSpecial:executeSpecial_orig;
  all (r ~ `failed;
       .executeTestN.executeSpecial_log ~
       ((;testname;"BEFOREEACH") each beforeeaches),(;testname;"AFTEREACH") each aftereaches) };

executeTestN_notest_beforeeacherr:{[]
  executeTestN_stdOverrides[];
  .executeTestN.executeSpecial_log::();
  executeSpecial_orig:.qtb.priv.executeSpecial;
  .qtb.priv.executeSpecial:{[f;n;t] .executeTestN.executeSpecial_log,::enlist (f;n;t); not f ~ {[] '"dingdong"} };
  
  beforeeaches:({[] `beforeeach_1};{[] '"dingdong"};{[] `beforeeach_3});
  aftereaches:({[] `aftereach_1};{[] `aftereach_2});
 
 r:.qtb.priv.executeTest[{[] 1b};`nocatch`beforeeach`aftereach`tns`overrides`verbose!(1b;beforeeaches;aftereaches;"executeTestN.notest_beforeerr";(`$())!();0b)];
  .qtb.priv.executeSpecial::executeSpecial_orig;
  executeTestN_resetStdOverrides[];
 
  :all (r ~ `broke;
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
 
  r:.qtb.priv.executeTest[{[] 1b};`nocatch`beforeeach`aftereach`tns`overrides`verbose!(1b;beforeeaches;aftereaches;"executeTestN.aftereach_error";(`$())!();0b)];
  executeTestN_resetStdOverrides[];
  .qtb.priv.executeSpecial::executeSpecial_orig;
  :all (r ~ `broke;
        .executeTestN.executeSpecial_log ~ ((;"executeTestN.aftereach_error";"BEFOREEACH") each beforeeaches),
                                            (;"executeTestN.aftereach_error";"AFTEREACH") each  aftereaches;
        .test.revertOverrides_calls ~ enlist ([] vname:`$(); origValue:(); undef:`boolean$());
        .test.reportTestResult_calls ~ enlist (0b;"executeTestN.aftereach_error";`broke;"aftereach failure"));
 };

executeTestN_SUITE:`executeTestN_success`executeTestN_fail`executeTestN_exception`executeTestN_other`executeTestN_notafunc,
                   `executeTestN_toomanyargs`executeTestN_beforeandafter`executeTestN_notest_beforeeacherr,
                   `executeTestN_nocatch_success`executeTestN_nocatch_exception`executeTestN_restoreOverrides_afterEachError;

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
  .z.exit:{[] 0N!`exit;};
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
  r11:(.qtb.callLog[`testf1;(::)])[]; 
  r12:(.qtb.callLog[`testf1;`x])[];
  r13:(.qtb.callLog[`testf1;{(`a;x)}])[];
  e1:.[.qtb.callLog;(`testf1;{x+y});(::)];
  r21:(.qtb.callLog[`testf2;([] c:1 2 3)])[3];
  r22:(.qtb.callLog[`testf2;{(`b;x)}])[4];
  r23:(.qtb.callLog[`testf2;{(`b;x)}])[(`x;4)];
  e2:.[.qtb.callLog;(`testf2;{x+y});(::)];
  r31:(.qtb.callLog[`testf3;`a`b!1 2])[`x;2];
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


ALLTESTS:`privExecuteN_all,execute_SUITE,catchX_SUITE,checkX_SUITE,countargs_SUITE,isEmptyFunc_SUITE,
         executeSpecial_SUITE,`matchPaths_all,executeSuite_SUITE,executeTestN_SUITE,`applyOverrides_all,
         `applyOverride_all`revertOverride_all`callLog_all;

