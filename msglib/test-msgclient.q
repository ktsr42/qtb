// Unit tests for the messaging client

\l ../qtb.q
\l msgclient.q

.qtb.suite`priv;

// priv.connSetup is trivial

// priv.regResult
.qtb.suite`priv`regResult;
.qtb.setOverrides[`priv`regResult;`.msg.priv.LOGF`.msg.priv.CONN_STATE`.msg.priv.dropConnection!(.qtb.callLogNoret`.msg.priv.LOGF;.msg.priv.CONN_STATE;.qtb.callLogNoret`.msg.priv.dropConnection)];

.qtb.addTest[`priv`regResult`success;{[]
  .msg.priv.CONN_STATE::`registration_pending;
  .msg.priv.regResult 1b;
  .qtb.assert.matches[`connected;.msg.priv.CONN_STATE];
  .qtb.assert.matches[([] functionName:``.msg.priv.LOGF; arguments:((::);"Registration request result: 1");
                      .qtb.getFuncallLog[])];
  }];

.qtb.addTest[`priv`regResult`failed;{[]
  .msg.priv.CONN_STATE:`registration_pending;
  .msg.priv.regResult 0b;
  .qtb.assert.matches[([] functionName:``.msg.priv.LOGF`.msg.priv.dropConnection;
                        arguments:((::);"Registration request result: 0";enlist (::)));
                      .qtb.getFuncallLog[]];
  }];

.qtb.addTest[`priv`regResult`invalid;{[]
  .msg.priv.CONN_STATE:`OTHER;
  .qtb.override[`.msg.priv.MSGSERVER;42];
 
  .msg.priv.regResult 1b;
  .qtb.assert.matches[([] functionName:``.msg.priv.LOGF`.msg.priv.LOGF`.msg.priv.dropConnection;
                        arguments:((::);
                                   "Registration request result: 1";
                                   "Received unexpected registration message, current state: OTHER";
                                   enlist (::)));
                      .qtb.getFuncallLog[]];
  }];
  
.qtb.suite`priv`receiveMsg;
.qtb.setOverrides[`priv`receiveMsg;`.dispatch.call`.msg.priv.MSGSERVER!(.qtb.callLogNoret`.dispatch.call;42)]

.qtb.addTest[`priv`receiveMsg`notforus;{[]
  .msg.priv.receiveMsg[10;`yo];
  .qtb.assert.matches[.qtb.emptyFuncallLog[];.qtb.getFuncallLog[]];
  }];

