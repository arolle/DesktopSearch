(:~
 : 
 : 
 : order functions are applied in:
 :  1. _:minimize
 :  2. _:lcaSet
 :  3. _:depthsCorr
 :  4. _:generateOutput
 :)
module namespace _ = "http://arolle.github.com/DesktopSearchIterative";
import module namespace functx = "http://www.functx.com";
import module namespace fbase = "http://arolle.github.com/DesktopSearchBase" at "/Users/mag/github/local/DesktopSearch/repo/com/github/arolle/DesktopSearchBase.xqm";


(:~
 : Minimizes a tree of file and dir elements
 : The minimized tree has the following 
 : property:
 : there is no node having
 : exactly one dir-child
 : 
 : The returned sequence is ordered by the
 : attributes @path or @dewey
 : 
 : @param $M sequence of file or dir elements
 : @return sequence of file or dir elements
 :)
declare function _:minimize(
  $M as element()*
) as element()* {
  for $x in
  (
    (: generate duplicates (to be deleted) for nodes that are not necessary :)
    for $x in $M
    let $children := $M[@parent-id = $x/@node-id]
    where empty($children/self::file) and count($children) = 1 (: exactly one dir-childnode :)
    return element {name($x)} {
      $x/@path, $x/@dewey, $x/@name,
      attribute {'depth'} {-2}, $x/@node-id, $x/@parent-id
    }
    ,$M (: assuming sort-algorithm is stable -> new nodes will be prefered :)
  )
  let $id := $x/@node-id
  group by $id
  order by $x[1]/@dewey (: ordering necessary for output :)
  return $x[1][@depth > -1] (: exclude if node was found before (since sort algo is stable the negative depth will be first in grouping) :)
};

(: recursive minimization :)
declare
function _:minimize2 (
  $M as element()*
) as element()* {
  $M[not(@parent-id = $M/@node-id)]
  
  
(:  if (empty($M))
  then ()
  else
    let $x := head($M),
        $tail := tail($M),
        $children := $M[@parent-id = $x/@node-id]
    return (
      (: include $x in resultset iff has not exactly one dir-child and does not occur later on :)
      if (count($children) = 1 or not($children/self::file) or empty($M[$x/@node-id = ./@node-id]))
      then $x
      else (),
      _:minimize2($tail)
    )
:)};




(:
 : Creates a ordered set of items necessary
 : for a minimal tree containing all given nodes
 : 
 : @param $M set of file and dir-elements
 : @param $DB name of the db where items in $M refer to
 : @return ordered set
 :)
declare function _:lcaSet(
  $M as element()*,
  $DB as xs:string
) as element()* {
  if (count($M) < 1)
  then $M
  else 
  (: duplicate filtering from $M and found parents :)
  for $x in ($M,
    (: performance: lca for distinct parents
      in total: $num * (-1 + $num)/2 loops
    :)
    let $nodesDP := 
    (
      for $x in $M[@parent-id > 1] (: not including direct root descendents :)
      let $parent-id := $x/@parent-id
      where not($parent-id = $M/@node-id) (: is direct parent in $M? -> no calculation for this node :)
      group by $parent-id
      return $x[1]
    )
    let $num := count($nodesDP)
    for $i in 1 to $num -1
    for $j in $i+1 to $num
    let $lca := fbase:lca(
      db:open-id($DB, $nodesDP[$i]/@node-id),
      db:open-id($DB, $nodesDP[$j]/@node-id)
    )
    return if(not(empty($lca[2])))
      then (fbase:elem($lca[2], $lca[1]))
      else ()
  )
  let $id := $x/@node-id
  group by $id
  order by $x[1]/@dewey (: ordering necessary for output :)
  return $x[1]
};



(: tree ORDERED by @path or @dewey!!!,
all nodes without parentnodes in tree are abbreviateable :)
declare function _:depthCorr($M as element()*) as element()* {
  for $x in (
    for $x in $M[@parent-id = $M[1]/@parent-id]
    return element {name($x)} {
        $x/@path, $x/@dewey, $x/@name,
      attribute {'depth'} {0}, $x/@node-id, $x/@parent-id,
      attribute {'old-depth'} {$x/@depth/data()}
    },
    for $i in 2 to count($M)
    where $M[$i]/@parent-id > 1 and empty($M[@node-id = $M[$i]/@parent-id])
    return 
      let $newdepth := 2 + $M[$i]/@depth + $M[-1+$i]/@depth - count(
        distinct-values((tokenize($M[-1+$i]/@dewey, '/'),
        tokenize(string($M[$i]/@dewey), '/'))))
      let $parent-id := $M[$i]/@parent-id
      for $x in $M[@parent-id = $parent-id]
      return element {name($x)} {
        $x/@path, $x/@dewey, $x/@name,
      attribute {'depth'} {$newdepth}, $x/@node-id, $parent-id,
      attribute {'old-depth'} {$x/@depth/data()}
      }
    ,$M (: assuming sort-algorithm is stable -> new nodes will be prefered :)
  )
  let $id := $x/@node-id
  group by $id
  order by $x[1]/@dewey (: ordering necessary for output :)
  return $x[1]
};




(: having given a set of items where each child has an ancestor (e.g. rootnode) :)
declare function _:generateOutput(
  $nodes as element()*,
  $DB as xs:string,
  $dataRoot as xs:string,
  $serverRoot as xs:string
) as node()* {
  let $depth := min($nodes/@depth)
  let $depthNodes := $nodes[@depth = $depth]
  let $childNodes := $nodes[@depth > $depth]
  for $x in $depthNodes
  let $type := name($x)
  order by $type, $x/@path (: folders on top, "dir < file" :)
  return
    switch (name($x))
    case "file" return fbase:fileOutput(db:open-id($DB, $x/@node-id), $dataRoot, $serverRoot)
    case "dir" return (
      let $node-name := 
        if ($x/@old-depth)
        then fbase:abbrevName($x/@path, xs:integer($x/@old-depth - $x/@depth))
        else $x/@name/data()
      let $subNodes := $childNodes[starts-with(@dewey, $x/@dewey)]
      return
      <li>{
        if ($subNodes or empty(db:open-id($DB, $x/@node-id)/(dir|file)))
        then (<a>{$node-name}</a>)
        else (<a data-node-id="{$x/@node-id}">{$node-name}</a>)
      }{
        if ($subNodes)
        then (
          <ul>{_:generateOutput($subNodes, $DB, $dataRoot, $serverRoot)}</ul>
        )
        else ()
      }</li>
    )
    default return ()
};


