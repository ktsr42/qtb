\l ../qtb.q
\l dispatch.q

.qtb.suite`registerFunc;
.qtb.setOverrides[`;enlist[`.dispatch.FUNCTIONS]!enlist 1#.dispatch.FUNCTIONS];

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

.qtb.addTest[`call`base;{[]
  .qtb.override[`testfunc1;.qtb.wrapLogCall[`testfunc1;{[a;b;c]}]];
  `.dispatch.FUNCTIONS upsert (`testfunc;`testfunc1;-11 -7 10h);
  .dispatch.call (`testfunc;`a;22;"yo!");
  .qtb.matchValue["testfunc result";
                    ([] functionName:``testfunc1; arguments:((::);(`a;22;"yo!")));
                    .qtb.getFuncallLog[]] }];

.qtb.addTest[`call`anyarg;{[]
  .qtb.override[`testfunc2;.qtb.wrapLogCall[`testfunc2;{[a]}]];
  `.dispatch.FUNCTIONS upsert (`testfunc;`testfunc2;0N);
  .dispatch.call (`testfunc;1 2);
  .qtb.matchValue["testfunc result";
                    ([] functionName:``testfunc2; arguments:((::);1 2));
                    .qtb.getFuncallLog[]] }];

.qtb.addTest[`call`onearg;{[]
  .qtb.override[`testfunc3;.qtb.wrapLogCall[`testfunc3;{[s]}]];
  `.dispatch.FUNCTIONS upsert (`testfunc;`testfunc3;-11h);
  .dispatch.call `testfunc`xxx;
  .qtb.matchValue["testfunc result";
                    ([] functionName:``testfunc3; arguments:((::);`xxx));
                    .qtb.getFuncallLog[]] }];

.qtb.addTest[`call`noarg;{[]
  .qtb.override[`testfunc4;.qtb.wrapLogCall[`testfunc4;{[]}]];
  `.dispatch.FUNCTIONS upsert (`testfunc;`testfunc4;());
  r:.dispatch.call `testfunc;
  .qtb.matchValue["testfunc result";
                    ([] functionName:``testfunc4; arguments:((::);(::)));
                    .qtb.getFuncallLog[]] }];

.qtb.addTest[`call`unknown;{[]
  .qtb.override[`testfunc5;.qtb.wrapLogCall[`testfunc5;{[a;b]}]];
  .dispatch.FUNCTIONS::([name:enlist `] realname:enlist `; argTypes:enlist (::));
  r:.qtb.checkX[.dispatch.call;(`testfunc;42);"dispatch: unknown function 'testfunc'"];
  r and .qtb.matchValue["testfunc result"; .qtb.emptyFuncallLog[];.qtb.getFuncallLog[]] }];

.qtb.addTest[`call`numargs;{[]
  .qtb.override[`testfunc6;.qtb.wrapLogCall[`testfunc6;{[a;b;c]}]];
  `.dispatch.FUNCTIONS upsert (`testfunc;`testfunc6;-11 -7 10h);
  r:.qtb.checkX[.dispatch.call;`testfunc`x;"dispatch: function 'testfunc' requires 3 arguments"];
  r and .qtb.matchValue["testfunc result"; .qtb.emptyFuncallLog[];.qtb.getFuncallLog[]] }];

.qtb.addTest[`call`argtype;{[]
  .qtb.override[`testfunc7;.qtb.wrapLogCall[`testfunc7;{[a;b;c]}]];
  `.dispatch.FUNCTIONS upsert (`testfunc;`testfunc7;-11 -6 10h);
  r:.qtb.checkX[.dispatch.call;`testfunc`x`y`z;"dispatch: arg type mismatch"];
  r and .qtb.matchValue["testfunc result"; .qtb.emptyFuncallLog[];.qtb.getFuncallLog[]] }];
