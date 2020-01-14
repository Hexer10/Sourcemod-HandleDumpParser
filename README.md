# Sourcemod Handle Dump Parser.
Parses an handle dump file, and provide information such as the most used handle type and the total memory used by a single plugin.
Also keep track of the dumps in a local indexdb.

Fully built with dart.

Try it here: https://hexer10.github.io/Sourcemod-HandleDumpParser/

To generate a dump file simply type in the console `sm_dump_handles dump.log` and a file named `dump.log` will be created in `gamefolder/` then you copy the content of that file or upload it to the web site to see all the values with ease.

![](https://i.imgur.com/gQZZ9Sr.png)
