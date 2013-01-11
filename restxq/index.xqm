module namespace _ = "http://arolle.github.com/DesktopSearchApp";
import module namespace filterdir = "http://arolle.github.com/DesktopSearchIterative";
import module namespace fbase = "http://arolle.github.com/DesktopSearchBase";


(:~
 : List all available FSML DBs as
 : sequence of option-nodes
 :
 : @return option-elements containing FSML-DB names
 :)
declare
  %restxq:GET
  %restxq:path("listdb")
function _:listdbs() as element(option)*
{
(:  <select name="database" id="database">{:)
    for $x in db:list()
    let $y := lower-case(string($x))
    where not(empty(doc($x)/fsml))
    order by $y
    return
      <option value="{$x}">{
        $x || " (" || count(doc($x)//(dir|file)) || " Knoten)"
      }</option>  
(:  }</select>:)
};


(:~
 : 
 : 
 :)
declare
  %restxq:POST
  %restxq:path("list")
  %restxq:query-param("suchschlitz", "{$q}", "")
  %restxq:query-param("database", "{$fsmldb}", "")
function _:listfsml(
  $q as xs:string,
  $fsmldb as xs:string
) as element(li)* {
(:  try {
:)    let $dataroot :=
      try {
        doc($fsmldb)/fsml/@source/data()
      } catch * {error(xs:QName('FSML1'), 'database does not exist')}
    let $Matches := (
      for $x in 
        (: every file  (not in root-dir) contained in the returned sequence has to have having a parent dir :)
        if (substring($q, 1, 1) eq "/") (: first character a slash :)

        (: xpath/xquery expression inserted :)
        then (
          (: assurance: get the parent ´file´-node (if any) otherwise the next parent ´dir´-node
          prevents any nonsense output e.g. ´//attribute::suffix´ now returns all file nodes having a suffix attribute
          to have same behavior like in BaseX add ´/.´ after query string join
          e.g. the query ´/´ now returns tree, before an error was thrown
          but this slows down the query
           || '/.'
          :)
          for $x in xquery:eval("doc('" || $fsmldb || "')/fsml" || $q)
          return $x/(ancestor-or-self::file | ancestor-or-self::dir[1])
        )
        
        else if (ends-with($q, "/")) (: last character is a slash :)
        
        (: search for some dir-path expression
          a path like tmp/foo/bar/
          resolves to /dir[@name='tmp']/dir[@name='foo']/dir[@name='bar']
        :)
        then xquery:eval(trace("doc('" || $fsmldb || "')/fsml" || _:path-to-fsmlquery($q) || "//(file | dir)", "query: "))
        
        (: search for word in filename :)
        else doc($fsmldb)//(file | dir)[contains(lower-case(@name), lower-case($q))]

      let $id := $x/db:node-id(.)
      group by $id (: now: no more duplicates :)
      return fbase:elem($x[1])
    )
    return filterdir:generateOutput(
      filterdir:depthCorr(filterdir:lcaSet(filterdir:minimize($Matches), $fsmldb)),
      $fsmldb,
      $dataroot,
      replace(file:resolve-path(".") || file:dir-separator(), file:dir-separator()||"."||file:dir-separator(), file:dir-separator())
    )
(:   } catch err:FSML1 {
    <li class="error">{$fsmldb} ist keine <abbr title="File System Markup Language">FSML</abbr>-Datenbank</li>
  } catch * {
    (: should be triggered whilst entering no XPath
    shortest nonsense possible would be  `/:` :)
    <li class="error">fehlerhafter Ausdruck</li>
  }:)
};

(:~
 : transforms a sequence of directory parts
 : into a xpath expression for a fsml tree
 : e.g. ("tmp", "foo", "bar")
 : results in /dir[@name='tmp']/dir[@name='foo']/dir[@name='bar']
 : 
 :)
declare
%private
function _:path-to-fsmlquery(
  $str as xs:string
) as xs:string {
(: escape string, split into dir parts and remove unneccessary parts :)
  let $parts := tokenize(
  replace(
    replace($str, "\\", "\\\\")
    , "'", "\\'"
  ),"/"
)[string-length(.) > 0 or . = "."]
return if (empty($parts))
  then ""
  else replace(
    "/dir[@name='" ||
    string-join( $parts, "']/dir[@name='" ) ||
    "']"
  ,"dir\[@name='\.\.'\]", "parent::dir")
};
(:declare
%private
declare function _:path-to-fsmlquery($seq) {
  let $seq := $seq[string-length(.) > 0]
  return if (empty($seq))
  then ""
  else "/dir[@name='" || string-join($seq, "']/dir[@name='") || "']"
};:)