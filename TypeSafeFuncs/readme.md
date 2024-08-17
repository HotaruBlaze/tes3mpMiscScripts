```
require("custom/TypeSafeFuncs")
```
Note: To correctly benefit from this script, you want it to be one of the first entrys in your customScripts.lua file.

This script helps you avoid server crashes by adding type checking to TES3MP’s C++ calls made from Lua. Without this, you might run into issues where incorrect argument types can crash your server, especially on Linux.