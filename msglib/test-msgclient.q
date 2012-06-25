// Unit tests for the messaging client

\l ../qtb.q
\l msgclient.q

// reset the function call log before every test
.qtb.addBeforeEach[`;{[] .qtb.resetFuncallLog[] }];

.qtb.suite`priv;

// priv.connSetup is trivial

// priv.regResult
.qtb.suite`priv`regResult;

.qtb.addBeforeAll[`priv`regResult;{[]
  logf_orig::.msg.priv.LOGF;
  .msg.priv.LOGF::.qtb.wrapLogCall[`logf;{[msg]}];
  priv_CONN_STATE::.msg.priv.CONN_STATE;
  priv_dropConnection::.msg.priv.dropConnection;
  .msg.priv.dropConnection::.qtb.wrapLogCall[`dropConnection;{[]}];
  }];

.qtb.addAfterAll[`priv`regResult;{[]
  .msg.priv.LOGF::logf_orig;
  .msg.priv.CONN_STATE::priv_CONN_STATE;
  .msg.priv.dropConnection::priv_dropConnection;
  }];

.qtb.addTest[`priv`regResult`success;{[]
  .msg.priv.CONN_STATE::`registration_pending;
  .msg.priv.regResult[1b];
  all .qtb.matchValue ./: (("connection state";`connected;.msg.priv.CONN_STATE);
                           ("Call log";
                            ([] functionName:``logf; arguments:((::);"Registration request result: 1"));
                            .qtb.getFuncallLog[])) }];

.qtb.addTest[`priv`regResult`failed;{[]
  .msg.priv.CONN_STATE:`registration_pending;
  .msg.priv.regResult[0b];
  .qtb.matchValue["Call log";
                  ([] functionName:``logf`dropConnection;
                      arguments:((::);"Registration request result: 0";(::)));
                  .qtb.getFuncallLog[]]}];

.qtb.addTest[`priv`regResult`invalid;{[]
  .msg.priv.CONN_STATE:`OTHER;
  priv_MSGSERVER:.msg.priv.MSGSERVER;
  .msg.priv.MSGSERVER::42;
 
  .msg.priv.regResult[1b];
  .msg.priv.MSGSERVER::priv_MSGSERVER;
  .qtb.matchValue["Call log";
                  ([] functionName:``logf`logf`dropConnection;
                      arguments:((::);
                                 "Registration request result: 1";
                                 "Received unexpected registration message, current state: OTHER";
                                 (::)));
                  .qtb.getFuncallLog[]]}];

.qtb.suite`priv`receiveMsg;

.qtb.addBeforeAll[`priv`receiveMsg;{[]
  dispatch_call::.dispatch.call;
  .dispatch.call::.qtb.wrapLogCall[`dispatch_call;{[msg]}];
  priv_MSGSERVER::.msg.priv.MSGSERVER;
  .msg.priv.MSGSERVER::42;
  }];

.qtb.addAfterAll[`priv`receiveMsg;{[]
  .dispatch.call::dispatch_call;
  .msg.priv.MSGSERVER::priv_MSGSERVER;
  }];

.qtb.addTest[`priv`receiveMsg`notforus;{[]
  .msg.priv.receiveMsg[10;`yo];
  .qtb.matchValue["Call log";.qtb.emptyFuncallLog[];.qtb.getFuncallLog[]] }];

.qtb.addTest[`priv`receiveMsg`success;{[]
  .msg.priv.receiveMsg[42;`yo];
  .qtb.matchValue["Call log";([] functionName:``dispatch_call; arguments:((::);`yo));.qtb.getFuncallLog[]]}];

.qtb.addTest[`priv`receiveMsg`fail;{[]
  logf:.msg.priv.LOGF;
  .msg.priv.LOGF::.qtb.wrapLogCall[`logf;{[msg]}];
  dispatch_call:.dispatch.call;
  .dispatch.call::.qtb.wrapLogCall[`dispatch_call;{[msg] '"kaboom"}];
  .msg.priv.receiveMsg[42;`yo];
  .msg.priv.LOGF::logf;
  .dispatch.call::dispatch_call;
  .qtb.matchValue["Call log";
                  ([] functionName:``dispatch_call`logf;
                      arguments:((::);`yo;"Message dispatch failed: kaboom"));
                  .qtb.getFuncallLog[]] }];

