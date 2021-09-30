#
#* $Id: lua.h,v 1.283 2012/04/20 13:18:26 roberto Exp $
#* Lua - A Scripting Language
#* Lua.org, PUC-Rio, Brazil (http://www.lua.org)
#* See Copyright Notice at the end of this file
#
const
  LUA_VERSION_MAJOR* = "5"
  LUA_VERSION_MINOR* = "4"
  LUA_VERSION_NUM* = 543
  LUA_VERSION_RELEASE* = "3"
  LUA_VERSION* = "Lua " & LUA_VERSION_MAJOR & "." & LUA_VERSION_MINOR
  #LUA_RELEASE = LUA_VERSION & "." & LUA_VERSION_RELEASE
  #LUA_COPYRIGHT = LUA_RELEASE & " Copyright (C) 1994-2012 Lua.org, PUC-Rio"
  #LUA_AUTHORS = "R. Ierusalimschy, L. H. de Figueiredo, W. Celes"

#{.deadCodeElim: on.}
#when defined(useLuaJIT):
#  {.warning: "Lua JIT does not support Lua 5.3 at this time."}
const SHARED_LIB_NAME* {.strdefine.} = "none"

when SHARED_LIB_NAME != "none":
  const LIB_NAME* = SHARED_LIB_NAME
elif not defined(useLuaJIT):
  when defined(MACOSX):
    const
      LIB_NAME* = "liblua54.dylib"
  elif defined(FREEBSD):
    const
      LIB_NAME* = "liblua-5.4.so"
  elif defined(UNIX):
    const
      LIB_NAME* = "liblua54.so"
  else:
    const
      LIB_NAME* = "lua54.dll"
else:
  when defined(MACOSX):
    const
      LIB_NAME* = "libluajit.dylib"
  elif defined(FREEBSD):
    const
      LIB_NAME* = "libluajit-5.4.so"
  elif defined(UNIX):
    const
      LIB_NAME* = "libluajit.so"
  else:
    const
      LIB_NAME* = "luajit.dll"

const
  # mark for precompiled code ('<esc>Lua')
  LUA_SIGNATURE* = "\x1BLua"

  # option for multiple returns in 'lua_pcall' and 'lua_call'
  LUA_MULTRET* = (-1)

#
#* pseudo-indices
#
#@@ LUAI_MAXSTACK limits the size of the Lua stack.
#* CHANGE it if you need a different limit. This limit is arbitrary;
#* its only purpose is to stop Lua to consume unlimited stack
#* space (and to reserve some numbers for pseudo-indices).
#
when sizeof(int) >= 4: #LUAI_BITSINT >= 32:
  const
    LUAI_MAXSTACK* = 1000000
else:
  const
    LUAI_MAXSTACK* = 15000

# reserve some space for error handling
const
  LUAI_FIRSTPSEUDOIDX* = (-LUAI_MAXSTACK - 1000)
  LUA_REGISTRYINDEX* = LUAI_FIRSTPSEUDOIDX

proc upvalueindex*(i: int): int {.inline.} = LUA_REGISTRYINDEX - i

# thread status
type TThreadStatus* {.size:sizeof(int32).}= enum
  Thread_OK = 0, Thread_Yield, Thread_ErrRun, Thread_ErrSyntax,
  Thread_ErrMem, Thread_ErrGCMM, Thread_ErrErr

const
  LUA_OK* = 0
  LUA_YIELD* = 1
  LUA_ERRRUN* = 2
  LUA_ERRSYNTAX* = 3
  LUA_ERRMEM* = 4
  LUA_ERRGCMM* = 5
  LUA_ERRERR* = 6

type
  LuaState* = distinct pointer
  TCFunction* = proc (L: LuaState): int32{.cdecl.}

  #* functions that read/write blocks when loading/dumping Lua chunks
  TReader* = proc (L: LuaState; ud: pointer; sz: var csize_t): cstring {.cdecl.}
  TWriter* = proc (L: LuaState; p: pointer; sz: csize_t; ud: pointer): int32 {.cdecl.}

  #* prototype for memory-allocation functions
  TAlloc* = proc (ud, p: pointer; osize, nsize: csize_t): pointer

proc `==`*(a, b: LuaState): bool {.borrow.}

