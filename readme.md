# Anime Ninja Simulator

Anime Ninja Simulator is a multiplayer Naruto IP based MMORPG game. The game will be set in various villages, hidden villages, and countries from the Naturo universe. 

There will be about 10 areas on release based on a setting for each area. There will be a boss at the end of each area. There will be missions the player should complete that helps them to progress to the next area. Areas can be unlocked by completing all the quests in the current area OR by saving up enough currency to unlock the next area. 

Players will be able to use equipped ninja characters to engage in combat with an enemy NPC. Optionally, players can activate a button to directly damage a selected enemy NPC. Upon defeating an enemy, the player earns currency directly or by picking up dropped currency.

Ninjas are characters the player can equip to fight enemy NPCs with. These are based on Nartuo characters.

The objective of the game is to unlock and equip stronger ninjas by progressing to higher areas by earning currency.

[Google Docs](https://docs.google.com/document/d/1gvsl3oDkl1MrIaWaRKGyx2nzcB9sx54sERcVYANOglE)

#### References
- https://narutofanon.fandom.com/wiki/World_of_Naruto
- https://naruto.fandom.com/wiki/Geography
- https://naruto.fandom.com/wiki/Category:Characters


***

### Contributors

> [@AveryArk](https://github.com/averyark) Lead Programmer and maintainer for the github repository\
> [@AverageLuaU](https://github.com/averageluau) Backend and Frontend Programmer

***
### Dependencies

The project utilizes various helper modules to increase code development efficiency while attempting to minimize bug caused by faulty code.

> **Knit**\
> Knit orientates core game logic around services and controllers, allowing us to inherit cleaner organization across codebases and easier maintainability.\
> [Documentation](https://sleitnick.github.io/Knit/docs/intro)

> **Janitor**\
> Light-weight, flexible object for cleaning up connections, instances, or anything. This implementation covers all use cases, as it doesn't force you to rely on naive typechecking to guess how an instance should be cleaned up. Instead, the developer may specify any behavior for any object.\
> [Documentation](https://rostrap.github.io/Libraries/Events/Janitor/)

> **ProfileService**\
> ProfileService is a stand-alone ModuleScript that specialises in loading and auto-saving DataStore profiles. ProfileService does not give you any data getter or setter functions. It gives you the freedom to write your own data interface. Low resource footprint, no excessive type checking. It is great for 100+ player servers. ProfileService automatically spreads the DataStore API calls evenly within the auto-save loop timeframe.\
> [Documentation](https://madstudioroblox.github.io/ProfileService/)

> **Promise**\
> Promises model asynchronous operations in a way that makes them delightful to work with. The library includes many utility functions beyond the basic functionality. Promises support cancellation, which allows you to prematurely stop an async task.\
> [Documentation](https://eryn.io/roblox-lua-promise/api/Promise)

> **t**\
> t is a module which allows you to create type definitions to check values against. When building large systems, it can often be difficult to find type mismatch bugs. Typechecking helps you ensure that your functions are recieving the appropriate types for their arguments.\
> [Documentation](https://github.com/osyrisrblx/t)

> **BoatTween**\
> BoatTween offers 32 easing styles (compared to Roblox’s 11) and they all have the 3 easing directions as well, allowing you to find exactly the tween timing you desire. It covers serveral TweenService insufficiency and brings more API to the table. `The util module offers a fast tween method using BoatTween`
> ```lua
> utilities.tween.instance(instance, properties, duration, easingStyle,easingDirection)
>```
> [Documentation](https://github.com/boatbomber/BoatTween)

> **Cmdr**\
> Cmdr is a fully extensible and type safe command console for Roblox developers. It offers great for admin commands, but does much more. Intelligent autocompletion and instant validation. Run commands programmatically on behalf of the local user. Embedded commands: dynamically use the output of an inner command when running a command.\
> [Documentation](https://eryn.io/Cmdr/api/Cmdr.html)

> **TestEZ**\
> TestEZ is a BDD-style testing framework for Roblox Lua. It provides an API that can run all of your tests with a single method call as well as a more granular API that exposes each step of the pipeline.\
> [Documentation](https://roblox.github.io/testez/api-reference)

> **Matter**\
> Matter is a pure ECS library with fast archetypical entity storage, automatic system scheduling, and a slick API featuring topologically-aware state. Matter empowers users to build games that are extensible, performant, and easy to debug.\
> [Documentation](https://eryn.io/matter/docs/GettingStarted)

***

### Practices

- `OOP` is suggested over `POP`; procedural programming is inferior as it lacks readability and reusability, especially in this project setup.
- Commetning with the purpose of your code is suggested but don't comment excessively.
- Well maintained Desktop and Mobile support is expected. Most of our players will be PC and Phones players.
- Putting the International community into consideration is one of our goal, which is why text localization is crucial.
- Interact with UIs using `utilities.ui.observeFor(uiName)`
- Always prefer methods from the utilities library unless it is inferior in your use case