// priv.enqueue

.qtb.suite`priv`enqueue;
.qtb.addBeforeAll[`priv`enqueue;{[]
  logf_orig::.msg.priv.LOGF;
  .msg.priv.LOGF::.qtb.wrapLogCall[`logf;{[msg]}];  
  prim_address::.msg.priv.PRIM_ADDRESS;
  .msg.priv.PRIM_ADDRESS::`me;
  messages_orig::.msg.priv.MESSAGES;
  .msg.priv.MESSAGES::([] srcAddr:enlist `; destAddr:enlist `; msg:enlist (::));
  }];

.qtb.addAfterAll[`priv`enqueue;{[] 
  .msg.priv.LOGF::logf_orig;
  .msg.priv.PRIM_ADDRESS::prim_address;
  .msg.priv.MESSAGES::messages_orig;
  }];

.qtb.addTest[`priv`enqueue`ok;{[]
  .msg.priv.enqueue[`him;`me;"Yo!"];
  r:all .qtb.matchValue ./: (("Messages";([] srcAddr:``him; destAddr:``me; msg:((::);"Yo!")); .msg.priv.MESSAGES);
                             ("Call log";([] functionName:``logf; arguments:((::);"Message received from him for me: \"Yo!\""));.qtb.getFuncallLog[]));
  delete from `.msg.priv.MESSAGES where srcAddr=`him,destAddr=`me;
  r }];

.qtb.addTest[`priv`enqueue`notforus;{[]
  .msg.priv.enqueue[`him;`her;42];
  all .qtb.matchValue ./: (("Messages";([] srcAddr:enlist `; destAddr:enlist `; msg:enlist (::)); .msg.priv.MESSAGES);
                           ("Call log";
                            ([] functionName:``logf`logf;
                                arguments:((::);"Message received from him for her: 42";"Message is not addressed to us, ignoring"));
                            .qtb.getFuncallLog[])) }];

// priv.dropConnection

.qtb.suite`priv`dropConnection;
.qtb.addBeforeAll[`priv`dropConnection;{[]
  logf_orig::.msg.priv.LOGF;
  .msg.priv.LOGF::.qtb.wrapLogCall[`logf;{[msg]}];
  connectionDropped_orig::.msg.priv.connectionDropped;
  .msg.priv.connectionDropped::.qtb.wrapLogCall[`connDrop;{[conn]}];
  msgsrver_orig::.msg.priv.MSGSERVER;
  .msg.priv.MSGSERVER::42;
  }];

.qtb.addAfterAll[`priv`dropConnection;{[]
  .msg.priv.LOGF::logf_orig;
  .msg.priv.connectionDropped::connectionDropped_orig;
  .q.hclose::hclose;
  .msg.priv.MSGSERVER::.msg.priv.MSGSERVER;
  }];

.qtb.addTest[`priv`dropConnection`ok;{[]
  .q.hclose::.qtb.wrapLogCall[`hclose;{[conn]}];
  .msg.priv.dropConnection[];
  .qtb.matchValue["Call log";
                  ([] functionName:``logf`hclose`connDrop;
                      arguments:((::);"Dropping server connection";42;42));
                  .qtb.getFuncallLog[]] }];

.qtb.addTest[`priv`dropConnection`error;{[]
  .q.hclose::.qtb.wrapLogCall[`hclose;{[conn] '"ace"}];
  errexit_orig:.msg.priv.ERREXITF;
  .msg.priv.ERREXITF::.qtb.wrapLogCall[`errexit;{[] '"jump"}];
  r:.qtb.checkX[.msg.priv.dropConnection;(::);"jump"];
  .msg.priv.ERREXITFL::errexit_orig;
  r and .qtb.matchValue["Call log";
                        ([] functionName:``logf`hclose`logf`errexit;
                             arguments:((::);"Dropping server connection";42;"Fatal error, hclose in dropConnection failed: ace";(::)));
                        .qtb.getFuncallLog[]] }];

