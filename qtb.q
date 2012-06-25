// Q Test Bench - A framework for writing unit tests in Q
//
// Copyright (C) 2012 Klaas Teschauer
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// Interface
// =========
//
// suite[pathname] - create a new suite (creates subtree)
// addTest[pathname;func] - pathname is a list that gives the suite and
//                          name of the test
// addBeforeAll[pathname;func] - pathname must be an existing suite
//   dto. addBeforeEach, addAfterEach, addAfterAll
// execute[pathname] - run the tests in the suite/tree specified by pathname,
//                     which may be empty.
//
// Design and Implementation notes
//
// We store the tests in a global tree. The user should not touch it directly.
// The special init/cleanup nodes are members of the tree that have special
// names (e.g. `_BEFOREALL). The value of that node is a list of lambdas
// which are executed in order.
//
// Test execution:
// * recurse through all branches, pass down two lists: beforeEach and afterEach
// * at each branch, first execute beforeAll
// * add the branch's beforeEach and afterEach to the lists
// * then execute all tests, i.e. all beforeEach, test and all afterEach
// * recurse into sub-branches, passing down the enhanced beforeEach and afterEach lists
// * execute afterAll

// TODO: Logging/output control, including support for different log levels
// TODO: Consider making arguments to executeSuite and executeTest dictionaries

// a simple tree library
//
// Path is specified, branches are created as necessary
// Insert of a node at a branch level is an error

\d .tree

new:{[]
  ([id:enlist 0j] parentId:enlist 0j; nodeName:enlist `; nodeType:enlist `branch; nodeValue:enlist (::))};

