/////////////////////////////////////
// Unit tests for the Q Test Bench

\l qtb-s.q

\l ../tb/testbench.q

privExecuteN_allsucc:{[]
  executeSuite_orig:.qtb.priv.executeSuite;
  .qtb.priv.executeSuite::{[catchX;bp;be;ae;cp] 111b};
  
  res:.qtb.priv.execute[0b;`xx`yy];
  .qtb.priv.executeSuite::executeSuite_orig;
  res };

privExecuteN_onefail:{[]
  executeSuite_orig:.qtb.priv.executeSuite;
  .qtb.priv.executeSuite::{[catchX;bp;be;ae;cp] 101b};
  
  res:.qtb.priv.execute[0b;()];
  .qtb.priv.executeSuite::executeSuite_orig;
  not res };

privExecuteN_SUITE:`privExecuteN_allsucc`privExecuteN_onefail;


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

wrapLogCall_noargfunc:{[]
  f:.qtb.wrapLogCall[`testfunc;{[] 42}];
  .qtb.resetFuncallLog[];
  r:f[];
  all .qtb.matchValue ./: (("Return value";42;r);
                           ("Log entry";([] functionName:``testfunc; arguments:((::);(::))); .qtb.priv.FUNCALL_LOG)) };

wrapLogCall_oneargfunc:{[]
  f:.qtb.wrapLogCall[`somef;{[a] a+2}];
  .qtb.resetFuncallLog[];
  r:f 2;
  all .qtb.matchValue ./: (("Return value";4;r); ("Log entry";([] functionName:``somef; arguments:((::);2)); .qtb.priv.FUNCALL_LOG)) };

wrapLogCall_twoargfunc:{[]
  f:.qtb.wrapLogCall[`myfunc;{[a;b] a+b}];
  .qtb.resetFuncallLog[];
  r:f[2;3];
  all .qtb.matchValue ./: (("Return value";5;r); ("Log entry";([] functionName:``myfunc; arguments:((::);(2;3))); .qtb.priv.FUNCALL_LOG)) };

wrapLogCall_eightargfunc:{[]
  f:.qtb.wrapLogCall[`eightfunc;{[a1;a2;a3;a4;a5;a6;a7;a8] a1 + a2 + a3 + a4 + a5 + a6 + a7 + a8}];
  .qtb.resetFuncallLog[];
  r:f[1;2;3;4;5;6;7;8];
  all .qtb.matchValue ./: (("Return value";36;r);
                      ("Log entry";([] functionName:``eightfunc; arguments:((::);(1;2;3;4;5;6;7;8))); .qtb.priv.FUNCALL_LOG)) };

wrapLogCall_complexargs:{[]
  f:.qtb.wrapLogCall[`complexargs;{[a;b;c] (c;b;a)}];
  .qtb.resetFuncallLog[];
  d:`a`b!10 20;
  l:(1j;2011.11.11;`xx);
  t:([] ncol:1 2 3);
  r:f[d;l;t];
  all .qtb.matchValue ./: (("Return value";(t;l;d);r);
                      ("Log entry";([] functionName:``complexargs; arguments:((::);(d;l;t))); .qtb.priv.FUNCALL_LOG)) };

wrapLogCall_projectTable:{[]
  t:([] ncol:1 2 3);  
  f:.qtb.wrapLogCall[`tblproject;{[a;b;c] (a;c;b)}[;t]];
  .qtb.resetFuncallLog[];
  r:f[1;`xx];
  all .qtb.matchValue ./: (("Return value";(1;`xx;t);r);
                      ("Log entry";([] functionName:``tblproject; arguments:((::);(1;`xx))); .qtb.priv.FUNCALL_LOG)) };
  
wrapLogCall_projectDict:{[]
  d:`a`b`c!77 88 99;
  f:.qtb.wrapLogCall[`dictproject;{[a;b;c] (a;c;b)}[;d]];
  .qtb.resetFuncallLog[];
  r:f[1;`xx];
  all .qtb.matchValue ./: (("Return value";(1;`xx;d);r);
                      ("Log entry";([] functionName:``dictproject; arguments:((::);(1;`xx))); .qtb.priv.FUNCALL_LOG)) };

wrapLogCall_projectList:{[]
  l:(1;`xx;1 2);
  f:.qtb.wrapLogCall[`listproject;{[a;b;c] (a;c;b)}[l]];
  .qtb.resetFuncallLog[];
  r:f[1;`xx];
  all .qtb.matchValue ./: (("Return value";(l;`xx;1);r);
                      ("Log entry";([] functionName:``listproject; arguments:((::);(1;`xx))); .qtb.priv.FUNCALL_LOG)) };

