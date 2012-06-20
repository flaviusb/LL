Yet another Arc web thing.
--------------------------

This project is defunct.

This makes use of a number of hacks to the arc interpreter and core libraries (under the "hacks" and "lib" directories).
These are in the form of patches to arc, which must be applied as directed in main.hack, and straight replacements of arc core library files, which are in the lib directory.
LL requires arc 3.1 and git. Some functionality requires that some LL directories be part of a git repository (ie serving versioned preprocessed files).

For markdown processing, LL shells out to discount; any markdown processor which can be shelled out to as 'markdown' and accept input from stdin will work, however.

LL relies on a reverse proxy to serve static files, handle connections, deal with abusive ip's etc; nginx.conf is a configuration file for using nginx with LL.

###Lessons learned###

Arc was beautiful, but was too deeply broken - I kept running into sharp edges with the macro system, and there were some really niggling bugs with the implementation. Then, running the actual game took all the time I had set aside for putting together infrastructure for the game. For the next larp, putting together a MVP character sheet viewer, xp tracker and expenditure tool will have to be complete before the first real planning sessions.