#* basic types
type
  LUA_TTYPE* = enum
    LUA_TNONE = -1
    LUA_TNIL = 0
    LUA_TBOOLEAN = 1
    LUA_TLIGHTUSERDATA = 2
    LUA_TNUMBER = 3
    LUA_TSTRING = 4
    LUA_TTABLE = 5
    LUA_TFUNCTION = 6
    LUA_TUSERDATA = 7
    LUA_TTHREAD = 8
    LUA_NUMTAGS = 9

type
  LUA_TYPE* = enum
    LNONE = -1, LNIL, LBOOLEAN, LLIGHTUSERDATA, LNUMBER,
    LSTRING, LTABLE, LFUNCTION, LUSERDATA, LTHREAD, LNUMTAGS

# minimum Lua stack available to a C function
const
  LUA_MINSTACK* = 20

# predefined values in the registry
const
  LUA_RIDX_MAINTHREAD* = 1
  LUA_RIDX_GLOBALS* = 2
  LUA_RIDX_LAST* = LUA_RIDX_GLOBALS

type
  lua_Number* = float64  # type of numbers in Lua
  lua_Integer* = int64    # ptrdiff_t \ type for integer functions

when defined(lua_static_lib):
  import os
  {.passC: "-DMAKE_LIB".}
  const LUA_DIR = currentSourcePath().splitPath.head & "/../external/lua/src"
  {.compile: LUA_DIR / "onelua.c".}


  {.pragma: ilua, cdecl, importc: "lua_$1".} # lua.h
  {.pragma: iluaLIB, cdecl, importc: "lua$1".} # lualib.h
  {.pragma: iluaL, cdecl, importc: "luaL_$1".} # lauxlib.h
else:
  {.push callconv: cdecl, dynlib: LIB_NAME .} # importc: "lua_$1"  was not allowed?
  {.pragma: ilua, importc: "lua_$1".} # lua.h
  {.pragma: iluaLIB, importc: "lua$1".} # lualib.h
  {.pragma: iluaL, importc: "luaL_$1".} # lauxlib.h

proc newstate*(f: TAlloc; ud: pointer): LuaState {.ilua.}
proc close*(L: LuaState) {.ilua.}
proc newthread*(L: LuaState): LuaState {.ilua.}
proc atpanic*(L: LuaState; panicf: TCFunction): TCFunction {.ilua.}
proc version*(L: LuaState): ptr lua_Number {.ilua.}

#
#* basic stack manipulation
#
proc absindex*(L: LuaState; idx: int32): int32 {.ilua.}
proc gettop*(L: LuaState): int32 {.ilua.}
proc settop*(L: LuaState; idx: int32) {.ilua.}
proc pushvalue*(L: LuaState; idx: int32) {.ilua.}
proc rotate*(L: LuaState; idx, n: int32) {.ilua.}

proc copy*(L: LuaState; fromidx: int32; toidx: int32) {.ilua.}
proc checkstack*(L: LuaState; sz: int32): int32 {.ilua.}
proc xmove*(src: LuaState; dst: LuaState; n: int32) {.ilua.}

proc pop*(L: LuaState; n: int32) {.inline.} = L.settop(-n - 1)
proc insert*(L: LuaState, idx: int32) {.inline.} = L.rotate(idx, 1)
proc remove*(L: LuaState, idx: int32) {.inline.} = L.rotate(idx, -1); L.pop(1)
proc replace*(L: LuaState, idx: int32) {.inline.} = L.copy(-1, idx); L.pop(1)

#
#* access functions (stack -> C)
#
proc isnumber*(L: LuaState; idx: int32): int32 {.ilua.}
proc isstring*(L: LuaState; idx: int32): int32 {.ilua.}
proc iscfunction*(L: LuaState; idx: int32): int32 {.ilua.}
proc isuserdata*(L: LuaState; idx: int32): int32 {.ilua.}
proc isinteger*(L: LuaState; idx: int32): int32 {.ilua.}
when defined(lua_static_lib):
  proc luatype*(L: LuaState; idx: int32): LUA_TTYPE {.cdecl, importc: "lua_type".}
else:
  proc luatype*(L: LuaState; idx: int32): LUA_TTYPE {.importc: "lua_type".}
