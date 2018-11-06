// Local Message Router

// Protocol:
// * All communications are asynchronous (unless absolutely required)
// * Anybody can connect, but first has to register a primary id (address)
// * Messages are forwarded as they come in

\l dispatch.q

// Utilities
el:{x,()}; // ensures that the result is always a list

// Logging facility, to be expanded
lg:{[msg] -1 msg; };

CONNS:([primaryAddress:`$()] clientHandle:`int$());


registerClient:{[handle;primAddr] send[handle;] (`regResult;processRegistration[handle;primAddr]); };

// The primary id being registered must not be in use
processRegistration:{[handle;primAddr]
  if[null primAddr;
    lg "regQuest for null (invalid) handle";
    :0b];
 
  registeredHandle:CONNS[primAddr;`clientHandle];
  primAddrS:string primAddr;
  if[null registeredHandle;
    lg "Registering client with primary address ",primAddrS;
    `CONNS upsert (primAddr; handle);
    :1b];
 
  if[isValidConnHandle registeredHandle;
    :$[handle = registeredHandle;
       [lg "Re-registration from client ",primAddrS;             1b];
       [lg "Failed registration for primary address ",primAddrS; 0b]]];
       
  lg "Warning: Found invalid handle for primary address ",primAddrS,", replacing registration";
  connectionDropped registeredHandle;
  `CONNS upsert (primAddr; handle);
  1b };

sendMessage:{[handle;srcAddr;destAddr;msg]
  lg "Message from ",(string srcAddr)," to ",(string destAddr)," received: ",-3!msg;
  if[isRegisteredClient[handle;srcAddr];
    tgth:CONNS[destAddr;`clientHandle];
    $[null tgth; lg "Unknown address, cannot forward message";
                 [submitMessage[(`receive;srcAddr;destAddr;msg);destAddr;tgth];
                 lg "Message forwarded"]]];
  };

// we only export these two functions to for remote calling
.dispatch.registerFunc[`regRequest;`registerClient;-6 -11h];
.dispatch.registerFunc[`sendMessage;`sendMessage;-6 -11 -11 0Nh];

submitMessage:{[msg;clientAddress;clientHandle]
  r:.[{[h;m] send[h;m];1b};(clientHandle;msg);{(0b;x)}];
  if[not first r;
    lg "Failed to send message to client ",(string clientAddress),": ",r 1];
  };

isRegisteredClient:{[handle;primAddr]
  ch:CONNS[primAddr;`clientHandle];
  $[null ch;     [lg "Received request from unregistered client ",string primAddr;     0b];
    ch <> handle;[lg "Received request with invalid primary address ",string primAddr; 0b];
                  1b] };

isValidConnHandle:{x in key .z.W};

connectionDropped:{[handle]
  primAddresses:exec primaryAddress from CONNS where clientHandle = handle;
  if[0 > c:count primAddresses; die "Unexpected result from select in connectionDropped"];
  if[1 < c;                     die "Corrupt connection tracking"];
  if[0 = c;                     :(::)];  // unknown handle, nothing to do 
  
  // if we reach this point, we have a valid client connection
  primAddr:first primAddresses;
  lg "Client ",(string primAddr)," closed the connection";
  delete from `CONNS where primaryAddress = primAddr;
  };

die:{ lg x; exit 1; }; // never returns

send:{[handle;msg] (neg handle) msg; };

receiveMsg:{[ch;msg]
  lg "Received msg ",(-3!msg);
  req:$[10 = type msg; parse msg; msg];
  
  resp:@[{[args] (1b;) .dispatch.call@args}; first[req],ch,1 _ req; {[err] (0b;err)}];
  $[first resp;     lg "Successfully processed request, result: ",-3!last resp;
    not first resp; lg "Error evaluating request: ",last resp;
                    lg "Internal error, invalid evaluation result: ",-3!resp];
  lg "Request processing complete";
  };

// Remote communication callbacks

// Client connect
.z.po:{ lg "Connection setup from ",(string .z.a),", user ",string .z.u; };

// Connection close
.z.pc:connectionDropped;

// We don't do http
.z.ph:{[x;y] '"denied"};

// No synchronous calls either (may have to be revisited)
.z.pg:{'"sync"};

// Process async request
.z.ps:{[msg] receiveMsg[.z.w;msg]; };

