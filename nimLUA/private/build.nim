import os, macros

{.used.}

{.passC: "-DLUA_COMPAT_ALL -DMAKE_LIB".}

when defined(windows):
  {.passC: "-DLUA_USE_WINDOWS".}
else:
  {.passC: "-DLUA_USE_C89".}
  when defined(macos):
    {.passC: "-DLUA_USE_MACOS".}
  else:
    {.passC: "-DLUA_USE_LINUX".}


const LUA_DIR = currentSourcePath().splitPath.head & "/../../external/lua/src"
{.compile: LUA_DIR / "onelua.c".}

macro buildLua(): untyped =
  result = newNimNode(nnkStmtList)
  for (kind, path) in LUA_DIR.walkDir():
    if kind == pcFile:
      let (_, name, ext) = splitFile(path)
      if name in ["lua", "luac", "onelua"]:
        continue
      if ext == ".c":
        result.add quote do:
          {.compile: `path`.}

#buildLua()


