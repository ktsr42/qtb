\l ctxa.q
l1:42;

\d .otherctx

\l ctxb.q
l2:"42";

\l ctxc.q
l3:`42;

\l avar.q

// Unit tests

\d .loadtests

toString:{[v] $[10 = type v;v;string v]};

check_variableValue:{[vname;expval]
  r:@[{(0b;value x)};vname;(1b;)];
  if[first r; -1 "Variable ",string[vname]," is undefined"; :0b];
  actval:last r;
  if[not actval ~ expval;
    -1 "Variable ",string[vname]," has the wrong value. Expected: ",toString[expval],", actual: ",toString actval];
  actval ~ expval };

check_variableValues:{[]
  all check_variableValue ./: ((`.a.avar;42);(`.b.avar;"42");(`.c.avar;`42);(`.d.avar;42j);(`l1;42);(`.otherctx.l2;"42");(`.otherctx.l3;`42))
  };

match_context:{[ctxName;expMembers]
  actMembers:key[ctxName] where not null key ctxName;
  expMembers1:(),expMembers;
  missing:expMembers1 except actMembers;
  if[0 < count missing;
    -1 "Missing elements in context ",string[ctxName],": "," " sv string missing];
  unexpected:actMembers except expMembers1;
  if[0 < count unexpected;
    -1 "Unexpected members in context ",string[ctxName],": "," " sv string unexpected];
  all 0 = count each (missing;unexpected) };

check_contexts:{[]
  all match_context ./: ((`.a;`avar`afunc);(`.b;`avar);(`.c;`avar);(`.d;`avar);(`.otherctx;`l2`l3`xvar))  };

\d .

ALLTESTS:`.loadtests.check_variableValues`.loadtests.check_contexts;

\l ../tb/testbench.q

