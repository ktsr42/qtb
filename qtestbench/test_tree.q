/////////////////////////////////////
// Unit tests for tree.q

\l tree.q

\l ../tb/testbench.q

/////////////////////////////////////
// Tests

Tree1:([id:0 1 2 3 4 5 6j] 
  parentId:0 0 1 2 0 1 1j;
  nodeName:``test`test`tealeaf`rootleaf`sideleaf`sidebranch;
  nodeType:`branch`branch`branch`leaf`leaf`leaf`branch;
  nodeValue:((::);(::);(::);42;`rotten;`sixtimesseven;(::)));

Tree2:Tree1 upsert (7j;0j;`rootbranch;`branch;(::));
`Tree2 upsert (8j;7j;`oakleaf;`leaf;12);
`Tree2 upsert (9j;7j;`acornleaf;`leaf;13);
`Tree2 upsert (10j;7j;`appleleaf;`leaf;14);

findNodeId_validRootleaf:{[]  4j = .tree.priv.findNodeId[Tree1;`rootleaf] };
findNodeId_validRoot:{[] 0j = .tree.priv.findNodeId[Tree1;`] };
findNodeId_validTestBranch:{[] 1j = .tree.priv.findNodeId[Tree1;`test] };
findNodeId_validTestTestBranch:{[] 2j = .tree.priv.findNodeId[Tree1;`test`test] };
findNodeId_validTealeaf:{[] 3j = .tree.priv.findNodeId[Tree1;`test`test`tealeaf] };
findNodeId_validSideLeaf:{[] 5j = .tree.priv.findNodeId[Tree1;`test`sideleaf] };
findNodeId_validSideBranch:{[] 6j = .tree.priv.findNodeId[Tree1;`test`sidebranch] };
findNodeId_invalidPath1:{[] 0Nj = .tree.priv.findNodeId[Tree1;`test`test`XX] };
findNodeId_invalidPath2:{[] 0Nj = .tree.priv.findNodeId[Tree1;`test`XX] };
findNodeId_invalidPath3:{[] 0Nj = .tree.priv.findNodeId[Tree1;`XX] };


findNodeId_suite:`findNodeId_validRootleaf`findNodeId_validRoot`findNodeId_validTestBranch`findNodeId_validTestTestBranch,
                 `findNodeId_validTealeaf`findNodeId_validSideLeaf`findNodeId_validSideBranch`findNodeId_invalidPath1,
                 `findNodeId_invalidPath2`findNodeId_invalidPath3;

validTree_valid1:{[] .tree.validTree Tree1};

validTree_valid2:{[] .tree.validTree .tree.new[]};

validTree_invalidNodeType:{[]
  .test.checkException[.tree.validTree;Tree1 upsert (100j;0j;`invalidnode;`root;-42);"tree: invalid node type"] };

validTree_invalidBranch:{[]
  .test.checkException[.tree.validTree;Tree1 upsert (100j;0j;`invalidnode;`branch;-42);"tree: unexpected value for branch"] };

validTree_invalidParent:{[]
  .test.checkException[.tree.validTree;Tree1 upsert (100j;101j;`invalidnode;`leaf;-42);"tree: invalid parent node(s)"]};

validTree_duplicateNodeIds:{[]
  .test.checkException[.tree.validTree;
                       `id xkey ([] id:0 1 1j; parentId:0 1 1j; nodeType:3#`branch; nodeValue:((::);(::);(::)));
                       "tree: duplicate node ids"] };

validTree_leafParent:{[]
  .test.checkException[.tree.validTree; Tree1 upsert (100j;5j;`invalidnode;`leaf;-42); "tree: leaf as parent"] };

validTree_onlyOneRoot:{[]
  .test.checkException[.tree.validTree; Tree1 upsert (100j;100j;`secondroot;`branch; (::)); "tree: multiple roots"] };


validTree_suite:`validTree_valid1`validTree_valid2`validTree_invalidNodeType`validTree_invalidBranch,
  		`validTree_invalidParent`validTree_duplicateNodeIds`validTree_leafParent`validTree_onlyOneRoot;


insertLeaf_root:{[]
  nt:.tree.insertLeaf[Tree1;`it1;"lolo"];
  (nt ~ Tree1 upsert (7j;0j;`it1;`leaf;"lolo")) and .tree.validTree nt };

insertLeaf_subsub:{[]
  nt:.tree.insertLeaf[Tree1;`test`test`it2;"lolo"];
  (nt ~ Tree1 upsert (7j;2j;`it2;`leaf;"lolo")) and .tree.validTree nt };

insertLeaf_overwrite:{[]
  nt:.tree.insertLeaf[Tree1;`test`test`tealeaf;"lolo"];
  (nt ~ Tree1 upsert (3j;2j;`tealeaf;`leaf;"lolo")) and .tree.validTree nt };

insertLeaf_invalidPath:{[]
  .test.checkException[.tree.insertLeaf;(Tree1;`test`test`notthere`xx;42);"tree: invalid path"] };

insertLeaf_branchNode:{[]
  .test.checkException[.tree.insertLeaf;(Tree1;`test`test;42);"tree: isbranch"] };

insertLeaf_suite:`insertLeaf_root`insertLeaf_subsub`insertLeaf_overwrite`insertLeaf_invalidPath`insertLeaf_branchNode;

createBranch_root:{[]
  nt:.tree.createBranch[Tree1;`ast];
  (nt ~ Tree1 upsert (7j;0j;`ast;`branch;(::))) and .tree.validTree nt };

createBranch_deep:{[]
  nt:.tree.createBranch[Tree1;`test`test`newtest];
  (nt ~ Tree1 upsert (7j;2j;`newtest;`branch;(::))) and .tree.validTree nt };

createBranch_side:{[]
  nt:.tree.createBranch[Tree1;`test`sidebranch`subbranch];
  (nt ~ Tree1 upsert (7j;6j;`subbranch;`branch;(::))) and .tree.validTree nt };

createBranch_invalidPath:{[]
  .test.checkException[.tree.createBranch;(Tree1;`test`test`test`test`xxx);"tree: invalid path"] };

createBranch_existingLeaf:{[]
  .test.checkException[.tree.createBranch;(Tree1;`test`sideleaf);"tree: node exists"] };

createBranch_existingBranch:{[]
  .test.checkException[.tree.createBranch;(Tree1;`test`test);"tree: node exists"] };

createBranch_suite:`createBranch_root`createBranch_deep`createBranch_side`createBranch_invalidPath,
                   `createBranch_existingLeaf`createBranch_existingBranch;

removeNode_leaf:{[]
  nt:.tree.removeNode[Tree1;`test`test`tealeaf];
  (nt ~ delete from Tree1 where id = 3j) and .tree.validTree nt };

removeNode_branch:{[]
  nt:.tree.removeNode[Tree1;`test`sidebranch];
  (nt ~ delete from Tree1 where id = 6j) and .tree.validTree nt };

removeNode_invalidPath:{[]
  .test.checkException[.tree.removeNode;(Tree1;`test`test`xxx`yyy);"tree: invalid path"] };

removeNode_subtree:{[]
  .test.checkException[.tree.removeNode;(Tree1;`test`test);"tree: branch not empty"] };

removeNode_suite:`removeNode_leaf`removeNode_branch`removeNode_invalidPath`removeNode_subtree;

getLeaf_tealeaf:{[] 42 ~ .tree.getLeaf[Tree1;`test`test`tealeaf] };

getLeaf_invalidPath:{[]
  .test.checkException[.tree.getLeaf;(Tree1;`test`sidebranch`notthere`tealeaf);"tree: invalid path"] };

getLeaf_branch:{[]
  .test.checkException[.tree.getLeaf;(Tree1;`test`test);"tree: get branch"] };

getLeaf_suite:`getLeaf_tealeaf`getLeaf_invalidPath`getLeaf_branch;

getLeafDefault_tealeaf:{[] 42 ~ .tree.getLeafDefault[Tree1;`test`test`tealeaf;`]};
getLeafDefault_default:{[] ` ~ .tree.getLeafDefault[Tree1;`test`test`NOTTHERE;`]};
getLeafDefault_invalidPath:{[]
  .test.checkException[.tree.getLeafDefault;(Tree1;`test`sidebranch`notthere`tealeaf;`);"tree: invalid path"] };

getLeafDefault_branch:{[]
  .test.checkException[.tree.getLeafDefault;(Tree1;`test`test;`);"tree: isbranch"] };

getLeafDefault_suite:`getLeafDefault_tealeaf`getLeafDefault_default`getLeafDefault_invalidPath`getLeafDefault_branch;

foreach_Tree1Full:{[]
  ((`test`test`tealeaf;42);(`test`sideleaf;`sixtimesseven);(enlist `rootleaf;`rotten)) ~ .tree.foreach[Tree1;`;{[p;v] (p;v)}] };

foreach_Subtree1:{[]
  ((`test`test`tealeaf;42);(`test`sideleaf;`sixtimesseven)) ~ .tree.foreach[Tree1;`test;{[p;v] (p;v)}] };

foreach_Subtree2:{[]
  (enlist (`test`test`tealeaf;42)) ~ .tree.foreach[Tree1;`test`test;{[p;v] (p;v)}] };

foreach_Subtree3:{[]
  tree:.tree.insertLeaf[Tree1;`test`test`figleaf;`yeahyeah];
  ((`test`test`tealeaf;42);(`test`test`figleaf;`yeahyeah)) ~ .tree.foreach[tree;`test`test;{[p;v] (p;v)}] };

foreach_Leaf:{[]
  (enlist (`test`test`tealeaf;42)) ~ .tree.foreach[Tree1;`test`test`tealeaf;{[p;v] (p;v)}] };

foreach_emptyBranch:{[]
  () ~ .tree.foreach[Tree1;`test`sidebranch;{(x;y)}] };

foreach_suite:`foreach_Tree1Full`foreach_Subtree1`foreach_Subtree2`foreach_Subtree3`foreach_Leaf`foreach_emptyBranch;


foreachBranch_Tree1Full:{[]
  ((`$();enlist `rootleaf);(enlist `test;enlist `sideleaf);
   (`test`test;enlist `tealeaf);(`test`sidebranch;`$())) ~
  .tree.foreachBranch[Tree1;`;{[path;leaves;lookup] (path;leaves)}] };

foreachBranch_lookupFunc_helper:{[path;kys;lf]
  (path;kys;{[lf;k] @[lf;k;{(`err;x)}]}[lf;] each kys,`xxx)};

foreachBranch_lookupFunc:{[]
  (enlist (`test`test;`tealeaf`figleaf;(42;`yeahyeah;(`err;"tree: invalid leaf key")))) ~
    .tree.foreachBranch[Tree1 upsert (7j;2j;`figleaf;`leaf;`yeahyeah);
                  `test`test;
                  foreachBranch_lookupFunc_helper] }