proc typename*(L: LuaState; tp: LUA_TTYPE): cstring {.ilua.}
proc tonumberx*(L: LuaState; idx: int32; isnum: ptr int32): lua_Number {.ilua.}
proc tointegerx*(L: LuaState; idx: int32; isnum: ptr int32): lua_Integer {.ilua.}
proc toboolean*(L: LuaState; idx: int32): int32 {.ilua.}
proc tolstring*(L: LuaState; idx: int32; len: ptr csize_t): cstring {.ilua.}
proc rawlen*(L: LuaState; idx: int32): csize_t {.ilua.}
proc tocfunction*(L: LuaState; idx: int32): TCFunction {.ilua.}
proc touserdata*(L: LuaState; idx: int32): pointer {.ilua.}
proc tothread*(L: LuaState; idx: int32): LuaState {.ilua.}
proc topointer*(L: LuaState; idx: int32): pointer {.ilua.}

#
#* Comparison and arithmetic functions
#
const
  LUA_OPADD* = 0            # ORDER TM
  LUA_OPSUB* = 1
  LUA_OPMUL* = 2
  LUA_OPDIV* = 3
  LUA_OPMOD* = 4
  LUA_OPPOW* = 5
  LUA_OPUNM* = 6
proc arith*(L: LuaState; op: int32) {.ilua.}

const
  LUA_OPEQ* = 0
  LUA_OPLT* = 1
  LUA_OPLE* = 2
proc rawequal*(L: LuaState; idx1: int32; idx2: int32): int32 {.ilua.}
proc compare*(L: LuaState; idx1: int32; idx2: int32; op: int32): int32 {.ilua.}

#
#* push functions (C -> stack)
#
proc pushnil*(L: LuaState) {.ilua.}
proc pushnumber*(L: LuaState; n: lua_Number) {.ilua.}
proc pushinteger*(L: LuaState; n: lua_Integer) {.ilua.}
proc pushlstring*(L: LuaState; s: cstring; len: csize_t): cstring {.ilua.}
proc pushstring*(L: LuaState; s: cstring): cstring {.ilua.}
proc pushvfstring*(L: LuaState; fmt: cstring): cstring {.varargs,ilua.}
proc pushfstring*(L: LuaState; fmt: cstring): cstring {.varargs,ilua.}
proc pushcclosure*(L: LuaState; fn: TCFunction; n: int32) {.ilua.}
proc pushboolean*(L: LuaState; b: int32) {.ilua.}
proc pushlightuserdata*(L: LuaState; p: pointer) {.ilua.}
proc pushthread*(L: LuaState): int32 {.ilua.}

#
#* get functions (Lua -> stack)
#
proc getglobal*(L: LuaState; variable: cstring) {.ilua.}
proc gettable*(L: LuaState; idx: int32) {.ilua.}
proc getfield*(L: LuaState; idx: int32; k: cstring) {.ilua.}
proc rawget*(L: LuaState; idx: int32) {.ilua.}
proc rawgeti*(L: LuaState; idx: int32; n: int32) {.ilua.}
proc rawgetp*(L: LuaState; idx: int32; p: pointer) {.ilua.}
proc createtable*(L: LuaState; narr: int32; nrec: int32) {.ilua.}
proc newuserdatauv*(L: LuaState; sz: csize_t, nuvalue: int32): pointer {.ilua.}
proc newuserdata*(L: LuaState; sz: csize_t): pointer {.inline.} = newuserdatauv(L, sz, 1)
proc getmetatable*(L: LuaState; idx: int32): int32 {.ilua.}
proc getuservalue*(L: LuaState; idx: int32) {.ilua.}

#
#* set functions (stack -> Lua)
#
proc setglobal*(L: LuaState; variable: cstring) {.ilua.}
proc settable*(L: LuaState; idx: int32) {.ilua.}
proc setfield*(L: LuaState; idx: int32; k: cstring) {.ilua.}
proc rawset*(L: LuaState; idx: int32) {.ilua.}
proc rawseti*(L: LuaState; idx: int32; n: lua_Integer) {.ilua.}
proc rawsetp*(L: LuaState; idx: int32; p: pointer) {.ilua.}
proc setmetatable*(L: LuaState; objindex: int32): int32 {.ilua.}
proc setuservalue*(L: LuaState; idx: int32) {.ilua.}

