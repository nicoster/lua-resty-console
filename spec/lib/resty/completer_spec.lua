local new_binding = require('resty.console.binding').new
local new_completer = require('resty.console.completer').new
local binding, completer, result, word
local commands = {}

local test_completer = function()
  local info = debug.getinfo(2)
  binding = new_binding(info)
  completer = new_completer(binding, commands)
  result = completer:find_matches(word)
end

local upvalue_with_mt = setmetatable({ foo = 'bar' }, {
  __index = { bar = 'foo' }
})

local example_function = function(local_arg)
  assert(local_arg)
  assert(new_binding)
  assert(new_completer)
  assert(upvalue_with_mt)

  local local_false = false

  assert(local_false == false)

  local myngx = {
    req = { get_body_data = function() end, get_body_file = function() end },
    ERR = 1,
    ERROR = 2,
  }

  function myngx:print() assert(self) end
  local _mt = {}
  function _mt:xprint() assert(self) end

  setmetatable(myngx, { __index = _mt })

  test_completer()

  return myngx
end

local complete = function(t_word)
  word = t_word
  example_function(123)
  return result
end

describe('repl completer', function()
  it('should complete local vars', function()
    assert.are_same({ 'myngx' }, complete 'myn')
    local res = complete 'myngx.'
    table.sort(res)
    assert.are_same(
      {
        'myngx.ERR',
        'myngx.ERROR',
        'myngx.print()',
        'myngx.req.',
        'myngx.xprint()'
      },
      res
    )
    assert.are_same({ 'myngx.req.' }, complete 'myngx.re')
    assert.are_same(
      { 'myngx.req.get_body_data()', 'myngx.req.get_body_file()' },
      complete 'myngx.req.get_'
    )
    assert.are_same({ 'myngx.req.get_body_data()' },
      complete 'myngx.req.get_body_d')
  end)

  it('should complete local args', function()
    assert.are_same({ 'local_arg', 'local_false' }, complete 'loc')
  end)

  it('should complete upvalues', function()
    assert.are_same({ 'new_binding', 'new_completer' }, complete 'new_')
    assert.are_same({ 'new_binding(' }, complete 'new_b')
  end)

  it('should complete globals', function()
    assert.are_same({ 'debug.getlocal()' }, complete 'debug.getl')
  end)

  -- TODO: more specs

  context('object with metatable', function()
    it('should complete own keys', function()
      assert.are_same({ 'upvalue_with_mt.foo' }, complete 'upvalue_with_mt.f')
    end)

    it('should complete meta keys', function()
      assert.are_same({ 'upvalue_with_mt.bar' }, complete 'upvalue_with_mt.b')
    end)
  end)

  context('similar prefix fields', function()
    it('should complete all of them', function()
      local expected = { 'myngx.ERROR', 'myngx.ERR' }
      local actual   = complete 'myngx.ERR'

      table.sort(expected)
      table.sort(actual)

      assert.are_same(expected, actual)
    end)
  end)

  context('values in _G', function()
    before_each(function() _G.foo = { bar = 'buz' } end)
    after_each(function() _G.foo = nil end)

    it('should complete', function()
      assert.are_same({ 'foo' }, complete 'fo')
      assert.are_same({ 'foo.bar' }, complete 'foo.')
      assert.are_same({ 'foo.bar' }, complete 'foo.bar.b')
    end)
  end)

  context('values in _G metatable', function()
    local _G_mt = getmetatable(_G)

    before_each(function()
      setmetatable(_G, { __index = { foo = { bar = 'buz' } }})
    end)

    after_each(function() setmetatable(_G, _G_mt) end)

    it('should complete', function()
      assert.are_same({ 'foo' }, complete 'fo')
      assert.are_same({ 'foo.bar' }, complete 'foo.')
      assert.are_same({ 'foo.bar' }, complete 'foo.bar.b')
    end)
  end)

  context('methods', function()
    it('should complete list of methods', function()
      assert.are_same({ 'myngx:print()', 'myngx:xprint()' }, complete 'myngx:')
    end)

    it('should complete method name', function()
      assert.are_same({ 'myngx:print()' }, complete 'myngx:pri')
      assert.are_same({ 'myngx:xprint()' }, complete 'myngx:xp')
    end)
  end)

  context('edge cases', function()
    it('should not fail', function()
      assert.are_same({}, complete 'myngx:xprint(')
    end)
  end)
end)