.qtb.addTest[`priv`receiveMsg`success;{[]
  .msg.priv.receiveMsg[42;`yo];
  .qtb.assert.matches[([] functionName:``.dispatch.call; arguments:((::);enlist `yo));.qtb.getFuncallLog[]];
  }];

.qtb.addTest[`priv`receiveMsg`fail;{[]
  .qtb.override[`.msg.priv.LOGF;.qtb.callLogNoret`.msg.priv.LOGF];
  .qtb.override[`.dispatch.call;.qtb.callLogSimple[`.dispatch.call;{[msg] '"kaboom"}]];
  .msg.priv.receiveMsg[42;`yo];
  .qtb.assert.matches[([] functionName:``.dispatch.call`.msg.priv.LOGF;
                        arguments:((::);enlist `yo;"Message dispatch failed: kaboom"));
                      .qtb.getFuncallLog[]];
  }];

// priv.enqueue

.qtb.suite`priv`enqueue;
.qtb.setOverrides[`priv`enqueue;`.msg.priv.LOGF`.msg.priv.PRIM_ADDRESS`.msg.priv.MESSAGES!(.qtb.callLogNoret`.msg.priv.LOGF;`me;([] srcAddr:enlist `; destAddr:enlist `; msg:enlist (::)))];

.qtb.addTest[`priv`enqueue`ok;{[]
  .msg.priv.enqueue[`him;`me;"Yo!"];
  .qtb.assert.matches[([] srcAddr:``him; destAddr:``me; msg:((::);"Yo!")); .msg.priv.MESSAGES];
  .qtb.assert.matches[([] functionName:``.msg.priv.LOGF; arguments:((::);"Message received from him for me: \"Yo!\""));
                      .qtb.getFuncallLog[]];
  }];

.qtb.addTest[`priv`enqueue`notforus;{[]
  .msg.priv.enqueue[`him;`her;42];
  .qtb.assert.matches[([] srcAddr:enlist `; destAddr:enlist `; msg:enlist (::)); .msg.priv.MESSAGES];
  .qtb.assert.matches[([] functionName:``.msg.priv.LOGF`.msg.priv.LOGF;
                          arguments:((::);"Message received from him for her: 42";"Message is not addressed to us, ignoring"));
                      .qtb.getFuncallLog[]];
  }];

// priv.dropConnection

.qtb.suite`priv`dropConnection;
.qtb.setOverrides[`priv`dropConnection;`.msg.priv.LOGF`.msg.priv.connectionDropped`.msg.priv.MSGSERVER!(.qtb.callLogNoret`.msg.priv.LOGF;.qtb.callLogNoret`.msg.priv.connectionDropped;42)]

.qtb.addTest[`priv`dropConnection`ok;{[]
  .qtb.override[`.q.hclose;.qtb.callLogComplex[`.q.hclose;(::);1]];
  .msg.priv.dropConnection[];
  .qtb.assert.matches[([] functionName:``.msg.priv.LOGF`.q.hclose`.msg.priv.connectionDropped;
                          arguments:((::);"Dropping server connection";(),42;(),42));
                      .qtb.getFuncallLog[]];
  }];

.qtb.addTest[`priv`dropConnection`error;{[]
  .qtb.override[`.q.hclose;.qtb.callLogComplex[`.q.hclose;{[conn] '"ace"};1]];
  .qtb.override[`.msg.priv.ERREXITF;.qtb.callLogSimple[`.msg.priv.ERREXITF;{[] '"jump"}]];
  .qtb.assert.throws[(`.msg.priv.dropConnection;(::));"jump"];
  .qtb.assert.matches[([] functionName:``.msg.priv.LOGF`.q.hclose`.msg.priv.LOGF`.msg.priv.ERREXITF;
                          arguments:((::);"Dropping server connection";(),42;"Fatal error, hclose in dropConnection failed: ace";(),(::)));
                      .qtb.getFuncallLog[]];
  }];

// priv.connectionDropped

.qtb.suite`priv`connectionDropped;
.qtb.setOverrides[`priv`connectionDropped;`.msg.priv.LOGF`.msg.priv.MSGSERVER`.msg.priv.RECONNECT`.msg.priv.connSetup!(.qtb.callLogNoret`.msg.priv.LOGF;.msg.priv.MSGSERVER;.msg.priv.RECONNECT;.qtb.callLogNoret`.msg.priv.connSetup)];

.qtb.addTest[`priv`connectionDropped`otherhandle;{[]
  .msg.priv.MSGSERVER::3;
  .msg.priv.RECONNECT::0b;
  .msg.priv.connectionDropped[4];
  .qtb.assert.matches[3;.msg.priv.MSGSERVER];
  .qtb.assert.matches[.qtb.emptyFuncallLog[];.qtb.getFuncallLog[]];
  }];

.qtb.addTest[`priv`connectionDropped`noreconnect;{[]
  .msg.priv.RECONNECT:0b;
  .msg.priv.MSGSERVER::4;
  .msg.priv.connectionDropped[4];
  .qtb.assert.matches[0N;.msg.priv.MSGSERVER];
  .qtb.assert.matches[([] functionName:``.msg.priv.LOGF; arguments:((::);"Server has disconnected"));.qtb.getFuncallLog[]];
  }];

.qtb.addTest[`priv`connectionDropped`reconnect;{[]
  .msg.priv.RECONNECT:1b;
  .msg.priv.MSGSERVER::5;
  .msg.priv.connectionDropped[5];
  .qtb.assert.matches[0N;.msg.priv.MSGSERVER];
  .qtb.assert.matches[([] functionName:``.msg.priv.LOGF`.msg.priv.connSetup;
                         arguments:((::);"Server has disconnected";(),(::)));
                      .qtb.getFuncallLog[]];
  }];


// chainCallback

.qtb.suite`priv`chainCallback;

.testmsgcl.base:{x;};
.testmsgcl.link1:{x;};
.testmsgcl.link2:{x;};

.qtb.setOverrides[`priv`chainCallback;`.testmsgcl.base`.testmsgcl.link1`.testmsgcl.link2!.qtb.callLogNoret'[`.testmsgcl.base`.testmsgcl.link1`.testmsgcl.link2]];

.qtb.addBeforeEach[`priv`chainCallback;{[] delete testcallback from `.;}];
.qtb.addAfterAll[`priv`chainCallback;{[] delete testcallback from `.;}];

.qtb.addTest[`priv`chainCallback`notdefined;{[]
  .msg.priv.chainCallback[`testcallback;.testmsgcl.base];
  testcallback 1;
  .qtb.assert.matches[([] functionName:``.testmsgcl.base; arguments:((::);(),1));.qtb.getFuncallLog[]];
  }];

.qtb.addTest[`priv`chainCallback`existing;{[]
  .msg.priv.chainCallback[`testcallback;.testmsgcl.base];
  .msg.priv.chainCallback[`testcallback;.testmsgcl.link1];
  testcallback `me;
  .qtb.assert.matches[([] functionName:``.testmsgcl.base`.testmsgcl.link1; arguments:((::);(),`me;(),`me));.qtb.getFuncallLog[]];
  }];

.qtb.addTest[`priv`chainCallback`three;{[]
  .msg.priv.chainCallback[`testcallback;.testmsgcl.base];
  .msg.priv.chainCallback[`testcallback;.testmsgcl.link1];
  .msg.priv.chainCallback[`testcallback;.testmsgcl.link2];
  testcallback"a";
  .qtb.assert.matches[([] functionName:``.testmsgcl.base`.testmsgcl.link1`.testmsgcl.link2; arguments:(::),(),/:3#"a");
                      .qtb.getFuncallLog[]];
  }];

// init

.qtb.suite`init;
.qtb.setOverrides[`init;`.msg.priv.SERVER_ADDRESS`.msg.priv.PRIM_ADDRESS`.msg.priv.RECONNECT`.msg.priv.CONNECT_TIMEOUT`.msg.priv.connSetup!(.msg.priv.SERVER_ADDRESS;.msg.priv.PRIM_ADDRESS;.msg.priv.RECONNECT;.msg.priv.CONNECT_TIMEOUT;.qtb.callLogNoret`.msg.priv.connSetup)];

.qtb.addTest[`init`missingparams;{[]
  .qtb.assert.throws[(`.msg.init;`a`b!1 2);"msgclient: missing parameters"];
  .qtb.assert.matches[.qtb.emptyFuncallLog[];.qtb.getFuncallLog[]];
  }];

.qtb.addTest[`init`full;{[]
  reconnectflag:not .msg.priv.RECONNECT;
  .msg.init `server`primAddr`reconnect!(`myserver;`us;reconnectflag);
  .qtb.assert.matches[`myserver;.msg.priv.SERVER_ADDRESS];
  .qtb.assert.matches[`us;.msg.priv.PRIM_ADDRESS];
  .qtb.assert.matches[reconnectflag;.msg.priv.RECONNECT];
  .qtb.assert.matches[([] functionName:``.msg.priv.connSetup; arguments:((::);enlist (::)));.qtb.getFuncallLog[]];
  }];


.qtb.suite`sendMsg;

.qtb.setOverrides[`sendMsg;`.msg.priv.CONN_STATE`.msg.priv.MSGSERVER`.msg.priv.PRIM_ADDRESS`.msg.priv.send!(.msg.priv.CONN_STATE;.msg.priv.MSGSERVER;.msg.priv.PRIM_ADDRESS;.qtb.callLogNoret`.msg.priv.send)];

.qtb.addTest[`sendMsg`ok;{[]
  .msg.priv.CONN_STATE::`connected;
  .msg.priv.MSGSERVER::42;
  .msg.priv.PRIM_ADDRESS::`alice;
  .msg.sendMsg[`bob;([] c:1 2)];
  .qtb.assert.matches[([] functionName:``.msg.priv.send; arguments:((::);(42;(`sendMessage;`alice;`bob;([] c:1 2)))));
                      .qtb.getFuncallLog[]];
  }];

.qtb.addTest[`sendMsg`noconn;{[]
  .msg.priv.CONN_STATE:`registration_pending;
  .msg.priv.MSGSERVER::43;
  .qtb.assert.throws[(`.msg.sendMsg;(),`alice;"Yo!");"msgclient: not connected"];
  .qtb.assert.matches[.qtb.emptyFuncallLog[];.qtb.getFuncallLog[]];
  }];


// nextMsg

.qtb.suite`nextMsg;

.qtb.setOverrides[`nextMsg; (!) . enlist'[(`.msg.priv.MESSAGES;.msg.priv.MESSAGES)]];

.qtb.addTest[`nextMsg`get3msg;{[]
  m1:`srcAddr`destAddr`msg!(`you;`me;42);
  m2:`srcAddr`destAddr`msg!(`somebody;`me;"Here we go");
  m3:`srcAddr`destAddr`msg!(`her;`me;`a`b!10 20);
  `.msg.priv.MESSAGES upsert m1;
  `.msg.priv.MESSAGES upsert m2;
  `.msg.priv.MESSAGES upsert m3;
  msgs:enlist (::);
  msgs,:enlist .msg.nextMsg[];
  msgs,:enlist .msg.nextMsg[];
  msgs,:enlist .msg.nextMsg[];
  msgs,:enlist .msg.nextMsg[];
  msgs,:enlist .msg.nextMsg[];
  .qtb.assert.matches[(m1;m2;m3;();());1 _ msgs]
  .qtb.assert.matches[([] srcAddr:enlist `; destAddr:enlist `; msg:enlist (::));.msg.priv.MESSAGES];
  }];

.qtb.run[];