#
#* 'load' and 'call' functions (load and run Lua code)
#
proc callk*(L: LuaState; nargs, nresults, ctx: int32; k: TCFunction) {.ilua.}
proc call*(L: LuaState; n, r: int32) {.inline.} = L.callk(n, r, 0, nil)

#proc getctx*(L: LuaState; ctx: ptr int32): int32 {.ilua.}
proc pcallk*(L: LuaState; nargs, nresults, errfunc, ctx: int32; k: TCFunction): int32 {.ilua.}
proc pcall*(L: LuaState; nargs, nresults, errFunc: int32): int32 {.inline.} =
  L.pcallK(nargs, nresults, errFunc, 0, nil)

proc load*(L: LuaState; reader: TReader; dt: pointer; chunkname, mode: cstring): int32 {.ilua.}
proc dump*(L: LuaState; writer: TWriter; data: pointer): int32 {.ilua.}

#
#* coroutine functions
#
proc yieldk*(L: LuaState; nresults: int32; ctx: int32; k: TCFunction): int32 {.ilua.}
proc luayield*(L: LuaState, n: int32): int32 {.inline.} = L.yieldk(n, 0, nil)
proc resume*(L: LuaState; fromL: LuaState; narg: int32): int32 {.ilua.}
proc status*(L: LuaState): int32 {.ilua.}

#
#* garbage-collection function and options
#
const
  LUA_GCSTOP* = 0
  LUA_GCRESTART* = 1
  LUA_GCCOLLECT* = 2
  LUA_GCCOUNT* = 3
  LUA_GCCOUNTB* = 4
  LUA_GCSTEP* = 5
  LUA_GCSETPAUSE* = 6
  LUA_GCSETSTEPMUL* = 7
  LUA_GCSETMAJORINC* = 8
  LUA_GCISRUNNING* = 9
  LUA_GCGEN* = 10
  LUA_GCINC* = 11
proc gc*(L: LuaState; what: int32; data: int32): int32 {.ilua.}

#
#* miscellaneous functions
#
proc error*(L: LuaState): int32 {.ilua.}
proc next*(L: LuaState; idx: int32): int32 {.ilua.}
proc concat*(L: LuaState; n: int32) {.ilua.}
proc len*(L: LuaState; idx: int32) {.ilua.}
proc getallocf*(L: LuaState; ud: var pointer): TAlloc {.ilua.}
proc setallocf*(L: LuaState; f: TAlloc; ud: pointer) {.ilua.}

#
#* ===============================================================
#* some useful macros
#* ===============================================================
#
proc tonumber*(L: LuaState; i: int32): lua_Number {.inline.} = L.tonumberx(i, nil)
proc tointeger*(L: LuaState; i: int32): lua_Integer {.inline.} = L.tointegerx(i, nil)
proc newtable*(L: LuaState) {.inline.} = L.createtable(0,0)
proc pushcfunction*(L: LuaState; fn: TCfunction) {.inline.} = L.pushCclosure(fn, 0)
proc register*(L: LuaState, n: string, f :TCFunction) {.inline.} =
  L.pushcfunction(f); L.setglobal(n)

proc isfunction* (L: LuaState; n: int32): bool {.inline.} =
  L.luatype(n) == LUA_TFUNCTION

proc istable* (L: LuaState; n: int32): bool {.inline.} =
  L.luatype(n) == LUA_TTABLE

proc islightuserdata*(L: LuaState; n: int32): bool {.inline.} =
  L.luatype(n) == LUA_TLIGHTUSERDATA

proc isnil*(L: LuaState; n: int32): bool {.inline.} =
  L.luatype(n) == LUA_TNIL

proc isboolean*(L: LuaState; n: int32): bool {.inline.} =
  L.luatype(n) == LUA_TBOOLEAN

proc isthread* (L: LuaState; n: int32): bool {.inline.} =
  L.luatype(n) == LUA_TTHREAD

proc isnone* (L: LuaState; n: int32): bool {.inline.} =
  L.luatype(n) == LUA_TNONE

proc isnoneornil*(L: LuaState; n: int32): bool {.inline.} =
  L.luatype(n) <= LUA_TNIL

