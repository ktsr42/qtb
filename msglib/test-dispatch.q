\l ../lib/qtb.q
\l dispatch.q

.qtb.suite`registerFunc;

.qtb.addBeforeAll[`registerFunc;{[] FUNCTIONS_orig::.dispatch.FUNCTIONS; }];
.qtb.addAfterAll[`registerFunc;{[] .dispatch.FUNCTIONS::FUNCTIONS_orig; }];

testfunc:{[a;b] a+b};

.qtb.addTest[`registerFunc`ok;{[]
  .dispatch.registerFunc[`name;`testfunc;(-7 -7h)];
  .qtb.matchValue["Function registry";
                    ([name:``name] realname:``testfunc; argTypes:((::);-7 -7h));
                    .dispatch.FUNCTIONS] }];

.qtb.addTest[`registerFunc`undefined;{[]
  .qtb.checkX[.dispatch.registerFunc;(`invalid;`notthere;-11h);"dispatch: function notthere is not defined"]}];

answer:42;

.qtb.addTest[`registerFunc`notafunc;{[]
  .qtb.checkX[.dispatch.registerFunc;(`nofunc;`answer;-11h);"dispatch: answer is not a function"]}];

.qtb.addTest[`registerFunc`argmismatch;{[]
  .qtb.checkX[.dispatch.registerFunc;(`msmatch;`testfunc;-11h);"dispatch: signature mismatch"]}];

// deregister

.qtb.suite`deregister;
.qtb.addBeforeAll[`deregister;{[] FUNCTIONS_orig::.dispatch.FUNCTIONS; }];
.qtb.addAfterAll[`deregister;{[] .dispatch.FUNCTIONS::FUNCTIONS_orig; }];

.qtb.addTest[`deregister`remove;{[]
  `.dispatch.FUNCTIONS upsert (`a;`b;-11h);
  .dispatch.deregister `a;
  .qtb.matchValue["Function registry";
                    ([name:enlist `] realname:enlist `; argTypes:enlist (::));
                    .dispatch.FUNCTIONS] }];

.qtb.addTest[`deregister`donothing;{[]
  currFuncs:.dispatch.FUNCTIONS;
  .dispatch.deregister `notthere;
  .qtb.matchValue["Function registry";currFuncs;.dispatch.FUNCTIONS]} ];

// call

.qtb.suite`call;
.qtb.addBeforeAll[`call;{[] FUNCTIONS_orig::.dispatch.FUNCTIONS;}];
.qtb.addAfterAll[`call;{[] .dispatch.FUNCTIONS::FUNCTIONS_orig; }];

.qtb.addBeforeEach[`call;{[] .qtb.resetFuncallLog[]; }];

.qtb.addTest[`call`base;{[]
  testfunc1::.qtb.wrapLogCall[`testfunc1;{[a;b;c]}];
  `.dispatch.FUNCTIONS upsert (`testfunc;`testfunc1;-11 -6 10h);
  .dispatch.call (`testfunc;`a;22;"yo!");
  delete testfunc1 from `.;
  .qtb.matchValue["testfunc result";
                    ([] functionName:``testfunc1; arguments:((::);(`a;22;"yo!")));
                    .qtb.getFuncallLog[]] }];

.qtb.addTest[`call`anyarg;{[]
  testfunc2::.qtb.wrapLogCall[`testfunc2;{[a]}];
  `.dispatch.FUNCTIONS upsert (`testfunc;`testfunc2;0N);
  .dispatch.call (`testfunc;1 2);
  delete testfunc2 from `.;
  .qtb.matchValue["testfunc result";
                    ([] functionName:``testfunc2; arguments:((::);1 2));
                    .qtb.getFuncallLog[]] }];

.qtb.addTest[`call`onearg;{[]
  testfunc3::.qtb.wrapLogCall[`testfunc3;{[s]}];
  `.dispatch.FUNCTIONS upsert (`testfunc;`testfunc3;-11h);
  .dispatch.call `testfunc`xxx;
  delete testfunc3 from `.;
  .qtb.matchValue["testfunc result";
                    ([] functionName:``testfunc3; arguments:((::);`xxx));
                    .qtb.getFuncallLog[]] }];

.qtb.addTest[`call`noarg;{[]
  testfunc4::.qtb.wrapLogCall[`testfunc4;{[]}];
  `.dispatch.FUNCTIONS upsert (`testfunc;`testfunc4;());
  r:.dispatch.call `testfunc;
  delete testfunc4 from `.;
  .qtb.matchValue["testfunc result";
                    E::([] functionName:``testfunc4; arguments:((::);(::)));
                    A::.qtb.getFuncallLog[]] }];

.qtb.addTest[`call`unknown;{[]
  testfunc5::.qtb.wrapLogCall[`testfunc5;{[a;b]}];
  .dispatch.FUNCTIONS::([name:enlist `] realname:enlist `; argTypes:enlist (::));
  r:.qtb.checkX[.dispatch.call;(`testfunc;42);"dispatch: unknown function 'testfunc'"];
  delete testfunc5 from `.;
  r and .qtb.matchValue["testfunc result"; .qtb.emptyFuncallLog[];.qtb.getFuncallLog[]] }];

.qtb.addTest[`call`numargs;{[]
  testfunc6::.qtb.wrapLogCall[`testfunc6;{[a;b;c]}];
  `.dispatch.FUNCTIONS upsert (`testfunc;`testfunc6;-11 -6 10h);
  r:.qtb.checkX[.dispatch.call;`testfunc`x;"dispatch: function 'testfunc' requires 3 arguments"];
  delete testfunc6 from `.;
  r and .qtb.matchValue["testfunc result"; .qtb.emptyFuncallLog[];.qtb.getFuncallLog[]] }];

.qtb.addTest[`call`argtype;{[]
  testfunc7::.qtb.wrapLogCall[`testfunc7;{[a;b;c]}];
  `.dispatch.FUNCTIONS upsert (`testfunc;`testfunc7;-11 -6 10h);
  r:.qtb.checkX[.dispatch.call;`testfunc`x`y`z;"dispatch: arg type mismatch"];
  delete testfunc7 from `.;
  r and .qtb.matchValue["testfunc result"; .qtb.emptyFuncallLog[];.qtb.getFuncallLog[]] }];