// priv.connectionDropped

.qtb.suite`priv`connectionDropped;

.qtb.addBeforeAll[`priv`connectionDropped;{[]
  logf_orig::.msg.priv.LOGF;
  .msg.priv.LOGF::.qtb.wrapLogCall[`logf;{[msg]}];
  MSGSERVER_orig::.msg.priv.MSGSERVER;
  RECONNECT_orig::.msg.priv.RECONNECT;
  connSetup_orig::.msg.priv.connSetup;
  .msg.priv.connSetup::.qtb.wrapLogCall[`connSetup;{[]}];
  }];

.qtb.addAfterAll[`priv`connectionDropped;{[]
  .msg.priv.LOGF::logf_orig;
  .msg.priv.MSGSERVER::MSGSERVER_orig;
  .msg.priv.RECONNECT::RECONNECT_orig;
  .msg.priv.connSetup::connSetup_orig;
  }];

.qtb.addTest[`priv`connectionDropped`otherhandle;{[]
  .msg.priv.MSGSERVER::3;
  .msg.priv.RECONNECT::0b;
  .msg.priv.connectionDropped[4];
  all .qtb.matchValue ./: (("Connection handle";3;.msg.priv.MSGSERVER);
                           ("Call log";.qtb.emptyFuncallLog[];.qtb.getFuncallLog[])) }];

.qtb.addTest[`priv`connectionDropped`noreconnect;{[]
  .msg.priv.RECONNECT:0b;
  .msg.priv.MSGSERVER::4;
  .msg.priv.connectionDropped[4];
  all .qtb.matchValue ./: (("Connection handle";0N;.msg.priv.MSGSERVER);
                             ("Call log";([] functionName:``logf; arguments:((::);"Server has disconnected"));.qtb.getFuncallLog[])) }];

.qtb.addTest[`priv`connectionDropped`reconnect;{[]
  .msg.priv.RECONNECT:1b;
  .msg.priv.MSGSERVER::5;
  .msg.priv.connectionDropped[5];
  all .qtb.matchValue ./: (("Connection handle";0N;.msg.priv.MSGSERVER);
                             ("Call log";([] functionName:``logf`connSetup; arguments:((::);"Server has disconnected";(::)));.qtb.getFuncallLog[])) }];


// chainCallback

.qtb.suite`priv`chainCallback;

.qtb.addBeforeAll[`priv`chainCallback;{[] delete testcb from `.; }];
.qtb.addAfterAll[`priv`chainCallback;{[] delete testcb from `.; }];

