// Unit tests for the message server

\l ../qtb.q
\l msgsrvr.q

// --- registerClient is trivial

// *** processRegistration
.qtb.suite`processRegistration;

.qtb.addBeforeAll[`processRegistration;{[]
  isValidConnHandle_ORIG::isValidConnHandle;
  isValidConnHandle::{[ignore] 1b};
  lg_ORIG::lg;
  lg::.qtb.wrapLogCall[`lg;{[msg] }];
  }];

.qtb.addAfterAll[`processRegistration;{[]
  isValidConnHandle::isValidConnHandle_ORIG;
  lg::lg_ORIG
  }];

.qtb.addBeforeEach[`processRegistration;{[]
  CONNSorig::CONNS; CONNS::0#CONNS;
  .qtb.resetFuncallLog[];
  }];

.qtb.addAfterEach[`processRegistration;{[] CONNS::CONNSorig; }];

.qtb.addTest[`processRegistration`successful_add;{[]
  r:processRegistration[22;`me];
  checks:(("CONNS table";([primaryAddress:el `me] clientHandle:el 22);CONNS);
          ("logging calls";([] functionName:``lg; arguments:((::);"Registering client with primary address me"));.qtb.getFuncallLog[]));
  all r,.qtb.matchValue ./: checks }];

.qtb.addTest[`processRegistration`duplicate;{[]
  CONNS::([primaryAddress:el `me] clientHandle:el 22);
  r:processRegistration[22;`me];
  checks:(("CONNS table";([primaryAddress:el `me] clientHandle:el 22);CONNS);
          ("logging calls";([] functionName:``lg; arguments:((::);"Re-registration from client me"));.qtb.getFuncallLog[]));
  all r,.qtb.matchValue ./: checks}];

.qtb.addTest[`processRegistration`replace;{[]
  CONNS::([primaryAddress:el `me] clientHandle:el 22);
  connectionDroppedOrig:connectionDropped;
  connectionDropped::.qtb.wrapLogCall[`connectionDropped;{[conn]}];
  isValidConnHandle::{[ignore] 0b};
  r:processRegistration[23;`me];
  checks:(("CONNS table";([primaryAddress:el `me] clientHandle:el 23);CONNS);
          ("Function calls";
          ([] functionName:``lg`connectionDropped;
              arguments:((::);"Warning: Found invalid handle for primary address me, replacing registration";22));
          .qtb.getFuncallLog[]));
  connectionDropped::connectionDroppedOrig;
  isValidConnHandle::{[ignore] 1b};
  all r,.qtb.matchValue ./: checks }];

.qtb.addTest[`processRegistration`clash;{[]
  CONNS::conns:([primaryAddress:el `me] clientHandle:el 22);
 
  r:processRegistration[33;`me]; 
  checks:(("CONNS table";conns;CONNS);
          ("Funcall log";
          ([] functionName:``lg; arguments:((::);"Failed registration for primary address me"));
          .qtb.getFuncallLog[]));
  all (not r),.qtb.matchValue ./: checks}];

.qtb.addTest[`processRegistration`nulladdr;{[]
  r:processRegistration[22;`];
  all (not r),.qtb.matchValue["logging calls";
                              ([] functionName:``lg; arguments:((::);"regQuest for null (invalid) handle"));
                              .qtb.getFuncallLog[]] }];

// *** sendMessage
.qtb.suite`sendMessage;

.qtb.addBeforeAll[`sendMessage;{[]
  CONNS_orig::CONNS;
  lg_ORIG::lg;
  lg::.qtb.wrapLogCall[`lg;{[msg] }];
  isRegisteredClient_orig::isRegisteredClient;
  isRegisteredClient::.qtb.wrapLogCall[`isRegisteredClient;{[h;srca] 1b}];
  submitMessage_orig::submitMessage;
  submitMessage::.qtb.wrapLogCall[`submitMessage;{[msg;clAddr;clHandle]}];
  }];

.qtb.addAfterAll[`sendMessage;{[]
  lg::lg_ORIG;
  CONNS::CONNS_orig;
  isRegisteredClient::isRegisteredClient_orig;
  submitMessage::submitMessage_orig;
  }];

.qtb.addBeforeEach[`sendMessage;{[] .qtb.resetFuncallLog[]; }];

.qtb.addTest[`sendMessage`aok;{[]
  CONNS::([primaryAddress:`me`you] clientHandle:10 11);
  sendMessage[10;`me;`you;"are you ok?"];
  .qtb.matchValue["Call log";
    ([] functionName:``lg`isRegisteredClient`submitMessage`lg;
        arguments:((::);
                   "Message from me to you received: \"are you ok?\"";
                   (10;`me);
                   ((`receive;`me;`you;"are you ok?");`you;11);
                   "Message forwarded"));
    .qtb.getFuncallLog[]] }];


.qtb.addTest[`sendMessage`notok;{[]
  CONNS::([primaryAddress:`me`you] clientHandle:10 11);
  sendMessage[10;`me;`him;"are you ok?"];
  .qtb.matchValue["Call log";
     ([] functionName:``lg`isRegisteredClient`lg;
         arguments:((::);"Message from me to him received: \"are you ok?\"";(10;`me);"Unknown address, cannot forward message"));
     .qtb.getFuncallLog[]] }];

.qtb.addTest[`sendMessage`notregistered;{[]
  CONNS::([primaryAddress:`me`you] clientHandle:10 11);
  isRegClient_ORIG:isRegisteredClient;
  isRegisteredClient::.qtb.wrapLogCall[`isRegisteredClient;{[h;ca] 0b}];
  sendMessage[10;`me;`him;"are you ok?"];
  isRegisteredClient::isRegClient_ORIG;
  .qtb.matchValue["Call log";
     ([] functionName:``lg`isRegisteredClient;
         arguments:((::);"Message from me to him received: \"are you ok?\"";(10;`me)));
     .qtb.getFuncallLog[]] }];


// *** submitMessage
.qtb.suite`submitMessage;

.qtb.addBeforeAll[`submitMessage;{[]
  send_orig::send;
  send::.qtb.wrapLogCall[`send;{[h;m]}];
  lg_orig::lg;
  lg::.qtb.wrapLogCall[`lg;{[msg]}]; }];

.qtb.addAfterAll[`submitMessage;{[] send::send_orig; lg::lg_orig; }];
.qtb.addBeforeEach[`submitMessage;{[] .qtb.resetFuncallLog[]; }];

.qtb.addTest[`submitMessage`ok;{[]
  submitMessage["ayt?";`aclient;10];
  .qtb.matchValue["Call log";([] functionName:``send; arguments:((::);(10;"ayt?")));.qtb.getFuncallLog[]]} ];

.qtb.addTest[`submitMessage`fail;{[]
  send_orig:send;
  send::.qtb.wrapLogCall[`send;{[h;msg] '"oops!"}];
  submitMessage["dang!";`badboy;11];
  send::send_orig;
  .qtb.matchValue["Call log";
                  ([] functionName:``send`lg; arguments:((::);(11;"dang!");"Failed to send message to client badboy: oops!"));
                  .qtb.getFuncallLog[]]} ];

// *** confirmRegisteredClient
.qtb.suite`isRegisteredClient;

.qtb.addBeforeAll[`isRegisteredClient;{[]
  lg_orig::lg;
  lg::.qtb.wrapLogCall[`lg;{[msg]}];
  CONNSorig::CONNS;
  CONNS::(0#CONNS) upsert (`him;42);
  }];

.qtb.addAfterAll[`isRegisteredClient;{[] lg::lg_orig; CONNS::CONNSorig }];

.qtb.addBeforeEach[`isRegisteredClient;{[] .qtb.resetFuncallLog[]; }];

.qtb.addTest[`isRegisteredClient`ok;{[] isRegisteredClient[42;`him] }];
.qtb.addTest[`isRegisteredClient`unreg;{[]
  r:isRegisteredClient[43;`her];
  (not r) and .qtb.matchValue["Call log";
                              ([] functionName:``lg; arguments:((::);"Received request from unregistered client her"));
                              .qtb.getFuncallLog[]] }];

.qtb.addTest[`isRegisteredClient`invalid;{[]
  r:isRegisteredClient[10;`him];
  (not r) and .qtb.matchValue["Call log";
                              ([] functionName:``lg; arguments:((::);"Received request with invalid primary address him"));
                              .qtb.getFuncallLog[]] }];

// *** connectionDropped
.qtb.suite`connectionDropped;

.qtb.addBeforeAll[`connectionDropped;{[]
  lg_orig::lg;
  lg::.qtb.wrapLogCall[`lg;{[msg]}];
  CONNSorig::CONNS;
  }];

.qtb.addAfterAll[`connectionDropped;{[] lg::lg_orig; CONNS::CONNSorig }];

.qtb.addBeforeEach[`connectionDropped;{[] 
  CONNS::(0#CONNS) upsert (`him;42);
  .qtb.resetFuncallLog[];
  }];

.qtb.addTest[`connectionDropped`validhandle;{[]
  connectionDropped[42];
  r:0 = count exec primaryAddress from CONNS where clientHandle = 42;
  r and .qtb.matchValue["Call log";([] functionName:``lg; arguments:((::);"Client him closed the connection"));.qtb.getFuncallLog[]] }];

.qtb.addTest[`connectionDropped`invalidhandle;{[]
  connectionDropped[100];
  (1 = count select from CONNS where primaryAddress = `him,clientHandle = 42)
  and .qtb.matchValue["Call log";.qtb.emptyFuncallLog[];.qtb.getFuncallLog[]] }];


// *** receiveMsg

.qtb.suite`receiveMsg;
.qtb.addBeforeAll[`receiveMsg;{[]
  lg_orig::lg;
  lg::.qtb.wrapLogCall[`lg;{[msg]}];
  dispatch_call_orig::.dispatch.call;
  .dispatch.call::.qtb.wrapLogCall[`.dispatch.call;{[args]}];
  }];

.qtb.addAfterAll[`receiveMsg;{[]
  .dispatch.call::dispatch_call_orig;
  lg::lg_orig;
  }];

.qtb.addBeforeEach[`receiveMsg;{[] .qtb.resetFuncallLog[]; }];

.qtb.addTest[`receiveMsg`ok;{[]
  receiveMsg[10;(`afunc;`arg)];
  .qtb.matchValue["Function call log";
                  ([] functionName:``lg`.dispatch.call`lg`lg;
                      arguments:((::);
                                 "Received msg `afunc`arg";
                                 (`afunc;10;`arg);
                                 "Successfully processed request, result: ::";
                                 "Request processing complete"));
                   .qtb.getFuncallLog[]]}];

.qtb.addTest[`receiveMsg`error;{[]
  dispatch_call_orig:.dispatch.call;
  .dispatch.call::.qtb.wrapLogCall[`.dispatch.call;{[req] '"whoops!"}];
  receiveMsg[3;(`afunc;`xx)];
  .dispatch.call::dispatch_call_orig;
  .qtb.matchValue["Function call log";
                  ([] functionName:``lg`.dispatch.call`lg`lg;
                      arguments:((::);
                                 "Received msg `afunc`xx";
                                 (`afunc;3;`xx);
                                 "Error evaluating request: whoops!";
                                 "Request processing complete"));
                   .qtb.getFuncallLog[]]}];

.qtb.addTest[`receiveMsg`string;{[]
  receiveMsg[13;"afunc[`arg]"];
  .qtb.matchValue["Function call log";
                  EL::([] functionName:``lg`.dispatch.call`lg`lg;
                      arguments:((::);
                                 "Received msg \"afunc[`arg]\"";
                                 (`afunc;13;enlist `arg);
                                 "Successfully processed request, result: ::";
                                 "Request processing complete"));
                   .qtb.getFuncallLog[]]}];
