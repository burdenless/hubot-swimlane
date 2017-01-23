# Description
#   Swimlane Record Management and Creation
#
# Dependencies:
#   hubot-conversation
#
# Configuration:
#
# Commands:
#   hubot swim record new - Starts dialog to create new record
#   hubot swim get apps - Lists all current applications and their ID's
#   hubot swim set <field> <value> - Sets <field> to <value>
#
# Notes:
#   Swimlane is an automation and incident management
#   platform. Use this script to aid in automation
#   efforts and resolve incidents like a boss.
#   - byt3smith
#
# Author:
#   Bob Argenbright - @byt3smith

Conversation = require 'hubot-conversation'

SWIM_USER = process.env.SWIM_USER
SWIM_PASS = process.env.SWIM_PASS
SWIM_SERVER = process.env.SWIM_SERVER
COOKIE = null
authHeader = null
options =
  rejectUnauthorized: false

# Check Authentication
# Purpose: Self-explanatory
# #####################
checkAuth = (msg, cb) ->
  if SWIM_USER?
    auth(msg, cb)
  else
    msg.send "Swimlane credentials not configured"

# Authentication Function
# Purpose: Verifies credentials and returns cookie
##########################
auth = (msg, cb) ->
  creds = "userName=#{encodeURIComponent SWIM_USER}&password=#{encodeURIComponent SWIM_PASS}"

  msg.http("https://#{SWIM_SERVER}/api/user/login", options)
  .headers('Content-Type': 'application/x-www-form-urlencoded')
  .post(creds) (err, res, body) ->
    if res.statusCode is 200
      rawCookie = res.headers['set-cookie'][0]
      COOKIE = rawCookie.split('; ')[0].split('=')[1]
      authHeader = {'Cookie': ".AspNet.ApplicationCookie=#{COOKIE}"}
      if COOKIE?
        cb()
      else
        msg.send "IDK what happened bro, something's broken :fire:"
    else
      msg.send "[:x:]: #{res.statusCode}. #{body} :facepalm:"

# Application Listing
######################
listApps = (msg, cb) ->
  msg.send "Retrieving current application list..."
  msg.http("https://#{SWIM_SERVER}/api/apps/light", options)
  .headers(authHeader)
  .get() (err, res, body) ->
    msg.send res.statusCode
    cb(JSON.parse body)

# User Listing
######################
listUsers = (msg, cb) ->
  msg.send "Retrieving current users list..."
  msg.http("https://#{SWIM_SERVER}/api/user", options)
  .headers(authHeader)
  .get() (err, res, body) ->
    msg.send res.statusCode
    cb(JSON.parse body)

# Bot Configuration
####################
module.exports = (robot) ->
  switchboard = new Conversation(robot)

  # Dialog to insert a new record
  robot.respond /swim new record/i, (msg) ->
    checkAuth msg, () ->
      listApps msg, (data) ->
        convo = switchboard.startDialog(msg)
        count = 1
        message = ''
        apps = []
        for item in data
          appName = item.name.toLowerCase()
          appId = item.id
          message += "#{count}) #{appName}\n"
          apps.push appId
          count += 1
        msg.reply 'Sure, which app would you like to create a record in?'
        msg.send "#{message}"
        convo.addChoice /([0-9]+)/i, (msg2) ->
          app = Number(msg2.match[1])
          msg2.send "You chose #{app}"
          if apps.length < app < 0
            msg2.send ":x: That is not a valid choice, you ninny!"
          else
            chosen = apps[app-1]
            msg2.reply("On it boss! :+1: Creating record in #{chosen}")

  # Retrieve list of apps and their ID's
  robot.respond /swim get apps/i, (msg) ->
    checkAuth msg, () ->
      listApps msg, (data) ->
        message = ''
        for item in data
          message += "#{item.name}: #{item.id}\n"
        msg.send "#{message}"

  # Retrieve list of users and their ID's
  robot.respond /swim get users/i, (msg) ->
    checkAuth msg, () ->
      listUsers msg, (data) ->
        message = ''
        msg.send "Total Users: #{data['total']}"
        for item in data['users']
          msg.send "Name: #{item.displayName}\nUsername: #{item.userName}\nID: #{item.id}\n"

  # Set field as value for record
  robot.respond /swim set (.*)\s(.*)/i, (msg) ->
    field = msg.match[1]
    status = msg.match[2]
    msg.send "Closing all records with field #{field} as #{status}"