.qtb.addTest[`priv`chainCallback`notdefined;{[]
  .msg.priv.chainCallback[`testcb;.qtb.wrapLogCall[`base;{[x]}]];
  testcb 1;
  .qtb.matchValue["Callback log";([] functionName:``base; arguments:((::);1));.qtb.getFuncallLog[]] }];

.qtb.addTest[`priv`chainCallback`existing;{[]
  testcb::.qtb.wrapLogCall[`base;{[]x}];
  .msg.priv.chainCallback[`testcb;.qtb.wrapLogCall[`link1;{[x]}]];
  testcb `me;
  .qtb.matchValue["Callback log";([] functionName:``base`link1; arguments:((::);`me;`me));.qtb.getFuncallLog[]]} ];

.qtb.addTest[`priv`chainCallback`three;{[]
  testcb::.qtb.wrapLogCall[`base;{[]x}];
  .msg.priv.chainCallback[`testcb;.qtb.wrapLogCall[`link1;{[x]}]];
  .msg.priv.chainCallback[`testcb;.qtb.wrapLogCall[`link2;{[x]}]];
  testcb "a";
  .qtb.matchValue["Callback log";([] functionName:``base`link1`link2; arguments:((::);"a";"a";"a"));.qtb.getFuncallLog[]]} ];

// init

.qtb.suite`init;
.qtb.addBeforeAll[`init;{[]
  Privates_old::(.msg.priv.SERVER_ADDRESS;.msg.priv.PRIM_ADDRESS;
                 .msg.priv.RECONNECT;.msg.priv.CONNECT_TIMEOUT;
                 .msg.priv.LOGF;.msg.priv.connSetup);
  .msg.priv.connSetup::.qtb.wrapLogCall[`connSetup;{[]}];
  }];

.qtb.addAfterAll[`init;{[]
  {eval (:;x;$[-11 = type y;enlist y;y])} ./:
    flip X::(`.msg.priv.SERVER_ADDRESS`.msg.priv.PRIM_ADDRESS`.msg.priv.RECONNECT,
             `.msg.priv.CONNECT_TIMEOUT`.msg.priv.LOGF`.msg.priv.connSetup;
             Privates_old);
  }];

.qtb.addTest[`init`missingparams;{[]
  .qtb.checkX[.msg.init;`a`b!1 2;"msgclient: missing parameters"] and
    .qtb.matchValue["Call log";.qtb.emptyFuncallLog[];.qtb.getFuncallLog[]] }];

.qtb.addTest[`init`full;{[]
  reconnectflag:not .msg.priv.RECONNECT;
  .msg.init `server`primAddr`reconnect!(`myserver;`us;reconnectflag);
  all .qtb.matchValue ./: (("server";`myserver;.msg.priv.SERVER_ADDRESS);
                             ("primary address";`us;.msg.priv.PRIM_ADDRESS);
                             ("reconnect flag";reconnectflag;.msg.priv.RECONNECT);
                             ("Call log";([] functionName:``connSetup; arguments:((::);(::)));.qtb.getFuncallLog[])) }];


.qtb.suite`sendMsg;

.qtb.addBeforeAll[`sendMsg;{[]
  priv_CONN_STATE_orig::.msg.priv.CONN_STATE;
  priv_MSGSERVER_orig::.msg.priv.MSGSERVER;
  priv_PRIM_ADDRESS_orig::.msg.priv.PRIM_ADDRESS;
  priv_send_orig::.msg.priv.send;
  .msg.priv.send::.qtb.wrapLogCall[`priv_send;{[conn;msg]}];
  }];

.qtb.addAfterAll[`sendMsg;{[]
  .msg.priv.CONN_STATE::priv_CONN_STATE_orig;
  .msg.priv.MSGSERVER::priv_MSGSERVER_orig;
  .msg.priv.send::priv_send_orig;
  .msg.priv.PRIM_ADDRESS::priv_PRIM_ADDRESS_orig;
  }];

.qtb.addTest[`sendMsg`ok;{[]
  .msg.priv.CONN_STATE::`connected;
  .msg.priv.MSGSERVER::42;
  .msg.priv.PRIM_ADDRESS::`alice;
  .msg.sendMsg[`bob;([] c:1 2)];
  .qtb.matchValue["Call log";([] functionName:``priv_send; arguments:((::);(42;(`sendMessage;`alice;`bob;([] c:1 2)))));.qtb.getFuncallLog[]]}];

.qtb.addTest[`sendMsg`noconn;{[]
  .msg.priv.CONN_STATE:`registration_pending;
  .msg.priv.MSGSERVER::43;
  r:.qtb.checkX[.msg.sendMsg;(`alice;"Yo!");"msgclient: not connected"];
  r and .qtb.matchValue["Call log";.qtb.emptyFuncallLog[];.qtb.getFuncallLog[]] }];


// nextMsg

.qtb.suite`nextMsg;
.qtb.addBeforeAll[`nextMsg;{[] MESSAGES_orig::.msg.priv.MESSAGES; }];
.qtb.addAfterAll[`nextMsg;{[] .msg.priv.MESSAGES::MESSAGES_orig; }];

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
  all .qtb.matchValue ./: (("Receives messages";(m1;m2;m3;();());1 _ msgs);
                             ("Message queue";([] srcAddr:enlist `; destAddr:enlist `; msg:enlist (::));.msg.priv.MESSAGES)) }];
