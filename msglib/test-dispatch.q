\l ../qtb.q
\l dispatch.q

.qtb.suite`registerFunc;
.qtb.setOverrides[`;enlist[`.dispatch.FUNCTIONS]!enlist 1#.dispatch.FUNCTIONS];

testfunc:{[a;b] a+b};

.qtb.addTest[`registerFunc`ok;{[]
  .dispatch.registerFunc[`name;`testfunc;(-7 -7h)];
  .qtb.assert.matches[([name:``name] realname:``testfunc; argTypes:((::);-7 -7h));.dispatch.FUNCTIONS];
  }];

.qtb.addTest[`registerFunc`undefined;{[]
  .qtb.assert.throws[(`.dispatch.registerFunc;(),`invalid;(),`notthere;-11h);"dispatch: function notthere is not defined"];
  }];

answer:42;

.qtb.addTest[`registerFunc`notafunc;{[]
  .qtb.assert.throws[(`.dispatch.registerFunc;(),`nofunc;(),`answer;-11h);"dispatch: answer is not a function"];
  }];

.qtb.addTest[`registerFunc`argmismatch;{[]
  .qtb.assert.throws[(`.dispatch.registerFunc;(),`msmatch;(),`testfunc;-11h);"dispatch: signature mismatch"];
  }];

// deregister

.qtb.suite`deregister;

.qtb.addTest[`deregister`remove;{[]
  `.dispatch.FUNCTIONS upsert (`a;`b;-11h);
  .dispatch.deregister `a;
  .qtb.assert.matches[([name:enlist `] realname:enlist `; argTypes:enlist (::));.dispatch.FUNCTIONS];
  }];

.qtb.addTest[`deregister`donothing;{[]
  currFuncs:.dispatch.FUNCTIONS;
  .dispatch.deregister `notthere;
  .qtb.assert.matches[currFuncs;.dispatch.FUNCTIONS];
  } ];

// call

.qtb.suite`call;

.dpcall.testfunc1:{(x;y;z);42};
.dpcall.testfunc2:{x;};
.dpcall.testfunc3:{x;};
.dpcall.testfunc4:{};
.dpcall.testfunc5:{[a;b]};
.dpcall.testfunc6:{[a;b;c]};
.dpcall.testfunc7:{[a;b;c]};

.qtb.addTest[`call`base;{[]
  .qtb.override[`.dpcall.testfunc1;.qtb.callLogNoret`.dpcall.testfunc1];
  `.dispatch.FUNCTIONS upsert (`testfunc;`.dpcall.testfunc1;-11 -7 10h);
  .dispatch.call (`testfunc;`a;22;"yo!");
  .qtb.assert.matches[([] functionName:``.dpcall.testfunc1; arguments:((::);(`a;22;"yo!")));
                      .qtb.getFuncallLog[]];
  }];

.qtb.addTest[`call`anyarg;{[]
  .qtb.override[`.dpcall.testfunc2;.qtb.callLogNoret`.dpcall.testfunc2];
  `.dispatch.FUNCTIONS upsert (`testfunc;`.dpcall.testfunc2;0N);
  .dispatch.call (`testfunc;1 2);
  .qtb.assert.matches[([] functionName:``.dpcall.testfunc2; arguments:((::);1 2));
                      .qtb.getFuncallLog[]];
  }];

.qtb.addTest[`call`onearg;{[]
  .qtb.override[`.dpcall.testfunc3;.qtb.callLogNoret`.dpcall.testfunc3];
  `.dispatch.FUNCTIONS upsert (`testfunc;`.dpcall.testfunc3;-11h);
  .dispatch.call `testfunc`xxx;
  .qtb.assert.matches[([] functionName:``.dpcall.testfunc3; arguments:((::);enlist `xxx));
                      .qtb.getFuncallLog[]];
  }];

.qtb.addTest[`call`noarg;{[]
  .qtb.override[`.dpcall.testfunc4;.qtb.callLogNoret`.dpcall.testfunc4];
  `.dispatch.FUNCTIONS upsert (`testfunc;`.dpcall.testfunc4;());
  r:.dispatch.call `testfunc;
  .qtb.assert.matches[([] functionName:``.dpcall.testfunc4; arguments:((::);enlist (::)));
                      .qtb.getFuncallLog[]]
  }];

.qtb.addTest[`call`unknown;{[]
  .qtb.override[`.dpcall.testfunc5;.qtb.callLogNoret`.dpcall.testfunc5];
  .dispatch.FUNCTIONS::([name:enlist `] realname:enlist `; argTypes:enlist (::));
  .qtb.assert.throws[(`.dispatch.call;(enlist;(),`testfunc;42));"dispatch: unknown function 'testfunc'"];
  .qtb.assert.matches[.qtb.emptyFuncallLog[];.qtb.getFuncallLog[]];
  }];

.qtb.addTest[`call`numargs;{[]
  .qtb.override[`.dpcall.testfunc6;.qtb.callLogNoret`.dpcall.testfunc6];
  `.dispatch.FUNCTIONS upsert (`testfunc;`.dpcall.testfunc6;-11 -7 10h);
  .qtb.assert.throws[(`.dispatch.call;enlist`testfunc`x);"dispatch: function 'testfunc' requires 3 arguments"];
  .qtb.assert.matches[.qtb.emptyFuncallLog[];.qtb.getFuncallLog[]];
  }];

.qtb.addTest[`call`argtype;{[]
  .qtb.override[`.dpcall.testfunc7;.qtb.callLogNoret`.dpcall.testfunc7];
  `.dispatch.FUNCTIONS upsert (`testfunc;`.dpcall.testfunc7;-11 -6 10h);
  .qtb.assert.throws[(`.dispatch.call;enlist`testfunc`x`y`z);"dispatch: arg type mismatch"];
  .qtb.assert.matches[.qtb.emptyFuncallLog[];.qtb.getFuncallLog[]];
  }];

.qtb.run[];