validTree:{[tree]
  parentIds:exec parentId from tree;
  nodeIds:exec id from tree;
  // the nodeType is either branch or leaf
  if[not all (exec distinct nodeType from tree) in `branch`leaf; '"tree: invalid node type"];
  // all branches have an empty node value
  if[not all (::) ~/: exec nodeValue from tree where nodeType=`branch; '"tree: unexpected value for branch"];
  // all parentIds refer to valid nodes. This also covers the root node with id 0j and its own parent.
  if[not 0 = count (distinct parentIds) except nodeIds; '"tree: invalid parent node(s)"];
  // no duplicate ids (may be redundant; use sort to avoid ordering issues for ~)
  if[not (asc distinct nodeIds) ~ asc nodeIds; '"tree: duplicate node ids"];
  // all parentIds refer to branch nodes
  if[not enlist[`branch] ~ exec distinct nodeType from tree where id in distinct parentIds; '"tree: leaf as parent"];
  // The data structure (child -> parent) makes cycles impossible.
  // no multiple roots. Note: A table with multiple roots must have more than the node being its own parent.
  if[0 < count select id from tree where id = parentId,id <> 0j;'"tree: multiple roots"];
  1b };


// path has the list of branch node names, the last element is the name of the node to create or overwrite
insertLeaf:{[tree;path;nodeValue]
  pnid:priv.findNodeId[tree;-1 _ path,()];
  if[null pnid; '"tree: invalid path"];
  nid:first exec id from tree where parentId = pnid, nodeName = last path;
  newNodeRec:$[not null nid;
               $[`branch = tree[nid;`nodeType]; '"tree: isbranch";
                 `leaf   = tree[nid;`nodeType]; (nid;pnid;last path;`leaf;nodeValue);  // overwrite existing node
                                                '"tree: corrupt"];
               (1 + exec max id from tree;pnid;last path;`leaf;nodeValue)];  // create new node
  tree upsert newNodeRec };
    
createBranch:{[tree;path]
  pnid:priv.findNodeId[tree;-1 _ path,()];
  if[null pnid; '"tree: invalid path"];
  nid:first exec id from tree where parentId = pnid, nodeName = last path;
  if[not null nid; '"tree: node exists"];
  tree upsert (1 + exec max id from tree;pnid;last path;`branch;(::)) };

removeNode:{[tree;path]
  nid:priv.getNodeId[tree;path];
  if[`branch = tree[nid;`nodeType];
    if[0 < exec count id from tree where parentId=nid; '"tree: branch not empty"]];
  delete from tree where id = nid };

getLeaf:{[tree;path]
  nid:priv.getNodeId[tree;path];
  ntype:tree[nid;`nodeType];
  if[`branch = ntype; '"tree: get branch"];
  if[`leaf <> ntype; '"tree: corrupt"];
  tree[nid;`nodeValue] };

// func is a two-argument function, it receives the path as the first and the node value as the second
foreach:{[tree;path;func]
  p:$[`~ path;`$();path];
  nid:priv.getNodeId[tree;path];
  $[tree[nid;`nodeType] ~ `leaf;
    enlist func[p;tree[nid;`nodeValue]];  // special case, just call func on the target leaf
    priv.foreach[tree;nid;p;func]] };

// func receives three (3) arguments.
// 1. The path of the branch
// 2. A list of all leaf nodes in this branch
// 3. A function that allows for efficient lookup of nodes in that branch
//
// If the function throws the exception "tree: nodescent" none of the subtrees of the affected node
// are visited, but the exception is otherwise ignored. Any other exception will abort the execution as
// if uncaught. If "tree: nodescent" is thrown, the return value from the affected node is the empty list ().
NodescentXcptn:"tree: nodescent";

foreachBranch:{[tree;path;func]
  p:$[` ~ path;`$();path];
  nid:priv.getNodeId[tree;p];
  $[tree[nid;`nodeType] ~ `branch;
    priv.foreachBranch[tree;nid;p;func];
    ()] };


// getLeaves[path] return all leaf nodes at branch path as a dictionary: name -m> value.
// Throw exception if path is not a branch
getLeaves:{[tree;path]
  nid:priv.getNodeId[tree;path];
  if[not tree[nid;`nodeType] ~ `branch; '"tree: not a branch"];
  (exec nodeName from tree where parentId=nid,nodeType=`leaf)!exec nodeValue from tree where parentId=nid,nodeType=`leaf };

// getBranches[path] return the list of all sub-branches of branch [path]. Error if path is not a branch

getBranches:{[tree;path]
  nid:priv.getNodeId[tree;path];
  if[not tree[nid;`nodeType] ~ `branch; '"tree: not a branch"];
  exec nodeName from tree where parentId=nid,nodeType=`branch,id <> 0j };

/////////////////////////////////////
// Helper functions

priv.findNodeId:{[tree;path]
  nodeId:0j;
  currNode:tree nodeId; // start at the root node
  rPath:path,();        // make sure we have a symbol list
  while[(0 < count rPath) and `branch = currNode`nodeType;  // while we have path elements left and are following branches
    nodeId:first exec id from tree where parentId=nodeId,nodeName=first rPath;
    if[null nodeId; 0Nj];         // find the id of the next child node, if it is 0Nj, we have an invalid path
    currNode:tree nodeId;         // step down to the subtree
    rPath:1 _ rPath];             // consume the path element
  if[0 <> count rPath; 0Nj];
  nodeId };


// nid is the id of the branch we are currently processing, path gives its path from the root of the tree
priv.foreach:{[tree;nid;path;func]
  if[null nid; '"tree: invalid path"];
  r:raze ({[tree;basePath;func;nid;nn] priv.foreach[tree;nid;basePath,nn;func] }[tree;path;func;;].)
      each flip value exec id,nodeName from tree where parentId=nid,nodeType=`branch,id <> 0j;
  r,:({[func;basePath;nn;nval] func[basePath,nn;nval] }[func;path;].)
      each flip value exec nodeName,nodeValue from tree where parentId=nid,nodeType=`leaf;
  r };

priv.leafLookup:{[leafDict;leafName]
  if[not leafName in key leafDict;'"tree: invalid leaf key"];
  leafDict leafName };

priv.foreachBranch:{[tree;nid;path;func]
  if[null nid; '"tree: invalid path"];
  leafMatrix:value exec nodeName,nodeValue from tree where parentId=nid,nodeType=`leaf;
  leafDict:leafMatrix[0]!leafMatrix 1;
  fval:.[{[func;args] (`ok;func . args)};(func;(path;leafMatrix 0;priv.leafLookup[leafDict;]));{(`xcpt;x)}];
  if[`xcpt ~ first fval;
    xcptn:last fval;
    :$[NodescentXcptn ~ xcptn;();'xcptn]]; // return or throw
  (enlist last fval),raze ({[tree;basePath;func;nid;nn] priv.foreachBranch[tree;nid;basePath,nn;func] }[tree;path;func;;].)
      each flip value exec id,nodeName from tree where parentId=nid,nodeType=`branch,id <> 0j };

priv.getNodeId:{[tree;path]
  nid:priv.findNodeId[tree;path];
  if[null nid;'"tree: invalid path"];
  nid };
  
\d .

\d .qtb

priv.Tags:`$("_BEFOREALL";"_BEFOREEACH";"_AFTEREACH";"_AFTERALL");

priv.BeforeAllTag:priv.Tags 0;
priv.BeforeEachTag:priv.Tags 1;
priv.AfterEachTag:priv.Tags 2;
priv.AfterAllTag:priv.Tags 3;

priv.nameOk:{[path] if[(last path) in priv.Tags; '"qtb: Invalid identifier"]; };

priv.ALLTESTS:.tree.new[];

priv.addSpecial:{[special;path;func] priv.ALLTESTS:.tree.insertLeaf[priv.ALLTESTS;path,special;func] };

priv.pathString:{[path] ".","." sv string path,() };

priv.isEmptyFunc:{[func] 0x100001 ~ @[{first value x};func;{[func;err] -1 "Error, not a function: ",-3!func;`err}[func;]] };

priv.executeSpecial:{[func;suiteNameS;specialNameS]
  if[(func ~ (::)) or (func ~ ()) or priv.isEmptyFunc[func]; :1b]; // no need to "execute" (::) or () or {}
  -1 "Executing ",specialNameS," for ", suiteNameS;
  ex:@[{[f] f[];`ok};func;{x}];
  $[`ok ~ ex; 1b;
              [-1 suiteNameS," ",specialNameS," threw exception: ",ex; 0b]] };
  
priv.executeSuite:{[nocatch;basePath;be;ae;currPath]
  suitepathS:priv.pathString currPath;
  leaves:.[.tree.getLeaves;(priv.ALLTESTS;currPath);
              {[sp;err] if[err ~ "tree: invalid path"; -1 sp," is not a valid suite or test."; :`invpath]; 'err}[suitepathS;]];
  
  if[`invpath ~ leaves; :0b];  // bail out if we have hit an invalid path
  
  // execute beforeAll
  if[not priv.executeSpecial[leaves priv.BeforeAllTag;suitepathS;"BEFOREALL"];
    :enlist 0b];
  
  beforeEaches:be,leaves priv.BeforeEachTag;
  afterEaches:ae,leaves priv.AfterEachTag;
 
  bpl:count basePath;
  cpl:count currPath;
  mpl:min (bpl;cpl);
  if[not (mpl#basePath) ~ mpl#currPath; '"qtb: invalid test path"];  // sanity check: the current path is within the base path
  
  tests:key[leaves] except priv.Tags;
  nextNode:first mpl _ basePath;
 
  results:$[(bpl = cpl + 1) and nextNode in tests;  // basePath resolves to a single test (leaf)
                         priv.executeTest[nocatch;beforeEaches;afterEaches;suitepathS;`name`func!(nextNode;leaves nextNode)];
 
            bpl > cpl;   .z.s[nocatch;basePath;beforeEaches;afterEaches;(1 + mpl)#basePath]; // full basePath not reached yet, kepp following it
 
            // else execute the tests of this suite and recurse
                         [testResults:priv.executeTest[nocatch;beforeEaches;afterEaches;suitepathS;] each ([] name:tests; func:leaves tests);
                         testResults,raze .z.s[nocatch;basePath;beforeEaches;afterEaches;] each
                                               currPath ,/: .tree.getBranches[priv.ALLTESTS;currPath]]];
                       
  // execute afterAll
  priv.executeSpecial[leaves priv.AfterAllTag;suitepathS;"AFTERALL"];
 
  results };

priv.executeTest:{[nocatch;be;ae;suiteNameS;testDict]
  testnameS:suiteNameS,".",string testDict`name;
  func:testDict`func;
  
  if[1 <> countargs func;
    -1 testnameS," is not a valid test function";
    :0b];
    
  // execute beforeEaches
  if[not all priv.executeSpecial[;testnameS;"BEFOREEACH"] each be;
    :0b];
 
  // execute test
  tr:$[nocatch;{[f] (`success;f[])}[func];catchX[func;`]];
  
  // execute afterEaches
  priv.executeSpecial[;testnameS;"AFTEREACH"] each ae;
  
  $[ `exceptn ~ first tr; [-1 "Test ",testnameS," threw exception: ",last tr;  0b];
    (`success;0b) ~ tr;   [-1 "Test ",testnameS," failed";                     0b];
    (`success;1b) ~ tr;   [-1 "Test ",testnameS," succeeded";                  1b];
    `success ~ first tr;  [-1 "Test ",testnameS," returned an invalid result"; 0b];
                          '"qtb: unexpected test result"] };

priv.execute:{[catchX;basepath] 
  pn:$[any basepath ~/: (`;(::);());`$();basepath,()];
  if[11 <> type pn;'"qtb: invalid inclusion path"];
  res:priv.executeSuite[catchX;pn;();();`$()];
    
  -1 "Tests executed: ",string count res;
  -1 "Tests successful: ",string sum res;
  -1 "Tests failed: ",string sum not res;
  all res,0 < count res };

// Public Interface

suite:{[path]
  priv.nameOk path;
  priv.ALLTESTS:.tree.createBranch[priv.ALLTESTS;path];
  };

addTest:{[path;test]
  priv.nameOk path;
  priv.ALLTESTS:.tree.insertLeaf[priv.ALLTESTS;path;test];
  };

addBeforeAll:priv.addSpecial[priv.BeforeAllTag;;];
addBeforeEach:priv.addSpecial[priv.BeforeEachTag;;];
addAfterEach:priv.addSpecial[priv.AfterEachTag;;];
addAfterAll:priv.addSpecial[priv.AfterAllTag;;];

execute:priv.execute[1b;];
executeDebug:priv.execute[0b;];

// Helper functions for writing tests

// Might need a testpath argument as well
matchValue:{[msg;expValue;actValue]
  if[expValue ~ actValue; :1b];
  -1 msg," does not match. Expected: ",(-3! expValue),", actual: ",-3! actValue;
  0b };

// Wrapper function to catch exceptions
catchX:{[f;args]
  numargs:countargs f;
  cf:$[0 >= numargs;'"catchX: Unexpected number of arguments";
       1 =  numargs; {[f;arg]  (`success;f[arg])}[f;];
       1 <  numargs; {[f;args] (`success;f . args)}[f;]];
  @[cf; args; {(`exceptn;x)}] };

// Check if a function throws an expected exception
checkX:{[f;args;msg]
  res:catchX[f;args];
  $[`success ~ first res; [-1 "No exception was thrown"; 0b];
    (`exceptn;msg) ~ res; 1b;
    `exceptn ~ first res; [-1 "Expected exception \"",msg,"\", but got \"",last[res],"\""; 0b];
      '"qtb: catchX failed to return a valid result"] };

// A logging mechanism for function calls

emptyFuncallLog:{[] ([] functionName:enlist `; arguments:enlist (::)) };

resetFuncallLog:{[] priv.FUNCALL_LOG::emptyFuncallLog[]; };

resetFuncallLog[]; // ensure that the table exists

logFuncall:{[funcname;argList]
  `.qtb.priv.FUNCALL_LOG upsert (funcname;argList);
  };

getFuncallLog:{[] priv.FUNCALL_LOG };

// Wrap a function so that it will record its name and arguments via logFuncall[]
// when invoked.
//
// Implementation notes: Returning a projection has the disadvantage of consuming
// one argument out of the possible 8. In addition, it would require typing out
// all 9 variangs (0 to 8) arguments, because I could not find a way to convert
// the arguments in a function invocation (f[...]) into a list. So the most elegant
// way to solve the problem was to compose a string of the new function definition
// and create it via value. Embedded into the function is the serialized representation
// of the wrapped function, which gets de-serialized before being called. This takes
// care of more complex cases such as projections with tables as fixed arguments being
// passed in.
wrapLogCall:{[name;func]
  nameS:string name;
  numargs:countargs func;
  tail:"-9!0x",raze string -8! func; // create a string from the bytecode representation
  value $[numargs within 0 1;"{[a] .qtb.logFuncall[`",nameS,";a]; (",tail,")[a]}";
          numargs within 2 8;[arglist:";" sv string numargs#`a`b`c`d`e`f`g`h;
                              "{[",arglist,"]",
                              " argl:(",arglist,");",
                              " .qtb.logFuncall[`",nameS,";argl];",
                              " (",tail,") . argl}"];
                  '"Invalid or unsupported number of arguments"] };

countargs:{[fp]
  if[100 > type fp; :-1];  // not a function
  mfp:value fp;
  if[4 = type first mfp; :count mfp 1]; // a simple function
  basef:first mfp;
  if[not (type basef) within 100 104; '"Unsupported function type"];
  // compute the number of arguments of a projection:
  // (num args of base function) less number of arguments provided in the projection
  (count (value basef) 1) - sum not (::) ~/: 1 _ mfp };



