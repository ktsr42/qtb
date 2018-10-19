// Unit tests for the message server

\l ../qtb.q
\l msgsrvr.q

// --- registerClient is trivial

.qtb.setOverrides[`;enlist[`lg]!enlist .qtb.callLogS`lg];

// *** processRegistration
.qtb.suite`processRegistration;
.qtb.setOverrides[`processRegistration;`isValidConnHandle`CONNS!({[ignore] 1b};0#CONNS)];

.qtb.addTest[`processRegistration`successful_add;{[]
  r:processRegistration[22;`me];
  checks:(("CONNS table";([primaryAddress:el `me] clientHandle:el 22i);CONNS);
          ("logging calls";([] functionName:``lg; arguments:((::);"Registering client with primary address me"));.qtb.getFuncallLog[]));
  all r,.qtb.matchValue ./: checks }];

.qtb.addTest[`processRegistration`duplicate;{[]
  .qtb.override[`CONNS;([primaryAddress:el `me] clientHandle:el 22)];
  r:processRegistration[22;`me];
  checks:(("CONNS table";([primaryAddress:el `me] clientHandle:el 22);CONNS);
          ("logging calls";([] functionName:``lg; arguments:((::);"Re-registration from client me"));.qtb.getFuncallLog[]));
  all r,.qtb.matchValue ./: checks}];

.qtb.addTest[`processRegistration`replace;{[]
  .qtb.override[`CONNS;([primaryAddress:el `me] clientHandle:el 22)];
  .qtb.override[`connectionDropped;.qtb.callLogS`connectionDropped];
  .qtb.override[`isValidConnHandle;{[ignore] 0b}];
  r:processRegistration[23;`me];
  checks:(("CONNS table";([primaryAddress:el `me] clientHandle:el 23);CONNS);
          ("Function calls";
          ([] functionName:``lg`connectionDropped;
              arguments:((::);"Warning: Found invalid handle for primary address me, replacing registration";enlist 22));
          .qtb.getFuncallLog[]));
  all r,.qtb.matchValue ./: checks }];

.qtb.addTest[`processRegistration`clash;{[]
  .qtb.override[`CONNS;conns:([primaryAddress:el `me] clientHandle:el 22)];
 
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
.qtb.setOverrides[`sendMessage;`CONNS`isRegisteredClient`submitMessage!(([primaryAddress:`me`you] clientHandle:10 11);.qtb.callLog[`isRegisteredClient;1b];.qtb.callLogS`submitMessage)];

.qtb.addTest[`sendMessage`aok;{[]
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
  sendMessage[10;`me;`him;"are you ok?"];
  .qtb.matchValue["Call log";
     ([] functionName:``lg`isRegisteredClient`lg;
         arguments:((::);"Message from me to him received: \"are you ok?\"";(10;`me);"Unknown address, cannot forward message"));
     .qtb.getFuncallLog[]] }];

.qtb.addTest[`sendMessage`notregistered;{[]
  .qtb.override[`isRegisteredClient;.qtb.callLog[`isRegisteredClient;0b]];
  sendMessage[10;`me;`him;"are you ok?"];
  .qtb.matchValue["Call log";
     ([] functionName:``lg`isRegisteredClient;
         arguments:((::);"Message from me to him received: \"are you ok?\"";(10;`me)));
     .qtb.getFuncallLog[]] }];


// *** submitMessage
.qtb.suite`submitMessage;
.qtb.setOverrides[`submitMessage;enlist[`send]!enlist .qtb.callLogS`send];

.qtb.addTest[`submitMessage`ok;{[]
  submitMessage["ayt?";`aclient;10];
  .qtb.matchValue["Call log";([] functionName:``send; arguments:((::);(10;"ayt?")));.qtb.getFuncallLog[]]} ];

.qtb.addTest[`submitMessage`fail;{[]
  .qtb.override[`send;.qtb.callLog[`send;{[h;msg] '"oops!"}]];
  submitMessage["dang!";`badboy;11];
  .qtb.matchValue["Call log";
                  ([] functionName:``send`lg; arguments:((::);(11;"dang!");"Failed to send message to client badboy: oops!"));
                  .qtb.getFuncallLog[]]} ];

// *** confirmRegisteredClient
.qtb.suite`isRegisteredClient;

.qtb.setOverrides[`isRegisteredClient;enlist[`CONNS]!enlist (0#CONNS) upsert (`him;42)];

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
.qtb.setOverrides[`connectionDropped;enlist[`CONNS]!enlist (0#CONNS) upsert (`him;42i)];

.qtb.addTest[`connectionDropped`validhandle;{[]
  connectionDropped 42i;
  r:0 = count exec primaryAddress from CONNS where clientHandle = 42;
  r and .qtb.matchValue["Call log";([] functionName:``lg; arguments:((::);"Client him closed the connection"));.qtb.getFuncallLog[]] }];

.qtb.addTest[`connectionDropped`invalidhandle;{[]
  connectionDropped 100i;
  (1 = count select from CONNS where primaryAddress = `him,clientHandle = 42)
  and .qtb.matchValue["Call log";.qtb.emptyFuncallLog[];.qtb.getFuncallLog[]] }];

.qtb.addTest[`connectionDropped`sanitycheck;{[]
  .qtb.override[`CONNS;([primaryAddress:`a`b]; clientHandle:3 3i)];
  .qtb.override[`die;.qtb.callLogS`die];
  connectionDropped 3i;
  :.qtb.getFuncallLog[] ~ ([] functionName:``die`lg; arguments:((::);"Corrupt connection tracking";"Client a closed the connection"));
  }];

// *** receiveMsg

.qtb.suite`receiveMsg;

.qtb.setOverrides[`receiveMsg;enlist[`.dispatch.call]!enlist .qtb.callLogS`.dispatch.call];

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
  .qtb.override[`.dispatch.call;.qtb.callLog[`.dispatch.call;{[req] '"whoops!"}]];
  receiveMsg[3;(`afunc;`xx)];
  .qtb.matchValue["Function call log";
                  E::([] functionName:``lg`.dispatch.call`lg`lg;
                      arguments:((::);
                                 "Received msg `afunc`xx";
                                 (`afunc;3;`xx);
                                 "Error evaluating request: whoops!";
                                 "Request processing complete"));
                   A::.qtb.getFuncallLog[]]}];

.qtb.addTest[`receiveMsg`string;{[]
  receiveMsg[13;"afunc[`arg]"];
  .qtb.matchValue["Function call log";
                  ([] functionName:``lg`.dispatch.call`lg`lg;
                      arguments:((::);
                                 "Received msg \"afunc[`arg]\"";
                                 (`afunc;13;enlist `arg);
                                 "Successfully processed request, result: ::";
                                 "Request processing complete"));
                   .qtb.getFuncallLog[]]}];


.qtb.run[];
