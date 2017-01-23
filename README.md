# hubot-swimlane

A hubot script to integrate security automation operations with Slack

See [`src/swimlane.coffee`](src/swimlane.coffee) for full documentation.

## Installation

In the hubot project repo, run:

`npm install hubot-swimlane --save`

Then add **hubot-swimlane** to your `external-scripts.json`:

```json
["hubot-swimlane"]
```

## Sample Interaction

```
user1>> hubot swim get apps
hubot>> Retrieving current application list...
hubot>> Some_Application: 5702a781327180e9c883452


```
