import httpclient
import htmlparser

import strutils
import xmltree
import q
const
  SUBSCENE_LANG_FILTER = "http://u.subscene.com/filter"
  SUBSCENE_QUERY_URL = "http://subscene.com/subtitles/release?q=$#"

  LANGUAGES = ["Vietnamese"]


proc searchSub(name: string) =
  let url = SUBSCENE_QUERY_URL % [name]
  echo url
  let html = getContent(url)
  var d = q(html)
  #var d = q(path="test.html")

  var rows = d.select("table tbody tr td.a1 > a")

  if rows.len == 0:
    echo "Content not found"
    quit(1)

  echo "Found $# subtitles" % [$rows.len]
  for n in rows:
    var nodes = q(n).select("span")
    var lang = nodes[0].innerText().strip
    var title = nodes[1].innerText().strip
    if lang in LANGUAGES:
      echo lang, "\t", title
    #break



when isMainModule:
  var name = "Ex.Machina.2015.720p.BluRay.x264-SPARKS"
  searchSub(name)
