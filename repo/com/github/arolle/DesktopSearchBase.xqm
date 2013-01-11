(:
 : In this Module all functions are bundled, which the
 : modules
 :
 : http://arolle.github.com/DesktopSearchRecursive
 : and
 : http://arolle.github.com/DesktopSearchIterative
 : have in common.
 :
 :)
module namespace fbase = "http://arolle.github.com/DesktopSearchBase";
import module namespace functx = "http://www.functx.com";


(: echo path to given node, from root node :)
declare function fbase:pathFromRootNode($element as node()) as xs:string {
  $element/string-join(ancestor-or-self::*/@name, '/')
};


(: full path :)
declare function fbase:fullPath(
  $dataRoot as xs:string,
  $serverRoot as xs:string,
  $node as node()
  ) as xs:string
{
  let $fullPath := $dataRoot|| file:dir-separator() ||fbase:pathFromRootNode($node)
  return if (starts-with($fullPath, $serverRoot))
    then substring($fullPath, string-length($serverRoot) + 2)
    else "file://"||$fullPath
};
declare function fbase:fullPath2($dataRoot as xs:string, $serverRoot as xs:string, $node as node()) as xs:string {
  "/"||$dataRoot|| file:dir-separator() ||fbase:pathFromRootNode($node)
};


(: creates a fitting element :)
declare function fbase:elem($node as node()) as element() {
  fbase:elem($node, count($node/ancestor::dir))
};
declare function fbase:elem($node as node(), $depth as xs:integer) as element() {
  element {name($node)} {
    attribute {'path'} {fbase:pathFromRootNode($node)},
    attribute {'dewey'} {string-join(($node/ancestor-or-self::*/string(db:node-id(.)))[position()>1], '/')},
    $node/@name,
    attribute {'depth'} {$depth},
    attribute {'node-id'} {$node/db:node-id(.)},
    attribute {'parent-id'} {$node/(parent::dir | parent::fsml)/db:node-id(.)} (: performance: group by distinct parents later on, fsml-node has always id 1 :)
  }
};


(:~
 : get lowest common ancestor of given nodes and the depth of the ancestor
 : order of arguments is unimportant
 : 
 : @param $node1 node
 : @param $node2 node in same context as $node1
 : @return sequence containing (depth, lca)
 :)
declare function fbase:lca(
  $node1 as node(),
  $node2 as node()
) as item()* {
  (:let $trace := trace($node1/@name/data() ||"  "|| $node2/@name/data(),'lca'):)
  let $lca := $node1/ancestor-or-self::dir intersect $node2/ancestor-or-self::dir
  return (count($lca)-1, $lca[last()])
};

(: returns path from $ancestor to $descendent i.e. $ancestor / .... / $descendent
   (including $ancestor and $descendent if these are of type ´dir´)
 no nice output via
  return string-join($descendent/ancestor-or-self::dir/@name[count($ancestor/ancestor-or-self::dir) <= position()], ' / ')
:)
declare function fbase:abbrevNodeName($ancestor as node(), $descendent as node()) as item()+ {
  let $desc := $descendent/ancestor-or-self::dir/@name/data()
  let $start := count($ancestor/ancestor-or-self::dir)
  return ((for $i in $desc[position() = ($start to last()-1)]
    return ($i, <span>/</span>)), $desc[last()])
};

declare function fbase:abbrevName($path as xs:string, $int as xs:integer) as item()+ {
  let $parts := tokenize($path,'/')
  return ((for $i in $parts[position() = (last()-$int to last()-1)]
    return ($i, <span>/</span>)), $parts[last()])
};

declare function fbase:CSSabbrevName($path as xs:string, $int as xs:integer) as item()+ {
  let $parts := tokenize($path,'/')
  let $num := count($parts)-$int
  return (
    if ($num > 1)
    then <span class="prevPath">{string-join($parts[position() < $num], '/')}/</span>
    else (),
    (
      for $i in $parts[position() = ($num to last()-1)]
      return ($i, <span>/</span>)
    ),
    $parts[last()]
   )
};



(:
 : HTML-OUTPUT
 :)

declare function fbase:fileOutput($node as node(), $dataRoot as xs:string, $serverRoot as xs:string) as node()* {
  <li>
    <a href="{fbase:fullPath($dataRoot, $serverRoot, $node)}">{$node/@name/data()}</a>
    {()(:fbase:mediaHandling($node, $dataRoot, $serverRoot):)}
  </li>
};

(: generate metadata for given node :)
declare function fbase:nodeOutputDetails($details as node()) as node()* {
  <dl>{
    for $d in $details
    return (<dt>{string($d/@name)}</dt>,<dd>{string($d/@value)}</dd>)
  }</dl>
};


(: which media type to be handled how... :)
declare function fbase:mediaHandling($node as node(), $dataRoot as xs:string, $serverRoot as xs:string) as node()* {
  (: TODO show details if any :)
  switch (string($node/@suffix))
  case "txt" return (
    if (file:is-file(fbase:fullPath2($dataRoot, $serverRoot, $node)))
    then (<div><pre>{
      substring(
        file:read-text(fbase:fullPath2($dataRoot, $serverRoot, $node)
      ), 1, 200)
    }………</pre></div>)
    else   <div><strong>Could not find <em>{fbase:fullPath2($dataRoot, $serverRoot, $node)}</em></strong></div>
  ) (: end case "text" :)

  case "pdf" return <div>Hier könnte der Inhalt von dem PDF stehen</div>

  case "audio"
  case "ogg"
  case "mp3" return <div><audio controls="controls" preload="none"><source src="{fbase:fullPath($dataRoot, $serverRoot, $node)}"/> No audio support</audio></div>

  case "video"
  case "mp4" return <div><video controls="controls" preload="none"><source src="{fbase:fullPath($dataRoot, $serverRoot, $node)}"/> No video support</video></div>

(: TODO thumbnail :)
  case "image"
  case "jpg"
  case "png" return <div><figure><img src="{
(: img:scale(fbase:fullPath($dataRoot, $serverRoot, $node),200,200) :)
  fbase:fullPath($dataRoot, $serverRoot, $node)
    }" /><figcaption>{string($node/@name)}</figcaption></figure></div>
  default return ()
};