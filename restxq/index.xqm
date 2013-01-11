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
  %restxq:path("list")
  %restxq:query-param("suchschlitz", "{$q}", "")
  %restxq:query-param("database", "{$fsmldb}", "")
function _:listfsml(
  $q as xs:string,
  $fsmldb as xs:string
) as element(li)* {
  prof:time(
  try {
    let $dataroot :=
      try {
        doc($fsmldb)/fsml/@source/data()
      } catch * {error(xs:QName('FSML1'), 'database does not exist')}
    
    (: matches: each entry <file> or <dir> :)
    let $Matches := (
      for $x in (
        (: /XPath means $q is an XPath expression starting with a forward slash :)
        if (substring(trace($q, "$q = "), 1, 1) eq "/")
        then xquery:eval(trace("doc('" || $fsmldb || "')/fsml" || $q, "query: "))/(ancestor-or-self::file | ancestor-or-self::dir[1])
        
        (: directory-path/ means $x is a path expression ending with a forward slash
          for given directory path a fitting XQuery is generated
          e.g.  foo/bar/   resolves to   /dir[@name='foo']/dir[@name='bar']
        :)
        else if (ends-with($q, "/"))
        then xquery:eval(trace("doc('" || $fsmldb || "')/fsml/" || _:path-to-fsmlquery($q) || "//(file | dir)", "query: "))
        
        (: search for word in file or dirname :)
        else doc($fsmldb)//(file | dir)[contains(lower-case(@name), lower-case($q))]
      )
      let $id := $x/db:node-id(.)
      group by $id (: now: no more duplicates :)
      return fbase:elem($x[1])
    ) (: end let $Matches :)
    
    let $files := $Matches[name() = "file"]
    let $dirs := $Matches[name() = "dir"]
    let $dirs := $dirs union fbase:removeDup("parent-id", $files[@parent-id > 1 and not(@parent-id = $dirs/@node-id)]) ! fbase:elem(db:open-id($fsmldb, @parent-id)) (: add dirs for parentless files :)
    let $dirs := filterdir:lcaSet($dirs, $fsmldb)
    (:let $prof := 
        prof:dump(
          for $x in $files union $dirs
          order by $x/@path
          return $x, "ordered all elems "
        ):)
    return filterdir:generateOutput(
      filterdir:depthCorr(
        for $x in $files union $dirs
        order by $x/@dewey
        return $x
      ),
      $fsmldb,
      $dataroot,
      replace(file:resolve-path(".") || file:dir-separator(), file:dir-separator()||"."||file:dir-separator(), file:dir-separator())
    )
   } catch err:FSML1 {
    <li class="error">{$fsmldb} ist keine <abbr title="File System Markup Language">FSML</abbr>-Datenbank</li>
  } catch * {
    (: should be triggered whilst entering no XPath
    shortest nonsense possible would be  `/:` :)
    <li class="error">fehlerhafter Ausdruck</li>
  }
  )
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