proc pushliteral*(L: LuaState, s: string): cstring {.inline, discardable.} =
  L.pushlstring(s, s.len.csize_t)

proc pushglobaltable*(L: LuaState) {.inline.} =
  L.rawgeti(LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS)

proc tostring*(L: LuaState; index: int32): string =
  var len: csize_t = 0
  var s = L.tolstring(index, addr(len))
  result = newString(len)
  copyMem(result.cstring, s, len.int)

proc tobool*(L: LuaState; index: int32): bool =
  result = if L.toboolean(index) == 1: true else: false

proc gettype*(L: LuaState, index: int): LUA_TYPE =
  result = LUA_TYPE(L.luatype(index.int32))

#
#* {======================================================================
#* Debug API
#* =======================================================================
#
#
#* Event codes
#
const
  LUA_HOOKCALL* = 0
  LUA_HOOKRET* = 1
  LUA_HOOKLINE* = 2
  LUA_HOOKCOUNT* = 3
  LUA_HOOKTAILCALL* = 4
#
#* Event masks
#
const
  LUA_MASKCALL* = (1 shl LUA_HOOKCALL)
  LUA_MASKRET* = (1 shl LUA_HOOKRET)
  LUA_MASKLINE* = (1 shl LUA_HOOKLINE)
  LUA_MASKCOUNT* = (1 shl LUA_HOOKCOUNT)
# activation record


#@@ LUA_IDSIZE gives the maximum size for the description of the source
#@* of a function in debug information.
#* CHANGE it if you want a different size.
#
const
  LUA_IDSIZE* = 60

# Functions to be called by the debugger in specific events
type
  PDebug* = ptr lua.TDebug
  TDebug* {.pure, final.} = object
    event*: int32
    name*: cstring        # (n)
    namewhat*: cstring    # (n) 'global', 'local', 'field', 'method'
    what*: cstring        # (S) 'Lua', 'C', 'main', 'tail'
    source*: cstring      # (S)
    currentline*: int32    # (l)
    linedefined*: int32    # (S)
    lastlinedefined*: int32 # (S)
    nups*: cuchar         # (u) number of upvalues
    nparams*: cuchar      # (u) number of parameters
    isvararg*: char       # (u)
    istailcall*: char     # (t)
    short_src*: array[LUA_IDSIZE, char] # (S) \ # private part
    i_ci: pointer#ptr CallInfo   # active function


type
  lua_Hook* = proc (L: LuaState; ar: PDebug) {.cdecl.}
proc getstack*(L: LuaState; level: int32; ar: PDebug): int32 {.ilua.}
proc getinfo*(L: LuaState; what: cstring; ar: PDebug): int32 {.ilua.}
proc getlocal*(L: LuaState; ar: PDebug; n: int32): cstring {.ilua.}
proc setlocal*(L: LuaState; ar: PDebug; n: int32): cstring {.ilua.}
proc getupvalue*(L: LuaState; funcindex: int32; n: int32): cstring {.ilua.}
proc setupvalue*(L: LuaState; funcindex: int32; n: int32): cstring {.ilua.}
proc upvalueid*(L: LuaState; fidx: int32; n: int32): pointer {.ilua.}
proc upvaluejoin*(L: LuaState; fidx1: int32; n1: int32; fidx2: int32; n2: int32) {.ilua.}
proc sethook*(L: LuaState; fn: lua_Hook; mask: int32; count: int32): int32 {.ilua.}
proc gethook*(L: LuaState): lua_Hook {.ilua.}
proc gethookmask*(L: LuaState): int32 {.ilua.}
proc gethookcount*(L: LuaState): int32 {.ilua.}

# }======================================================================
#*****************************************************************************
# Copyright (C) 1994-2012 Lua.org, PUC-Rio.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#****************************************************************************




#
#* $Id: lualib.h,v 1.43 2011/12/08 12:11:37 roberto Exp $
#* Lua standard libraries
#* See Copyright Notice in lua.h
#

proc open_base*(L: LuaState): int32 {.iluaLIB.}
const
  LUA_COLIBNAME* = "coroutine"
proc open_coroutine*(L: LuaState): int32 {.iluaLIB.}
const
  LUA_TABLIBNAME* = "table"
