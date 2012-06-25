// client library for the message server

\l dispatch.q

\d .msg

// Internal data and helper functions
priv.SERVER_ADDRESS:`;
priv.MSGSERVER:0N;
priv.PRIM_ADDRESS:`;
priv.RECONNECT:0b;
priv.CONNECT_TIMEOUT:60000; // one minute
priv.LOGF:{@[-1;x;{}]};
priv.CONN_STATE:`disconnected;
priv.ERREXITF:{exit 1;};

priv.send:{[h;m] (neg h) m};

priv.MESSAGES:([] srcAddr:enlist `; destAddr:enlist `; msg:enlist (::));

// initiate the connection to the server
priv.connSetup:{[]
  sh:.q.hopen (hsym priv.SERVER_ADDRESS;priv.CONNECT_TIMEOUT); // may throw a 'timeout or something else, like 'access
  priv.send[sh;(`regRequest;priv.PRIM_ADDRESS)];
  priv.CONN_STATE::`registration_pending;
  priv.MSGSERVER::sh;
  };

// called by the server during registration
priv.regResult:{[result]
  priv.LOGF "Registration request result: ",string result;
  
  if[priv.CONN_STATE <> `registration_pending;  // are we expecting this message?
    priv.LOGF "Received unexpected registration message, current state: ",string priv.CONN_STATE;
    if[not null priv.MSGSERVER;
      priv.dropConnection[]]];
 
  $[result;
    priv.CONN_STATE::`connected; // registration was successful
    priv.dropConnection[]];      // we could not register for some reason
  };

priv.receiveMsg:{[connH;msg]
  if[connH ~ priv.MSGSERVER; // silently ignore messages that do not come from our server
    @[.dispatch.call; msg; {[err] priv.LOGF "Message dispatch failed: ",err;}]];
  };

// called by the server with a message for us
priv.enqueue:{[srcAddr;destAddr;msg]
  priv.LOGF "Message received from ",(string srcAddr), " for ",(string destAddr),": ",-3!msg;
  if[not destAddr ~ priv.PRIM_ADDRESS;
   priv.LOGF "Message is not addressed to us, ignoring";
   :(::)];
 
  @[{[rec] `.msg.priv.MESSAGES upsert rec}; (srcAddr;destAddr;msg);
      {[err] priv.LOGF "Failed to enqueue message: ",err;}];
   };

priv.dropConnection:{[]
  priv.LOGF "Dropping server connection";
  @[{.q.hclose x}; priv.MSGSERVER; {[err] priv.LOGF "Fatal error, hclose in dropConnection failed: ",err; priv.ERREXITF[];}];
  priv.connectionDropped priv.MSGSERVER;
  };

priv.connectionDropped:{[handle]
  if[handle ~ priv.MSGSERVER;
    priv.LOGF "Server has disconnected";
    priv.MSGSERVER::0N;
    priv.CONN_STATE:`disconnected;
    if[priv.RECONNECT; priv.connSetup[]]];
  };

priv.mapNull:{[val;default] $[null val;default;val]};

// we only support callbacks with one argument
priv.chainCallback:{[cbName;newfunc]
  // Assign a wrapper function to the given callback (any var).
  // The wrapper takes as argument a list of functions to call.
  // When created, the current value of the given callback name is added to the first
  // argument of the wrapper func, on which it is projected.
  eval (:;cbName;{[funcl;arg] @[;arg;{}] each funcl; }[(@[value;cbName;{{}}];newfunc);]);
  };

// Public interface
// * server: `:host:port of message server
// * primAddr: our primary address (symbol)
// * reconnect: boolean to indicate if we should try to reconnect to the server when we loose the connection
// * timeout: integer, number of ms to wait for a successful connection setup
// * logf: Logging function, must accept one parameter
// * errexitf: Function to call when we think the error warrants killing the current process
init:{[params]
  // mandatory parameters
  if[any null params`server`primAddr;'"msgclient: missing parameters"];
  priv.SERVER_ADDRESS:: params`server;
  priv.PRIM_ADDRESS::   params`primAddr;
  // optional params
  priv.RECONNECT::      priv.mapNull[params`reconnect;priv.RECONNECT];
  priv.CONNECT_TIMEOUT::priv.mapNull[params`timeout;priv.CONNECT_TIMEOUT];
  priv.LOGF::           priv.mapNull[params`logf;priv.LOGF];
  priv.ERREXITF::       priv.mapNull[params`errexitf;priv.ERREXITF];
 
  priv.connSetup[];
  };

sendMsg:{[destAddr;msg]
  if[priv.CONN_STATE <> `connected; '"msgclient: not connected"];
  priv.send[priv.MSGSERVER;(`sendMessage;priv.PRIM_ADDRESS;destAddr;msg)];
  };

nextMsg:{[]
  if[1 = count priv.MESSAGES; :()]; // no messages left;
  msg:priv.MESSAGES 1;
  delete from `.msg.priv.MESSAGES where i=1;
  msg };

// Override async message handler and connection dropped callback
priv.chainCallback[`.z.pc;priv.connectionDropped];
priv.chainCallback[`.z.ps;{[msg] priv.receiveMsg[.z.w;msg]}];

.dispatch.registerFunc[`receive;`.msg.priv.enqueue;-11 -11 0Nh];
.dispatch.registerFunc[`regResult;`.msg.priv.regResult;-1h];