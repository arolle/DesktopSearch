module namespace fdir = "http://arolle.github.com/DesktopSearchRecursive";
import module namespace functx = "http://www.functx.com";
import module namespace fbase = "http://arolle.github.com/DesktopSearchBase";


(: tree ORDERED by @path or @dewey!!!,
all nodes having exactly one direct child (which is a dir-node) are removable :)
declare function fdir:minimize(
  $M as element()*
) as element()* {
  for $x in 
    (
      (: generate duplicates (to be deleted) for nodes that are not necessary :)
      for $x in $M
    let $children := $M[@parent-id = $x/@node-id]
    where empty($children/self::file) and count($children) = 1
    return element {name($x)} {
        $x/@path, $x/@dewey, $x/@name,
        attribute {'depth'} {
          -2
        }, $x/@node-id, $x/@parent-id
      }
      ,$M (: assuming sort-algorithm is stable -> new nodes will be prefered :)
    )
  let $id := $x/@node-id
  group by $id
  order by $x[1]/@dewey (: ordering necessary for output :)
  return $x[1][@depth > -1] (: exclude if node was found before :)
};



(: creates a ordered set of necessary items for a minimal tree :)
declare function fdir:lcaSet(
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
declare function fdir:depthCorr($M as element()*) as element()* {
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
declare function fdir:generateOutput(
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
          <ul>{fdir:generateOutput($subNodes, $DB, $dataRoot, $serverRoot)}</ul>
        )
        else ()
      }</li>
    )
    default return ()
};