foreachBranch_nobranch:{[] () ~ .tree.foreachBranch[Tree1;`rootleaf;{(x;y;z)}] };

foreachBranch_invalidPath:{[]
  .test.checkException[.tree.foreachBranch;(Tree1;`test`notthere;{(x;y;z)});"tree: invalid path"] };

foreachBranch_nodescent:{[]
  f:{[path;kys;lf] $[(enlist `test) ~ path;'.tree.NodescentXcptn;(path;kys)] };
  ((();enlist `rootleaf);(enlist `newbranch;`$())) ~ 
    .tree.foreachBranch[Tree1 upsert (7j;0j;`newbranch;`branch;(::));();f] };

foreachBranch_exception:{[]
  f:{[path;kys;lf] $[(`test`test) ~ path;'"barf";(path;kys)] };
  .test.checkException[.tree.foreachBranch;(Tree1;();f);"barf"] };
  

foreachBranch_suite:`foreachBranch_Tree1Full`foreachBranch_lookupFunc`foreachBranch_nobranch,
                    `foreachBranch_invalidPath`foreachBranch_nodescent`foreachBranch_exception;

getLeaves_three:{[] (``oakleaf`acornleaf`appleleaf!((::);12;13;14)) ~ .tree.getLeaves[Tree2;`rootbranch] };
getLeaves_deep:{[] (``tealeaf!((::);42)) ~ .tree.getLeaves[Tree2;`test`test] };
getLeaves_nobranch:{[] .test.checkException[.tree.getLeaves;(Tree2;`test`test`tealeaf);"tree: not a branch"] };
getLeaves_none:{[] (enlist[`]!enlist(::)) ~ .tree.getLeaves[Tree2;`test`sidebranch] };

getLeaves_suite:`getLeaves_three`getLeaves_deep`getLeaves_nobranch`getLeaves_none;


getBranches_two:{[] `test`sidebranch ~ .tree.getBranches[Tree2;`test] };
getBranches_none:{[] (`$()) ~ .tree.getBranches[Tree2;`test`test] };
getBranches_root:{[] `test`rootbranch ~ .tree.getBranches[Tree2;`] };
getBranches_nobranch:{[] .test.checkException[.tree.getBranches;(Tree2;`rootbranch`oakleaf);"tree: not a branch"] };

getBranches_suite:`getBranches_two`getBranches_none`getBranches_root`getBranches_nobranch;

ALLTESTS:findNodeId_suite,validTree_suite,insertLeaf_suite,createBranch_suite,removeNode_suite,
         getLeaf_suite,getLeafDefault_suite,foreach_suite,foreachBranch_suite,getLeaves_suite,getBranches_suite;

