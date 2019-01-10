local repl_binding = require 'resty.console.binding'

describe('resty repl binding', function()
  local caller_info
  local repl_code
  local eval_result
  local binding

  local eval_with_binding = function()
    binding = repl_binding.new(caller_info)
    eval_result = binding:eval(repl_code)
  end

  local outer_function = function(outer_arg)
    local outer_local = 'outer_local'
    local invisible_outer_local = 'invisible_outer_local'
    local upvalue_false = false

    local caller_function = function(caller_arg)
      local caller_local = 'caller_local'
      local caller_local_nil = nil
      local caller_local_false = false

      assert(caller_local_nil == nil)
      assert(caller_local_false == false)
      assert(upvalue_false == false)

      caller_info = debug.getinfo(1)

      eval_with_binding()

      return {
        caller_local = caller_local,
        caller_arg   = caller_arg,
        caller_local_nil = caller_local_nil,
        caller_local_nil_type = type(caller_local_nil),
        caller_local_false = caller_local_false,
        caller_local_false_type = type(caller_local_false),
        outer_local  = outer_local,
        outer_arg    = outer_arg,
      }
    end

    local result = caller_function('caller_arg_value')
    result.invisible_outer_local = invisible_outer_local

    return result
  end

  local run = function(code)
    repl_code = code
    local outer_func_ret = outer_function 'outer_arg'
    return eval_result, outer_func_ret
  end

  it('should calculate simple expression', function()
    local result = run '1 + 1'
    assert.are_same({ ok = true, val = 2 }, result)
  end)

  it('should return locals', function()
    local _, outer_func_ret = run 'caller_local'
    assert.are_equal('caller_local', outer_func_ret.caller_local)
  end)

  it('should return locals with nil value', function()
    local result = run 'caller_local_nil'
    assert.are_same({ ok = true, val = nil }, result)
  end)

  it('should return locals with false value', function()
    local result = run 'caller_local_false'
    assert.are_same({ ok = true, val = false }, result)
  end)

  it('should return upvalues with false value', function()
    local result = run 'upvalue_false'
    assert.are_same({ ok = true, val = false}, result)
  end)

  it('should be able to set locals with false value', function()
    local result = run 'caller_local_false = 123; return caller_local_false'
    assert.are_same({ ok = true, val = 123 }, result)
  end)

  it('should be able to set upvalues with false value', function()
    local result = run 'upvalue_false = 123; return upvalue_false'
    assert.are_same({ ok = true, val = 123 }, result)
  end)

  it('should return locals with nil value even if global is not nil', function()
    local _, outer_func_ret = run '_G.caller_local_nil = 123'
    assert.are_equal('nil', outer_func_ret.caller_local_nil_type)
  end)

  it('should set locals with nil value', function()
    local _, outer_func_ret = run 'caller_local_nil = 123'

    assert.are_equal('number', outer_func_ret.caller_local_nil_type)
    assert.are_equal(123, outer_func_ret.caller_local_nil)
  end)

  it('should return local arg', function()
    local result, outer_func_ret = run 'caller_arg'

    assert.are_same({ ok = true, val = 'caller_arg_value' }, result)
    assert.are_equal('caller_arg_value', outer_func_ret.caller_arg)
  end)

  it('should return upvalue', function()
    local result, outer_func_ret = run 'outer_local'

    assert.are_same({ ok = true, val = 'outer_local' }, result)
    assert.are_equal('outer_local', outer_func_ret.outer_local)
  end)

  it('should return upvalue arg', function()
    local result, outer_func_ret = run 'outer_arg'

    assert.are_same({ ok = true, val = 'outer_arg' }, result)
    assert.are_equal('outer_arg', outer_func_ret.outer_arg)
  end)

  it('should update locals', function()
    local result, outer_func_ret = run 'caller_local = 123'

    assert.are_same({ ok = true }, result) -- no ret value
    assert.are_equal(123, outer_func_ret.caller_local)
  end)

  it('should update local args', function()
    local result, outer_func_ret = run 'caller_arg = "123"; return caller_arg'

    assert.are_same({ ok = true, val = '123' }, result)
    assert.are_equal('123', outer_func_ret.caller_arg)
  end)

  it('should update upvalues', function()
    local result, outer_func_ret = run 'outer_local = 123'

    assert.are_same({ ok = true }, result) -- no ret value
    assert.are_equal(123, outer_func_ret.outer_local)
  end)

  it('should update upvalues with return', function()
    local result, outer_func_ret = run 'outer_local = 123; return outer_local'

    assert.are_same({ ok = true, val = 123}, result)
    assert.are_equal(123, outer_func_ret.outer_local)
  end)

  it('should update upvalues with ret value nil', function()
    local result, outer_func_ret = run 'outer_local = 123; return nil'

    assert.are_same({ ok = true, val = nil }, result)
    assert.are_equal(123, outer_func_ret.outer_local)
  end)

  it('should update upargs', function()
    local result, outer_func_ret = run 'outer_arg = 123'

    assert.are_same({ ok = true }, result) -- no ret value
    assert.are_equal(123, outer_func_ret.outer_arg)
  end)

  it('should read from fenv', function()
    local result = run 'foo'
    assert.are_same({ ok = true, val = nil }, result)

    binding.env.foo = 'foo'

    result = run 'foo'
    assert.are_same({ ok = true, val = 'foo' }, result)
  end)

  it('should update last return value into `_`', function()
    local result = run '_'
    assert.are_same({ ok = true, val = nil }, result)

    run '123'

    result = run '_'
    assert.are_same({ ok = true, val = 123 }, result)
  end)

  it('should remember vars between runs', function()
    local result = run 'a'
    assert.are_same({ ok = true, val = nil }, result)

    run 'a = 123'

    result = run 'a'
    assert.are_same({ ok = true, val = 123 }, result)
  end)

  it('should compile more complicated expressions', function()
    local result = run 'f=function() return 123 end; return f()'
    assert.are_same({ ok = true, val = 123 }, result)
  end)

  context('eval result', function()
    context('success', function()
      it('should be success', function()
        local res = repl_binding.make_result ( true )
        assert.is_true(res.ok)
      end)

      it('should have value', function()
        local res = repl_binding.make_result ( true, 'foo' )
        assert.are_equal('foo', res.val)
      end)

      it('should have no value', function()
        local res = repl_binding.make_result ( true )
        assert.is_nil(res.val)
      end)

      it('should have no error because success with no ret value', function()
        local res = repl_binding.make_result ( true )
        assert.is_nil(res.val)
      end)

      it('should have table value if table returned', function()
        local res = repl_binding.make_result (true, 1, 2 )
        assert.are_same({ 1, 2 }, res.val)
      end)

      it('should have table value if more returned', function()
        local res = repl_binding.make_result (true, 1, 2 )
        assert.are_same({ 1, 2 }, res.val)
      end)

      it('should have table value if many tables returned', function()
        local res = repl_binding.make_result (
          true,
          { 1, 2 },
          { 3, 4 }
        )
        assert.are_same({ { 1, 2 }, { 3, 4 } }, res.val)
      end)
    end)

    context('not success', function()
      it('should not be success', function()
        local res = repl_binding.make_result ( false )
        assert.is_false(res.ok)
      end)

      it('should have no value with error without ret value', function()
        local res = repl_binding.make_result ( false )
        assert.is_nil(res.val)
      end)

      it('should have no error without error specified', function()
        local res = repl_binding.make_result ( false )
        assert.is_nil(res.val)
      end)

      it('should have error', function()
        local res = repl_binding.make_result (false, 'foo' )
        assert.are_equal('foo', res.val)
      end)

      it('should have no return values', function()
        local res = repl_binding.make_result ( false )
        assert.is_falsy(res.val)
      end)

      it('should have return values with error', function()
        local res = repl_binding.make_result ( false, 'foo' )
        assert.is_truthy(res.val)
      end)
    end)
  end)
end)
