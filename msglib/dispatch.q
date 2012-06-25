// dispatch.q

// A module to dispatch messages as function calls. These are not
// considered remote procedure calls, because there is no response
// guaranteed. However, there may be a response from the function
// called, but the originator of the message is not expected to
// wait for it (asynchronous communication).

\d .dispatch

/////
// All remotely accesible functions
FUNCTIONS:([name:enlist `] realname:enlist `; argTypes:enlist (::));

// a helper function, tested as part of qtb.q
countargs:{[fp]
  mfp:value fp;
  if[4 = type first mfp; :count mfp 1]; // a simple function
  basef:first mfp;
  if[not (type basef) within 100 104; '"Unsupported function type"];
  // compute the number of arguments of a projection:
  // (num args of base function) less number of arguments provided in the projection
  (count (value basef) 1) - sum not (::) ~/: 1 _ mfp };

// register "name" as the callable function name, pointing to the function with "name"
// args is a list of shorts with the expected type values of the arguments (use 0Ns for any type)
// verifies that name indeed resolves to a function and that has the number of given arguments
registerFunc:{[alias;name;args]
  realfunc:@[eval;name;{[name;dummy] '"dispatch: function ",(string name)," is not defined"}[name;]];
  if[100 > type realfunc; '"dispatch: ",(string name)," is not a function"];
  if[countargs[realfunc] <> count args; '"dispatch: signature mismatch"];
  
  `.dispatch.FUNCTIONS upsert (alias;name;args);
  };

deregister:{[alias] delete from `.dispatch.FUNCTIONS where name=alias; };

call:{[req]
  func:first req;
  args:1 _ (),req;
  funcS:string func;
  signature:(),FUNCTIONS[func;`argTypes];
  if[enlist[(::)] ~ signature;
    '"dispatch: unknown function '",funcS,"'"];
  if[(count signature) <> count args;
    '"dispatch: function '",funcS,"' requires ",(string count signature)," arguments"];
  argTypes:type each args;
  // A null value in the signature indicates that that argument can be any type
  if[not all (~') . (argTypes;signature) @\: where not null signature;
    '"dispatch: arg type mismatch"];
  // Ok, looks kosher. Apply any translation and execute. As we stick it into eval
  // we have to escape symbols. Rationale: Remote function calls should never
  // reference local variables. The eval tree to call a function with no arguments
  // is (name;::), so this requires a special case.
  eval FUNCTIONS[func;`realname],{$[-11 = type x;enlist x;x]} each $[0 < count args;args;(::)];
  };