proc open_table*(L: LuaState): int32 {.iluaLIB.}
const
  LUA_IOLIBNAME* = "io"
proc open_io*(L: LuaState): int32 {.iluaLIB.}
const
  LUA_OSLIBNAME* = "os"
proc open_os*(L: LuaState): int32 {.iluaLIB.}
const
  LUA_STRLIBNAME* = "string"
proc open_string*(L: LuaState): int32 {.iluaLIB.}
const
  LUA_UTF8LIBNAME* = "utf8"
proc open_utf8*(L: LuaState): int32 {.iluaLIB.}
const
  LUA_BITLIBNAME* = "bit32"
proc open_bit32*(L: LuaState): int32 {.iluaLIB.}
const
  LUA_MATHLIBNAME* = "math"
proc open_math*(L: LuaState): int32 {.iluaLIB.}
const
  LUA_DBLIBNAME* = "debug"
proc open_debug*(L: LuaState): int32 {.iluaLIB.}
const
  LUA_LOADLIBNAME* = "package"
proc open_package*(L: LuaState): int32 {.iluaLIB.}
# open all previous libraries
proc openlibs*(L: LuaState) {.iluaL.}

when not defined(lua_assert):
  template lua_assert*(x: typed) =
    (cast[nil](0))


#
#* $Id: lauxlib.h,v 1.120 2011/11/29 15:55:08 roberto Exp $
#* Auxiliary functions for building Lua libraries
#* See Copyright Notice in lua.h
#

# extra error code for `luaL_load'
const
  LUA_ERRFILE* = Thread_ErrErr.int32 + 1'i32 #(LUA_ERRERR + 1)

type
  luaL_Reg* {.pure, final.} = object
    name*: cstring
    fn*: TCFunction

const
  LUAL_NUMSIZES = (sizeof(lua_Integer)*16 + sizeof(lua_Number))

### IMPORT FROM "luaL_$1"
proc checkversion*(L: LuaState; ver: lua_Number; sz: csize_t) {.importc: "luaL_checkversion_".}
proc checkversion*(L: LuaState) {.inline.} = L.checkversion(LUA_VERSION_NUM, LUAL_NUMSIZES)

proc getmetafield*(L: LuaState; obj: int32; e: cstring): int32 {.iluaL.}
proc callmeta*(L: LuaState; obj: int32; e: cstring): int32 {.iluaL.}
#proc tolstring*(L: LuaState; idx: int32; len: ptr csize_t): cstring {.importc: "luaL_tolstring".}
# ^ duplicate?
proc argerror*(L: LuaState; numarg: int32; extramsg: cstring): int32 {.iluaL.}
proc checklstring*(L: LuaState; arg: int32; len: ptr csize_t): cstring {.iluaL.}
proc optlstring*(L: LuaState; arg: int32; def: cstring; len: ptr csize_t): cstring {.iluaL.}
proc checknumber*(L: LuaState; arg: int32): lua_Number {.iluaL.}
proc optnumber*(L: LuaState; arg: int32; def: lua_Number): lua_Number {.iluaL.}
proc checkinteger*(L: LuaState; arg: int32): lua_Integer {.iluaL.}
proc optinteger*(L: LuaState; arg: int32; def: lua_Integer): lua_Integer {.iluaL.}
proc checkstack*(L: LuaState; sz: int32; msg: cstring) {.iluaL.}
proc checktype*(L: LuaState; arg: int32; t: LUA_TTYPE) {.iluaL.}
proc checkany*(L: LuaState; arg: int32) {.iluaL.}
proc newmetatable*(L: LuaState; tname: cstring): int32 {.iluaL.}
proc setmetatable*(L: LuaState; tname: cstring) {.iluaL.}
proc testudata*(L: LuaState; ud: int32; tname: cstring): pointer {.iluaL.}
proc checkudata*(L: LuaState; ud: int32; tname: cstring): pointer {.iluaL.}
proc where*(L: LuaState; lvl: int32) {.iluaL.}
proc error*(L: LuaState; fmt: cstring): int32 {.varargs, iluaL.}
proc checkoption*(L: LuaState; arg: int32; def: cstring; lst: var cstring): int32 {.iluaL.}
proc fileresult*(L: LuaState; stat: int32; fname: cstring): int32 {.iluaL.}
proc execresult*(L: LuaState; stat: int32): int32 {.iluaL.}

