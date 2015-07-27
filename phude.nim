import httpclient
import htmlparser
import strutils
import xmltree
import q
import streams
import zipfiles
import math
import os
const
  SUBSCENE_BASE_URL = "http://subscene.com"
  SUBSCENE_QUERY_URL = "$#/subtitles/release?q=$#"

  LANGUAGES = ["English", "Vietnamese"]

randomize()
proc mktemp(len: int = 6): string =
  var charset {.global.} = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

  var filename = newString(len)
  while true:
    for i in 0..len-1:
      filename[i] = charset[random(charset.len-1)]
    result = getTempDir() & filename & ".zip"
    if not result.existsFile:
      break

proc search(name: string): string =

  let html = getContent(SUBSCENE_QUERY_URL % [SUBSCENE_BASE_URL, name])
  var error: seq[string] = @[]
  let tbody = parseHtml(newStringStream(html), "test.html", error).findAll("tbody")

  #let tbody = loadHtml("test.html").findAll("tbody")

  var d = q(tbody)
  var rows = d.select("tr td.a1 > a")

  if rows.len == 0:
    echo "No subtitle found"
    quit(0)

  var lang, title, url: string
  var bestDistance: int = 100

  for n in rows:
    var nodes = q(n).select("span")
    lang = nodes[0].innerText().strip
    title = nodes[1].innerText().strip

    if lang in LANGUAGES:
      var distance = editDistance(name, title)
      if distance == 0:
        return n.attr("href")
      elif bestDistance > distance:
        bestDistance = distance
        url = n.attr("href")

  return url

proc download(s: string, dir: string = getCurrentDir()) =
  let html = getContent(SUBSCENE_BASE_URL & s)
  let url = q(html).select("a#downloadButton")[0].attr("href")

  var tmp = mktemp()
  downloadFile(SUBSCENE_BASE_URL & url, tmp)
  var z: ZipArchive
  if z.open(tmp):
    for s in z.walkFiles:
      #if s.endsWith(".srt"):
      z.extractFile(s, "$#/$#" % [dir, s])
    z.close
  else:
    echo "Unable to open zip file"
  tmp.removeFile


when isMainModule:
  var name = paramStr(1)
  var url = search(name)
  if not url.isNil:
    download(url)
  else:
    echo "No subtitle found"