wrapLogCall_SUITE:`wrapLogCall_noargfunc`wrapLogCall_oneargfunc`wrapLogCall_twoargfunc`wrapLogCall_eightargfunc,
                  `wrapLogCall_complexargs`wrapLogCall_projectTable`wrapLogCall_projectDict`wrapLogCall_projectList;


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

.executeSpecial_mark:0b;
executeSpecial_success:{[]
  .executeSpecial_mark::0b;
  r:.qtb.priv.executeSpecial[{ .executeSpecial_mark::1b; };"executeSpecial success";"oh my"];
  .executeSpecial_mark and r }

executeSpecial_fail:{[]
  .executeSpecial_mark::0b;
  r:not .qtb.priv.executeSpecial[{ .executeSpecial_mark::1b; '"whoops"};"executeSpecial success";"oh my"];
  .executeSpecial_mark and r }

executeSpecial_SUITE:`executeSpecial_empty`executeSpecial_success`executeSpecial_fail;


\d .executeSuite

executeSpecial_log:();
executeTest_log:();

setup:{[]
  alltests_orig::.qtb.priv.ALLTESTS;
  .qtb.priv.ALLTESTS::42;
  
  tree_getLeaves_orig::.tree.getLeaves;
  
  executeSpecial_log::();
  executeSpecial_orig::.qtb.priv.executeSpecial;
  .qtb.priv.executeSpecial::{[f;sp;n] executeSpecial_log,::enlist (f;sp;n); 1b};
  
  executeTest_orig::.qtb.priv.executeTest;
  executeTest_log::();
  .qtb.priv.executeTest::{[nc;be;ae;sp;f] executeTest_log,::enlist (nc;be;ae;sp;f); 0b};
 
  tree_getBranches_orig::.tree.getBranches;
  };

restore:{[]
  ALLTESTS::alltests_orig;
  .tree.getLeaves::tree_getLeaves_orig;
  .qtb.priv.executeSpecial::executeSpecial_orig;
  .qtb.priv.executeTest::executeTest_orig;
  .tree.getBranches::tree_getBranches_orig;
  };

beforeall:{[] `beforeeall};
afterall:{[] `afterall};
testa:{[] `testa;1b};
testb:{[] `testb;0b};
beforeeach_l:{[] `beforeeach_local};
aftereach_l:{[] `aftereach_local};
beforeeach:{[] `beforeeach};
aftereach:{[] `aftereach};

\d .

executeSuite_base:{[]
  .executeSuite.setup[];
  leaves:(.qtb.priv.BeforeAllTag;.qtb.priv.AfterAllTag;`testa;`testb;.qtb.priv.BeforeEachTag;.qtb.priv.AfterEachTag)!
          (.executeSuite.beforeall;.executeSuite.afterall;.executeSuite.testa;.executeSuite.testb;.executeSuite.beforeeach_l;.executeSuite.aftereach_l);
  .tree.getLeaves::{[leaves;dummy1;dummy2] leaves}[leaves;;];
  .tree.getBranches::{[tree;path] ()};
 
  r:.qtb.priv.executeSuite[0b;`$();.executeSuite.beforeeach;.executeSuite.aftereach;`q`test`bench];
 
  .executeSuite.restore[];
 
  (00b ~ r)
    and (.executeSuite.executeSpecial_log ~
         ((.executeSuite.beforeall;".q.test.bench";"BEFOREALL");(.executeSuite.afterall;".q.test.bench";"AFTERALL")))
    and (.executeSuite.executeTest_log ~ 
          (0b;(.executeSuite.beforeeach;.executeSuite.beforeeach_l);(.executeSuite.aftereach;.executeSuite.aftereach_l);".q.test.bench";) each
            (`name`func!(`testa;.executeSuite.testa);`name`func!(`testb;.executeSuite.testb))) }

executeSuite_recurse:{[]
  .executeSuite.setup[];
  
  leaves:(`testa;`testb;.qtb.priv.BeforeEachTag;.qtb.priv.AfterEachTag)!(.executeSuite.testa;.executeSuite.testb;.executeSuite.beforeeach_l;.executeSuite.aftereach_l);
  .tree.getLeaves::{[leaves;dummy1;dummy2] leaves}[leaves;;];
  .executeSuite.getBranches_callcount::0;
  .tree.getBranches::{[tree;path]
    .executeSuite.getBranches_callcount+::1;
    if[.executeSuite.getBranches_callcount > 10;'"circuit breacker tripped, path: "," " sv string path];
    $[`asuite ~ path;`brancha`branchb; ()] };
 
  tests:([] name:`testa`testb; func:(.executeSuite.testa;.executeSuite.testb));
 
  r:.qtb.priv.executeSuite[0b;`$();();();`asuite];
 
  .executeSuite.restore[];
 
  (000000b ~ r) and (.executeSuite.executeSpecial_log ~ 
                       (((::);".asuite";"BEFOREALL");
                        ((::);".asuite.brancha";"BEFOREALL");
                        ((::);".asuite.brancha";"AFTERALL");
                        ((::);".asuite.branchb";"BEFOREALL");
                        ((::);".asuite.branchb";"AFTERALL");
                        ((::);".asuite";"AFTERALL")))
                and (.executeSuite.executeTest_log ~ 
                      raze ((0b;enlist .executeSuite.beforeeach_l;enlist .executeSuite.aftereach_l;".asuite";) each tests;
                       (0b;2#.executeSuite.beforeeach_l;2#.executeSuite.aftereach_l;".asuite.brancha";) each tests;
                       (0b;2#.executeSuite.beforeeach_l;2#.executeSuite.aftereach_l;".asuite.branchb";) each tests)) };

executeSuite_beforeallfail:{[]
  .executeSuite.setup[];
  leaves:(.qtb.priv.BeforeAllTag;.qtb.priv.AfterAllTag;`testa;`testb;.qtb.priv.BeforeEachTag;.qtb.priv.AfterEachTag)!
          (.executeSuite.beforeall;.executeSuite.afterall;.executeSuite.testa;.executeSuite.testb;.executeSuite.beforeeach_l;.executeSuite.aftereach_l);
  .tree.getLeaves::{[leaves;dummy1;dummy2] leaves}[leaves;;];
 
  .qtb.priv.executeSpecial::{[f;sp;n] .executeSuite.executeSpecial_log,::enlist (f;sp;n); 0b};
 
  r:.qtb.priv.executeSuite[0b;`$();.executeSuite.beforeeach;.executeSuite.aftereach;`];
  
  .executeSuite.restore[];
 
  (r ~ enlist 0b)
    and (.executeSuite.executeTest_log ~ ())
    and (.executeSuite.executeSpecial_log ~ enlist (.executeSuite.beforeall;enlist ".";"BEFOREALL")) };

executeSuite_invalidbasepath:{[]
  .executeSuite.setup[];
  .tree.getLeaves::{[tree;path] '"tree: invalid path"};
  
  r:.qtb.priv.executeSuite[0b;`a`b;();();`path];
  
  .executeSuite.restore[];
  (0b ~ r) and (.executeSuite.executeTest_log ~ ()) and (.executeSuite.executeSpecial_log ~ ()) };

executeSuite_getleaves_exception:{[]
  .executeSuite.setup[];
  .tree.getLeaves::{[tree;path] '"poof"};
  
  r:.test.checkException[.qtb.priv.executeSuite;(0b;`a`b;();();`path);"poof"];
  
  .executeSuite.restore[];
  (1b ~ r) and (.executeSuite.executeTest_log ~ ()) and (.executeSuite.executeSpecial_log ~ ()) };

executeSuite_followpath:{[]
  .executeSuite.setup[];
  .tree.getLeaves::{[tree;path]
    $[`pa`th ~ path; ()!();
      `pa`th`suite ~ path;(enlist `testa)!enlist .executeSuite.testa;
                          '"invalid path"] };
  .tree.getBranches::{[tree;path] ()};

  r:.qtb.priv.executeSuite[0b;`pa`th`suite;();();`pa`th];
  
  .executeSuite.restore[];
  (enlist[0b] ~ r)
    and (.executeSuite.executeTest_log ~ enlist (0b;enlist[(::)];enlist[(::)];".pa.th.suite";`name`func!(`testa;.executeSuite.testa)))
    and (.executeSuite.executeSpecial_log ~
                       ((();".pa.th";"BEFOREALL");
                        enlist ((::);".pa.th.suite";"BEFOREALL");
                        enlist ((::);".pa.th.suite";"AFTERALL");
                        (();".pa.th";"AFTERALL")))  };

executeSuite_single:{[]
  .executeSuite.setup[];
  .tree.getLeaves:{[tree;path] (enlist `testa)!enlist .executeSuite.testa};
  
  r:.qtb.priv.executeSuite[0b;`pa`th`testa;();();`pa`th];
  
  .executeSuite.restore[];
  (r ~ 0b)
    and (.executeSuite.executeTest_log ~ enlist (0b;enlist[(::)];enlist[(::)];".pa.th";`name`func!(`testa;.executeSuite.testa)))
    and (.executeSuite.executeSpecial_log ~ (((::);".pa.th";"BEFOREALL");((::);".pa.th";"AFTERALL")))  };
  

executeSuite_SUITE:`executeSuite_base`executeSuite_recurse`executeSuite_beforeallfail,
                   `executeSuite_invalidbasepath`executeSuite_getleaves_exception,
                   `executeSuite_followpath`executeSuite_single;


executeTestN_success:{[]
  catchX_orig:.qtb.catchX;
  .qtb.catchX::{[f;a] (`success;1b)};
  r:.qtb.priv.executeTest[0b;();();"executeTestN";`name`func!(`success;{})];
  .qtb.catchX::catchX_orig;
  r };

executeTestN_fail:{[]
  catchX_orig:.qtb.catchX;
  .qtb.catchX::{[f;a] (`success;0b)};
  r:.qtb.priv.executeTest[0b;();();"executeTestN";`name`func!(`fail;{})];
  .qtb.catchX::catchX_orig;
  not r };

executeTestN_exception:{[]
  catchX_orig:.qtb.catchX;
  .qtb.catchX::{[f;a] (`exceptn;"poof")};
  r:.qtb.priv.executeTest[0b;();();"executeTestN";`name`func!(`exception;{})];
  .qtb.catchX::catchX_orig;
  not r };

executeTestN_other:{[]
  catchX_orig:.qtb.catchX;
  .qtb.catchX::{[f;a] (`success;42)};
  r:.test.checkException[.qtb.priv.executeTest;(0b;();();"executeTestN";`name`func!(`other;{}));"qtb: unexpected test result"];
  .qtb.catchX::catchX_orig;
  not r };

executeTestN_nocatch_success:{[] .qtb.priv.executeTest[1b;();();"executeTestN";`name`func!(`debug;{[] 1b})] };

executeTestN_nocatch_exception:{[]
  .test.checkException[.qtb.priv.executeTest;(1b;();();"executeTestN";`name`func!(`debug;{[] '"jump!"}));"jump"] };

executeTestN_notafunc:{[] not .qtb.priv.executeTest[0b;();();"executeTestN";`name`func!(`notafunc;42)] };

executeTestN_toomanyargs:{[] not .qtb.priv.executeTest[0b;();();"executeTestN";`name`func!(`toomanyargs;{x+y})] };

.executeTestN.executeSpecial_log:();

executeTestN_beforeandafter:{[]
  catchX_orig:.qtb.catchX;
  .qtb.catchX::{[f;a] (`success;1b)};
  .executeTestN.executeSpecial_log::();
  executeSpecial_orig:.qtb.priv.executeSpecial;
  .qtb.priv.executeSpecial:{[f;n;t] .executeTestN.executeSpecial_log,::enlist (f;n;t); 1b};
 
  beforeeaches:({[] `beforeeach_1};{[] `beforeeach_2};{[] `beforeeach_3});
  aftereaches:({[] `aftereach_1};{[] `aftereach_2});
 
  r:.qtb.priv.executeTest[0b;beforeeaches;aftereaches;"executeTestN";`name`func!(`beforeandafter;{[] 0b})];
  .qtb.catchX::catchX_orig;
  .qtb.priv.executeSpecial::executeSpecial_orig;
  testname:"executeTestN.beforeandafter";
  r and .executeTestN.executeSpecial_log ~
        ((;testname;"BEFOREEACH") each beforeeaches),(;testname;"AFTEREACH") each aftereaches };

executeTestN_notest_beforeeacherr:{[]
  catchX_orig:.qtb.catchX;
  .qtb.catchX::{[f;a] (`success;42)};
  .executeTestN.executeSpecial_log::();
  executeSpecial_orig:.qtb.priv.executeSpecial;
  .qtb.priv.executeSpecial:{[f;n;t] .executeTestN.executeSpecial_log,::enlist (f;n;t); not f ~ {[] '"dingdong"} };
  
  beforeeaches:({[] `beforeeach_1};{[] '"dingdong"};{[] `beforeeach_3});
  aftereaches:({[] `aftereach_1};{[] `aftereach_2});
 
  r:.qtb.priv.executeTest[0b;beforeeaches;aftereaches;"executeTestN";`name`func!(`notest_beforeerr;{[] 1b})];
  .qtb.catchX::catchX_orig;
  .qtb.priv.executeSpecial::executeSpecial_orig;
 
  (not r) and .executeTestN.executeSpecial_log ~ (;"executeTestN.notest_beforeerr";"BEFOREEACH") each beforeeaches };

executeTestN_SUITE:`executeTestN_success`executeTestN_fail`executeTestN_exception`executeTestN_other`executeTestN_notafunc,
                   `executeTestN_toomanyargs`executeTestN_beforeandafter`executeTestN_notest_beforeeacherr,
                   `executeTestN_nocatch_success`executeTestN_nocatch_exception;

saveValue_regularDefined:{[]
  savedValues_orig:.qtb.priv.SAVEDVALUES;
  testfunc:{x+x};
  saveValue_Root::42;
  .saveValue.secondLevel::testfunc;
  .saveValue.context.subcontext::`a`b!10 20;
  .z.exit:testfunc;
  vars:`saveValue_Root`.saveValue.secondLevel`.saveValue.context.subcontext`.z.exit`.z.pc`INVALID`.context.INVALID;
  .qtb.saveValue each vars;
  expSavedvalues:(`,vars)!(::) , {(x;(::))} each ((1b;42);(1b;testfunc);(1b;`a`b!10 20);(1b;testfunc);(0b;`undef);(0b;`undef);(0b;`undef));
  actSavedvalues:AS::.qtb.priv.SAVEDVALUES;
  .qtb.priv.SAVEDVALUES::savedValues_orig;
  actSavedvalues ~ ES::expSavedvalues };

saveValue_multipleRedefinitions:{[]
  savedValues_orig:.qtb.priv.SAVEDVALUES;  
  .saveValue.Aval::0;
  .qtb.saveValue`.saveValue.Aval;
  .saveValue.Aval::1;
  .qtb.saveValue`.saveValue.Aval;
  .saveValue.Aval::2;
  .qtb.saveValue`.saveValue.Aval;
  actSavedvalues:.qtb.priv.SAVEDVALUES;
  .qtb.priv.SAVEDVALUES::savedValues_orig;
  actSavedvalues ~ ``.saveValue.Aval!((::);((1b;2);(1b;1);(1b;0);(::))) };

saveValue_pushPrevious:{[]
  savedValues_orig:.qtb.priv.SAVEDVALUES;  
  .qtb.priv.SAVEDVALUES:``.saveValues.Anotherval!((::);enlist (::));
  .qtb.saveValue `.saveValues.Anotherval;
  actSavedValues:.qtb.priv.SAVEDVALUES;
  .qtb.priv.SAVEDVALUES::savedValues_orig;
  (``.saveValues.Anotherval!((::);((0b;`undef);(::)))) ~ actSavedValues };

saveValue_SUITE:`saveValue_regularDefined`saveValue_multipleRedefinitions`saveValue_pushPrevious;

restoreValue_base:{[]
  savedValues_orig:.qtb.priv.SAVEDVALUES;
  .qtb.priv.SAVEDVALUES::``.restoreValue.a`.z.exit`UNDEF`.restoreValue.UNDEF!((::);((1b;100);(1b;42);(::));((0b;`undef);(::));((0b;`undef);(::));((0b;`undef);(::)));
  .z.exit::exitfunc:{[r] };
  UNDEF::42;
  .restoreValue.UNDEF::67;
 
  res:.qtb.restoreValue each `.restoreValue.a`.z.exit`UNDEF`.restoreValue.UNDEF;
  actSavedvalues:.qtb.priv.SAVEDVALUES;
 
  .qtb.priv.SAVEDVALUES::savedValues_orig;
  expSavedvalues:``.restoreValue.a!((::);((1b;42);(::)));
  all ((~)./: ((.restoreValue.a;100);(expSavedvalues;actSavedvalues);((100;(::);(::);(::));res))),
      (@[{[x] value x; 0b};;1b] @/: `.z.exit`UNDEF`.restoreValue.UNDEF)  };

restoreValue_invalidvar:{[]
  savedValues_orig:.qtb.priv.SAVEDVALUES;
  .qtb.priv.SAVEDVALUES:``A!((::);enlist (::));
  
  res:@[.qtb.restoreValue;;{[err] err}] @/: `invalid`A;
  actSavedvalues:.qtb.priv.SAVEDVALUES;
  .qtb.priv.SAVEDVALUES::savedValues_orig;
 
  (".qtb.restoreValue: invalid variable name: invalid";".qtb.restoreValue: invalid variable name: A") ~ res  };

restoreValue_SUITE:`restoreValue_base`restoreValue_invalidvar;

ALLTESTS:countargs_SUITE,wrapLogCall_SUITE,isEmptyFunc_SUITE,executeSuite_SUITE,
         executeTestN_SUITE,privExecuteN_SUITE,execute_SUITE,`logFuncall_all,
         checkX_SUITE,catchX_SUITE,executeSpecial_SUITE,saveValue_SUITE,restoreValue_SUITE;