# pre-defined references
const
  LUA_NOREF* = (- 2)
  LUA_REFNIL* = (- 1)
proc luaref*(L: LuaState; t: int32): int32 {.iluaL, importc:"luaL_ref".}
proc unref*(L: LuaState; t: int32; iref: int32) {.iluaL.}
proc loadfilex*(L: LuaState; filename: cstring; mode: cstring): int32 {.iluaL.}
proc loadfile*(L: LuaState; filename: cstring): int32 = L.loadfilex(filename, nil)

proc loadbufferx*(L: LuaState; buff: cstring; sz: csize_t; name, mode: cstring): int32 {.iluaL.}
proc loadstring*(L: LuaState; s: cstring): int32 {.iluaL.}
proc newstate*(): LuaState {.iluaL.}
proc llen*(L: LuaState; idx: int32): int32 {.iluaL, importc:"luaL_len".}
proc gsub*(L: LuaState; s: cstring; p: cstring; r: cstring): cstring {.iluaL.}
proc setfuncs*(L: LuaState; L2: ptr luaL_Reg; nup: int32) {.iluaL.}
proc getsubtable*(L: LuaState; idx: int32; fname: cstring): int32 {.iluaL.}
proc traceback*(L: LuaState; L1: LuaState; msg: cstring; level: int32) {.iluaL.}
proc requiref*(L: LuaState; modname: cstring; openf: TCFunction; glb: int32) {.iluaL.}
#
#* ===============================================================
#* some useful macros
#* ===============================================================
#

proc newlibtable*(L: LuaState, arr: openArray[luaL_Reg]){.inline.} =
  createtable(L, 0, (arr.len - 1).int32)

proc newlib*(L: LuaState, arr: var openArray[luaL_Reg]) {.inline.} =
  newlibtable(L, arr)
  setfuncs(L, cast[ptr luaL_reg](addr(arr)), 0)

proc argcheck*(L: LuaState, cond: bool, numarg: int, extramsg: string) {.inline.} =
  if not cond: discard L.argerror(numarg.int32, extramsg)

proc checkstring*(L: LuaState, n: int): cstring {.inline.} = L.checklstring(n.int32, nil)
proc optstring*(L: LuaState, n: int, d: string): cstring {.inline.} = L.optlstring(n.int32, d, nil)

proc checkint*(L: LuaState, n: lua_Integer): lua_Integer {.inline.} = L.checkinteger(n.int32)
proc optint*(L: LuaState, n, d: lua_Integer): lua_Integer {.inline.} = L.optinteger(n.int32, d)
proc checklong*(L: LuaState, n: int, d: clong): clong {.inline.} = cast[clong](L.checkinteger(n.int32))
proc optlong*(L: LuaState, n: int, d: lua_Integer): clong = cast[clong](L.optinteger(n.int32, d))

proc Ltypename*(L: LuaState, i: int32): cstring {.inline.} =
  L.typename(L.luatype(i))

proc dofile*(L: LuaState, file: string): int32 {.inline, discardable.} =
  result = L.loadfile(file)
  if result == LUA_OK:
    result = L.pcall(0, LUA_MULTRET, 0)

proc dostring*(L: LuaState, s: string): int32 {.inline, discardable.} =
  result = L.loadstring(s)
  if result == LUA_OK:
    result = L.pcall(0, LUA_MULTRET, 0)

proc getmetatable*(L: LuaState, s: string) {.inline.} =
  L.getfield(LUA_REGISTRYINDEX, s)

template opt*(L: LuaState, f: TCFunction, n, d: typed) =
  if L.isnoneornil(n): d else: L.f(n)

proc loadbuffer*(L: LuaState, buff: string, name: string): int32 =
  L.loadbufferx(buff, buff.len.csize_t, name, nil)

#
#@@ TBufferSIZE is the buffer size used by the lauxlib buffer system.
#* CHANGE it if it uses too much C-stack space.
#
const
  Lua_BufferSIZE* = 8192'i32 # BUFSIZ\
    ## COULD NOT FIND BUFSIZE ?? on my machine this is 8192
