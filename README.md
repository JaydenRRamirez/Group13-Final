# Devlog Entry - 11/14/2025

## Introducing the team
Either organizing by person or by role, tell us who will do what on your team. Your team should span at least the following four roles:


Tools Lead: This person will research alternative tools, identify good ones, and help every other team member set them up on their own machine in the best configuration for your project. This person might also establish your team’s coding style guidelines and help peers setup auto-formatting systems. This person should provide support for systems like source control and automated deployment (if appropriate to your team’s approach).
Zander


Engine Lead: This person will research alternative engines, get buy-in from teammates on the choice, and teach peers how to use it if it is new to them. This might involve making small code examples outside of the main game project to teach others. The Engine Lead should also establish standards for which kinds of code should be organized into which folders of the project. They should try to propose software designs that insulate the rest of the team from many details of the underlying engine.
Andrew


Design Lead: This person will be responsible for setting the creative direction of the project, and establishing the look and feel of the game. They might make small art or code samples for others to help them contribute and maintain game content. Where the project might involve a domain-specific language, the Design Lead (who is still an engineer in this class) will lead the discussion as to what primitive elements the language needs to provide.
Cici / Three


Testing Lead:  This person will be responsible for both any automated testing that happens within the codebase as well as organizing and reporting on human playtests beyond the team.
Jayden / Iain




