import nimLUA, unittest

proc print_pointer(p: pointer) =
  let pArr = cast[ptr UncheckedArray[int]](p)
  echo pArr[0]
  echo pArr[1]

suite "Test call Lua fucntion from Nim":
  var
    L: LuaState
    retCount: int32

  setup:
    L = newNimLua()
    discard L.dostring("""
function add(a, b)
  return a + b, -1
end

function hello()
  print("Hello world")
end

function greating(name)
  return "Hello " .. name
end

function arrsize(arr)
  arr[1] = 5
  return #arr
end

function pointer(p)
  print_pointer(p)
end

""")
  teardown:
    L.close()

  test "no param":
    L.callfunction("hello")
    retCount = L.gettop()
    assert retCount == 0

  test "input integer":
    L.callfunction("add", 3, 5)
    retCount = L.gettop()
    assert retCount == 2
    echo "result: ", L.tointeger(1)
    L.pop(retCount)

  test "input number":
    L.callfunction("add", 3.0, 4.5)
    retCount = L.gettop()
    assert retCount == 2
    assert L.tonumber(1) == 7.5
    assert L.tointeger(2) == -1
    L.pop(retCount)

  test "input string":
    L.callfunction("greating", "John")
    retCount = L.gettop()
    assert L.tostring(1) == "Hello John"
    L.pop(retCount)

  test "input array":
    let arr = [1,2,3,4,5,6]
    L.callfunction("arrsize", arr)
    retCount = L.gettop()
    assert retCount == 1
    assert L.tointeger(1) == arr.len
    L.pop(retCount)

  test "input pointer":
    var arr = [1,2,3,4,5,6]
    L.bindFunction(print_pointer)
    L.callfunction("pointer", addr arr)
    retCount = L.gettop()
    L.pop(retCount)