#
#* {======================================================
#* Generic Buffer manipulation
#* =======================================================
#
type
  PBuffer* = ptr TBuffer
  TBuffer* {.pure, final.} = object
    b*: cstring             # buffer address
    size*: csize_t           # buffer size
    n*: csize_t              # number of characters in buffer
    L*: LuaState
    initb*: array[Lua_BufferSIZE, char] # initial buffer

proc buffinit*(L: LuaState; B: PBuffer) {.iluaL.}
proc prepbuffsize*(B: PBuffer; sz: csize_t): cstring {.iluaL.}
proc addlstring*(B: PBuffer; s: cstring; len: csize_t) {.iluaL.}
proc addstring*(B: PBuffer; s: cstring) {.iluaL.}
proc addvalue*(B: PBuffer) {.iluaL.}
proc pushresult*(B: PBuffer) {.iluaL.}
proc pushresultsize*(B: PBuffer; sz: csize_t) {.iluaL.}
proc buffinitsize*(L: LuaState; B: PBuffer; sz: csize_t): cstring {.iluaL.}
proc addchar*(B: PBuffer, c: char) =
  if B.n < B.size: discard B.prepbuffsize(1)
  B.b[B.n] = c
  inc B.n

proc addsize*(B: PBuffer, s: int) {.inline.} = inc(B.n, s)
proc prepbuffer*(B: PBuffer): cstring {.inline.} = prepbuffsize(B, Lua_BufferSIZE.csize_t)

# }======================================================
#
#* {======================================================
#* File handles for IO library
#* =======================================================
#
#
#* A file handle is a userdata with metatable 'LUA_FILEHANDLE' and
#* initial structure 'luaL_Stream' (it may contain other fields
#* after that initial structure).
#
const
  LUA_FILEHANDLE* = "FILE*"
type
  luaL_Stream* {.pure, final.} = object
    f*: File            # stream (NULL for incompletely created streams)
    closef*: TCFunction  # to close stream (NULL for closed streams)

# }======================================================
# compatibility with old module system
when defined(LUA_COMPAT_MODULE):
  proc pushmodule*(L: LuaState; modname: cstring; sizehint: int32){.iluaL.}
  proc openlib*(L: LuaState; libname: cstring; ls: ptr luaL_Reg; nup: int32){.iluaL.}
  proc register*(L: LuaState, n: string, ls: var openArray[luaL_Reg]) {.inline.} =
    L.openlib(n, cast[ptr luaL_reg](addr(ls)), 0)

when isMainModule:
  #import lua52
  import strutils

  echo "Starting Lua"
  var L = newState()

  proc myPanic(L: LuaState): int32 {.cdecl.} =
    echo "panic"

  #discard L.atpanic(myPanic)

  var regs = [
    luaL_Reg(name: "abc", fn: myPanic),
    luaL_Reg(name: nil, fn: nil)
  ]

  L.newlib(regs)
  L.setglobal("mylib")
  echo L.dostring("mylib.abc()")

  #echo "Loading libraries"
  #L.openLibs
  #
  #when defined (Lua_REPL):
  #  import rdstdin
  #  echo "To leave the REPL, hit ^D, type !!!, or call quit()"
  #
  #  var line: string = ""
  #  while readlineFromStdin ("> ", line):
  #
  #    if line == "!!!": break
  #
  #    let result = L.loadString(line).TThreadStatus
  #    if result == Thread_OK:
  #      let result =  L.pcall(0, LUA_MULTRET, 0).TThreadStatus
  #      case result
  #      of Thread_OK:     discard
  #      else:             echo result
  #    else:
  #      echo result
  #
  #else:
  #  proc testFunc (L: LuaState): int32 {.cdecl.} =
  #    #foo
  #    echo "Hello thar"
  #
  #  echo "Setting testFunc"
  #  L.pushCfunction testFunc
  #  L.setGlobal "testFunc"
  #
  #  const LuaScript = "testFunc()"
  #  echo "Loading script: \"\"\"\L$1\L\"\"\"".format(LuaScript)
  #
  #  let result = L.loadString(LuaScript).TThreadStatus
  #  echo "return: ", result
  #
  #  if result == Thread_OK:
  #    echo "Running script"
  #    let result = L.pcall (0, LUA_MULTRET, 0)

  echo "Closing Lua state"
  #L.close


