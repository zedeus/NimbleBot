import os, options, asyncdispatch, net, times, strformat, sequtils, algorithm
import strutils except editdistance
import std/editdistance

import telebot

import data

const token = slurp("../token").strip()

var me: User

template sendText(text: string; replyId=0; parse="markdown") =
  var msg = newMessage(u.message.chat.id, text)
  asyncCheck b.send(msg)

proc start(b: Telebot, u: Command) {.async.} =
  sendText("This bot is inline-mode only. /help for instructions.")

proc help(b: Telebot, u: Command) {.async.} =
  sendText("Type @" & me.username.get & " to search for Nimble packages.")

proc inlineHandler(b: Telebot, u: InlineQuery) {.async.} =
  if u.query.len < 2: return

  await updateList()

  let matches = getMatches(u.query)
  var results: seq[InlineQueryResultArticle]

  for p in matches:
    if results.len == 15: break

    var res: InlineQueryResultArticle
    res.kind = "article"
    res.title = p.name
    res.id = $(results.len + 1)

    var content = &"<b>{p.name}</b>"

    if p.description.len > 0:
      res.description = some(p.description)
      content &= "\n\n" & p.description

    content &= "\n\n" & p.web

    var textContent = InputTextMessageContent(content)
    textContent.parseMode = some("html")
    res.inputMessageContent = some(textContent)

    results.add(res)

  asyncCheck b.answerInlineQuery(u.id, results, cacheTime=10)

proc startup(b: Telebot) =
  try:
    me = waitFor b.getMe()
    echo "ID: ", me.id
    echo "First Name: ", me.firstName
    echo "User Name: ", me.username.get()
  except OSError:
    let e = getCurrentException()
    echo e.name, " ", e.msg
    quit()

proc main =
  let bot = newTeleBot(token)
  startup(bot)

  bot.onInlineQuery(inlineHandler)
  bot.onCommand("start", start)
  bot.onCommand("help", help)

  waitFor updateList()

  while true:
    try:
      bot.poll(clean=true)
    except IOError, OSError, SslError:
      let e = getCurrentException()
      echo e.name, " ", e.msg

      if "Bad Gateway" in e.msg or "Time" in e.msg:
        sleep(2)
      discard

main()
