---
name: new-desk
description: Create a new Urbit desk. Use when the user asks you to create a new app or desk on their Urbit ship, e.g. "create a new desk called my-app", "make a new Urbit app".
model: "inherit"
---

# Create a new app ("desk") on the Urbit ship

## Overview

Use this to create a new app on the ship. This will instantiate 1) a simple skeleton Gall agent that demonstrates basic functionality and 2) all required dependencies for that app.

### What is a Gall app?

It's important to understand what a Gall app is. It's primarily a state machine (`+on-init`, `+on-load`, `+on-save`) and several APIs: `+on-poke` and `+on-peek` for external requests, `+on-agent` for responses from external/internal Gall agents, and `+on-arvo` for responses from the ship's internal Urbit OS. Other `+on-*` arms are rarely used.

In most cases this Gall agent does not include a UI. It might serve an HTML file to a URL using Eyre's `%connect` task, bind static files to URLs with Eyre's `%set-response` task. Usually, the frontend for a given app (e.g. a React frontend) is imported as URL in the desk's `desk.bill` file. Rarely, the Gall agent might provide a server-rendered UI using Urbit's Sail and Mast frameworks.

So if the user asks for a "hello world" app, you should ask them what they want:
- A simple state machine and API with no frontend?
- An app with an HTML frontend?

Then build accordingly. Since the `new-desk` tool gives you a skeleton Gall agent, you'll have to base it from that. A future version of %mcp-server may offer several "starter apps" for you and the user to choose from.

See the resoures linked below if you need to find out more about a specific aspect of Gall app development.

## Prerequisites

You must know the desired desk name (e.g. `my-app`, not `%my-app`).

## Instructions

Once you've run this tool to create the app, you *should* take one of two courses of action:
- Run `mcp__*__install-app` to start this example app's agents
- Run `mcp__*__mount-desk` to expose this desk to the Unix filesytem, copy in files from source, then run `mcp__*__install-app` to start the agents you've copied in

## Resources

- [Urbit HTTP API](https://docs.urbit.org/build-on-urbit/tools/js-libs/http-api-guide.md)
- [App School I](https://docs.urbit.org/build-on-urbit/app-school.md)
  - [App School I - 1. Arvo](https://docs.urbit.org/build-on-urbit/app-school/1-arvo.md)
  - [App School I - 2. The Agent Core](https://docs.urbit.org/build-on-urbit/app-school/2-agent.md)
  - [App School I - 3. Imports and Aliases](https://docs.urbit.org/build-on-urbit/app-school/3-imports-and-aliases.md)
  - [App School I - 4. Lifecycle](https://docs.urbit.org/build-on-urbit/app-school/4-lifecycle.md)
  - [App School I - 5. Cards](https://docs.urbit.org/build-on-urbit/app-school/5-cards.md)
  - [App School I - 6. Pokes](https://docs.urbit.org/build-on-urbit/app-school/6-pokes)
  - [App School I - 7. Structure and Marks](https://docs.urbit.org/build-on-urbit/app-school/7-sur-and-marks.md)
  - [App School I - 8. Subscriptions](https://docs.urbit.org/build-on-urbit/app-school/8-subscriptions.md)
  - [App School I - 9. Vanes](https://docs.urbit.org/build-on-urbit/app-school/9-vanes.md)
  - [App School I - 10. Scries](https://docs.urbit.org/build-on-urbit/app-school/10-scry.md)
  - [App School I - 11. Failure](https://docs.urbit.org/build-on-urbit/app-school/11-fail.md)
- [App School II (Full-Stack)](https://docs.urbit.org/build-on-urbit/app-school-full-stack.md)
  - [App School II - 1. Types](https://docs.urbit.org/build-on-urbit/app-school-full-stack/1-types.md)
  - [App School II - 2. Agent](https://docs.urbit.org/build-on-urbit/app-school-full-stack/2-agent.md)
  - [App School II - 3. JSON](https://docs.urbit.org/build-on-urbit/app-school-full-stack/3-json.md)
  - [App School II - 4. Marks](https://docs.urbit.org/build-on-urbit/app-school-full-stack/4-marks.md)
  - [App School II - 5. Eyre](https://docs.urbit.org/build-on-urbit/app-school-full-stack/5-eyre.md)
  - [App School II - 6. React app setup](https://docs.urbit.org/build-on-urbit/app-school-full-stack/6-react-setup.md)
  - [App School II - 7. React app logic](https://docs.urbit.org/build-on-urbit/app-school-full-stack/7-app-logic.md)
  - [App School II - 8. Desk and glob](https://docs.urbit.org/build-on-urbit/app-school-full-stack/8-desk.md)