If your team has fewer than four people, some people will need to be the lead for multiple disciplines, but no person should be the lead for more than two disciplines.
If your team has more than four people, you are welcome to sub-divide the roles above into more specific roles or tag people as Assistant or Backup for one of the existing roles. Alternatively, you could invent new lead roles if your team is going to try a special game design technique (e.g. assign a Procgen Lead if your team is planning to use procedural generation).
Overall, the four main disciplines all need to be associated with the name of specific people on your team.
## Tools and materials
With about one paragraph each (ideally including clickable hyperlinks
Engine: Tell us about what engines, libraries, frameworks, and or platforms you intend to use, and give us a tiny bit of detail about why your team chose those. You are not committing to use this engine to finish the project, just sharing your initial thinking on engine choice. IMPORTANT: In order to satisfy the F1 Requirements, you'll need to choose something that doesn't already support high-level 3D rendering and physics (it must be something that requires you to bring those features in for yourself). If you don't know what to use, "the baseline Links to an external site. web browser platform" is a good default choice.


For the engine discussed and selected amongst the team, we have the idea of utilizing LÖVE as our choice. Not only does it provide an accessible basis for making 2D games, but as it doesn’t already support high-level 3D rendering and physics, that means it will make a perfect opportunity to learn and adapt 3D support by our own hands in conjunction with the potential game we can make. On top of that, there is plenty of library resources for LOVE that will assist in the process.


Language: Tell us programming languages (e.g. TypeScript) and data languages (e.g. JSON) you team expects to use and why you chose them. Presumably you’ll just be using the languages expected by your previously chosen engine/platform.
As we were learning more research on LOVE, we had discovered that it is one that mainly utilizes Lua Scripting. As this will be many of us’s first times implementing and discovering such a language, it will prove both an effective learning opportunity and a unique hurdle to overcome during our process.






Tools: Tell us about which tools you expect to use in the process of authoring your project. You might name the IDE for writing code, the image editor for creating visual assets, or the 3D editor you will use for building your scene. Again, briefly tell us why you made these choices. Maybe one of your teammates feels especially skilled in that tool or it represents something you all want to learn about.


Much of the team had a preference for a local work environment, and as such, we will be working with Visual Studio Code. Our team will be using Github for collaboration. For custom asset creation, we will use Clip Studio Paint for 2D assets and Blender for 3D assets.




Generative AI: Tell us about your team's plan for using (or not using) tools based on generative AI, whether they are agentic or not. For example, will you be requiring team members to use or not use specific features of specific tools? Perhaps you plan use the autocomplete features in Github Copilot but not the agent mode. Maybe you will only use the agent mode under specific instructions for it to not make any direct modifications to your code, only giving the developer advice on how to proceed.


Our team will only be using generative AI in moderation, such as for helping to catch bugs


## Outlook
Give us a short section on your outlook on the project. You might cover one or more of these topics:
What is your team hoping to accomplish that other teams might not attempt?
What do you anticipate being the hardest or riskiest part of the project?
What are you hoping to learn by approaching the project with the tools and materials you selected above?

The hardest part of this project will definitely come in the form of each of us getting acquainted and learning the ins and outs of  LOVE. As stated above, it’ll not only be the first time for all of us to tackle this engine, but we also need to learn Lua and that particular scripting language in order to build our game. Even though outside opinion describes Lua as an easy to learn language, each of us may have a different experience or ease in trying to learn. Although, it is this opportunity to quickly learn and adapt to a new engine that is the most exciting prospect of the final project, especially in seeing what we will be able to accomplish in bringing our game to life.

# Devlog Entry - 11/21/2025
## How we satisfied the software requirements
1. It is built using a platform (i.e. engine, framework, language) that does not already provide support for 3D rendering and physics simulation
2. It uses a third-party 3D rendering library.
As we talked about in the planning stages, the team ultimately went on utilizing Love2d as the basis of the game engine, given the ease of understanding when it comes to Lua, as well as the documentation and additions that can be found for the engine. When it comes to the 3D rendering library, our initial attempt was to implement 3DreamEngine, but finding it more complex than necessary for the project, we switched to g3d.

3. It uses a third-party physics simulation library.
4. The playable prototype presents the player with a simple physics-based puzzle.
5. The player is able to exert some control over the simulation in a way that allows them to succeed or fail at the puzzle.
This portion for the requirements took most of the learning process, implementation, and overall dev time in terms for the engine, however, we were able to find ground within utilizing rigidBody for physics, while g3d handles the collisions. With every aspect in mind, we were able to craft a physics-based puzzle that gives off a good prototype presentation in what we are trying to achieve for our final game, and definitely something that will continue to see fine tuning and development. For the puzzle itself, it takes the form of a Plinko board, in which the player will drop the ball from the top, bounce off pegs that make up the middle of the board, and try to land it in a specific slot that will win them the game.

6. The game detects success or failure and reports this back to the player using the game’s graphics
The testing phase for this portion mainly boiled down to test cases of what was breaking when running the project, looking through any mismatched names or misinputted values and variables, etc. Alongside tools and tests that helped in the lua experience, we had a Lua Autoformatter that assisted in catching errors early and formatting the project.

7. The codebase for the prototype must include some before-commit automation that helps developers.
8. The codebase for the prototype must include some post-push automation that helps developers.
In terms of testing and automation, the main implementation has been in bootstrap. Bootstrap features: professional IDE integration, automated builds, and everything you need to go from prototype to published game. Alongside that, it allows automation to a wide range of paths, from Itch.io, to Android, to Windows and MacOS, etc.
	
## Reflection
F1 was a lengthy process in terms of fulfilling the requirements, as love2d required much in terms of finding not only extensions that housed the opportunity to work with 3D-oriented libraries, but also having to learn how such libraries work in order to implement the necessary assets, physics, and logic to build the puzzle. Much of the focus here was on engine work, and while we did maintain mostly our original ideas of g3d, we did have a bit of a moment in working in 3DreamEngine, but in the end, we just utilized its physics property for the project, rather than the whole engine. While we also discussed what automation and test libraries and scripts at the beginning (such as we ensured we had love2d extensions that would give us a running build at the press of a few keys), as said before, we focused on the engine at hand, and once it was at a state that left us satisfied, did we then implement such automation like Bootstrap or something to keep the code tidy like the lua Autoformatter.

# Devlog Entry - 12/01/2025

## How we satisfied the software requirements
Continuing on from the first iteration of the game so far, the 3D rendering and physics simulation remains as we collectively got to work on implementing new features and interactions. Starting from the top, the introduction of a new scene that will transition to the previous game level we’ve showcased so far. Next up was the focus on the object interaction, from introducing a new Inventory UI and subsequent Object class to store these items, but also being able to drag the items onto the game board. Finally, we’ve still kept on ensuring the elements of the game board itself still carry the physics based puzzle logic and a win/lose state.

## Reflection
This part of the process has been enlightening in both furthering the understanding of the g3d and love2d engines, but also in how we are able to weave overall game and level ideas through the tools we’ve been using so far. Amongst the process, there have been some shifts on the game design based on what we’ve learned about the engine so far and its capabilities. Originally there was a proposition of gears and rotatable objects to help or hinder the trajectory of the ball in the puzzle for this phase, but seeing the complexity of attempting logic within the physics, we instead focused on the ideas of pistons and conveyors as interactables instead.

# Devlog Entry - 12/05/2025

## Selected Requirements:

[External DSL] - With most of the team having used JSONs in past projects and classes, it was a skill we already had. We were able to use it to clean up the creation of scenes and objects within them, as well as for the localization requirement.

[i18n + I10n] - As mentioned in the DSL requirement, it was simple to implement localization using the JSON system established prior.

[Touchscreen Implementation] Our game already used mouse controls for most features, which were easy to adapt into touch controls. The keybind-only features were easy to adapt to on screen buttons, as they were either single button presses or toggles.

[Unlimited Undos] With the current structure of the inventory system, we are able to do unlimited undos simply by the functionality of returning items into the inventory, which had already been implemented. Navigation also came with undos built in, as every action for moving between rooms came with a button to move back.

## How we satisfied the software requirements.
The external DSL requirement was fulfilled using JSONs to build the room search scenes and everything within them. Objects and their locations are stored within one, as well as constants that are used for readability within the JSON itself and for ease of creating new scenes. This JSON is then parsed within our code into a Lua table that acts as our scene system. We also have another JSON that is used for localization, which stores all in-game text for all three supported languages. This also helped with the i18n + l10n (language) requirement. To add the ability for the user to choose a language in game, we added buttons to the main menu that can change the language for all in game text. Unlimited Undos were already implemented due to the existing inventory system being able to pick up placed items, as well as room traversal always having a corresponding button to traverse back. We fulfilled the touchscreen requirement by converting all mouse controls to touch controls (which was simple), adding an on screen button to open and close the inventory, and adding the switch language buttons.

## Reflection
Much like F2 and F1, there were many aspects of this segment that were a challenge to figure out, and others that were a breeze thanks to tapping into past knowledge. One big change of plan we had was when our team saw what features were already implemented, and realized our original plan was out of scope. Because of this, we descoped our tools with unique functionality to simple primitive obstacles that can be placed on the plinko levels. This kept the general concept of the puzzle-based plinko gameplay we originally planned, while allowing us to actually finish the game in time. It also allowed us to have the time to add another whole plinko level, and the one the user encounters is randomly chosen for each playthrough, adding replay value to the game.


## Useful Project Documents:

[Program Planning Doc](https://docs.google.com/document/d/1-9CKcUC9vJIP7k_AkpOvDtzBbWBxJ021xz6i5XMZBcM/edit?usp=sharing)

## Important Notes for Running Program:

In order to launch the program, you must type > launch love while on VS code, or via downloading and running the build on the github page.