import nimLUA, unittest

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

function greating(name)
  return "Hello " .. name
end

function arrsize(arr)
  arr[1] = 5
  return #arr
end

""")
  teardown:
    L.close()

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
