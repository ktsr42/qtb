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

getLeafDefault:{[tree;path;dflt]
  bid:priv.findNodeId[tree;-1 _ path];
  if[null bid;'"tree: invalid path"];
  if[`branch <> tree[bid;`nodeType]; '"tree: invalid path"];
  nid:first exec id from tree where parentId=bid,nodeName = last path;
  if[null nid;:dflt];
  if[`leaf <> tree[nid;`nodeType]; '"tree: isbranch"];
  :tree[nid;`nodeValue];
  };

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
// Throw exception if path is not a branch or a leaf
getLeaves:{[tree;path]
  nid:priv.getNodeId[tree;path];
  if[`leaf ~ tree[nid;`nodeType]; :(`value;tree[nid;`nodeValue])];
  if[`branch ~ tree[nid;`nodeType];
    r:(enlist[`]!enlist (::)),(!). value exec nodeName,nodeValue from tree where parentId=nid;
    :(`nodes;r)];
  '"tree: invalid path";
  };

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
    if[null nodeId; :0Nj];         // find the id of the next child node, if it is 0Nj, we have an invalid path
    currNode:tree nodeId;         // step down to the subtree
    rPath:1 _ rPath];             // consume the path element
  if[0 <> count rPath; :0Nj];
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
  