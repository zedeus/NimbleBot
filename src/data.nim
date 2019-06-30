import sequtils, algorithm, httpclient, asyncdispatch, times
import strutils except editdistance
import std/editdistance
import sam

type
  Package* = object
    name*: string
    tags*: seq[string]
    web*: string
    url*: string
    description*: string

const
  url = "https://github.com/nim-lang/packages/raw/master/packages.json"
  path = "/tmp/packages.json"

var
  lastFetched = now()
  interval = initDuration(hours=6)
  packageList*: seq[Package]

proc updateList*() {.async.} =
  if now() - lastFetched < interval and packageList.len > 0:
    return

  let client = newAsyncHttpClient()
  await client.downloadFile(url, path)
  client.close()

  packageList.loads(readFile(path))
  lastFetched = now()

proc searchTags(p: Package; search: string): bool =
  for t in p.tags:
    if search in t.toLower():
      return true

proc calcRank(p: Package; search: string): int =
  if search == p.name: result -= 20
  if search in p.name: result -= 10
  if search in p.description.toLower(): result -= 5
  if searchTags(p, search): result -= 10
  result += editDistance(search, p.name.toLower())

proc getMatches*(search: string): seq[Package] =
  packageList.sortedByIt(calcRank(it, search.toLower().strip()))
