local files    = require 'files'
local furi     = require 'file-uri'
local core     = require 'core.definition'
local config   = require 'config'
local platform = require 'bee.platform'
local catch    = require 'catch'

rawset(_G, 'TEST', true)

local function founded(targets, results)
    if #targets ~= #results then
        return false
    end
    for _, target in ipairs(targets) do
        for _, result in ipairs(results) do
            if target[1] == result[1]
            and target[2] == result[2]
            and target[3] == result[3]
            then
                goto NEXT
            end
        end
        do return false end
        ::NEXT::
    end
    return true
end

function TEST(datas)
    local targetList = {}
    local sourceList
    local sourceUri
    for i, data in ipairs(datas) do
        local uri = furi.encode(data.path)
        local newScript, catched = catch(data.content, '!?~')
        for _, position in ipairs(catched['!'] or {}) do
            targetList[#targetList+1] = {
                position[1],
                position[2],
                uri,
            }
        end
        for _, position in ipairs(catched['~'] or {}) do
            targetList[#targetList+1] = {
                position[1],
                position[2],
                uri,
            }
        end
        if #catched['?'] > 0 or #catched['~'] > 0 then
            sourceList = catched['?'] + catched['~']
            sourceUri = uri
        end
        files.setText(uri, newScript)
    end

    local _ <close> = function ()
        for _, info in ipairs(datas) do
            files.remove(furi.encode(info.path))
        end
    end

    local sourcePos = (sourceList[1][1] + sourceList[1][2]) // 2
    local positions = core(sourceUri, sourcePos)
    if positions then
        local result = {}
        for i, position in ipairs(positions) do
            result[i] = {
                position.target.start,
                position.target.finish,
                position.uri,
            }
        end
        assert(founded(targetList, result))
    else
        assert(#targetList == 0)
    end
end

TEST {
    {
        path = 'a.lua',
        content = '<!!>',
    },
    {
        path = 'b.lua',
        content = 'require <?"a"?>',
    },
}

TEST {
    {
        path = 'aaa/bbb.lua',
        content = '<!!>',
    },
    {
        path = 'b.lua',
        content = 'require "aaa.<?bbb?>"',
    },
}

TEST {
    {
        path = '@bbb.lua',
        content = '<!!>',
    },
    {
        path = 'b.lua',
        content = 'require "<?@bbb?>"',
    },
}

TEST {
    {
        path = 'aaa/bbb.lua',
        content = '<!!>',
    },
    {
        path = 'b.lua',
        content = 'require "<?bbb?>"',
    },
}

config.set(nil, 'Lua.runtime.pathStrict', true)
TEST {
    {
        path = 'aaa/bbb.lua',
        content = '',
    },
    {
        path = 'b.lua',
        content = 'require "<?bbb?>"',
    },
}

TEST {
    {
        path = 'aaa/bbb.lua',
        content = '<!!>',
    },
    {
        path = 'b.lua',
        content = 'require "<?aaa.bbb?>"',
    },
}

config.set(nil, 'Lua.runtime.pathStrict', false)

--FA test
local originSeparator = config.get(nil, 'Lua.completion.requireSeparator')
config.set(nil, 'Lua.completion.requireSeparator', '/')
local originRuntimePath = config.get(nil, 'Lua.runtime.path')
config.set(nil, 'Lua.runtime.path', {
    '/?',
})

TEST {
    {
        path = '/lua/Test.lua',
        content = '<!!>',
    },
    {
        path = 'a.lua',
        content = 'require "<?/lua/Test.lua?>"',
    }
}

-- lower case matching upper case test
TEST {
    {
        path = '/lua/Test.lua',
        content = '<!!>',
    },
    {
        path = 'a.lua',
        content = 'require "<?/lua/test.lua?>"',
    }
}

config.set(nil, 'Lua.runtime.path', originRuntimePath)
config.set(nil, 'Lua.completion.requireSeparator', originSeparator)

TEST {
    {
        path = 'a.lua',
        content = 'return <!function () end!>',
    },
    {
        path = 'b.lua',
        content = 'local <~t~> = require "a"',
    },
}

TEST {
    {
        path = 'a.lua',
        content = 'return <!function () end!>',
    },
    {
        path = 'b.lua',
        content = [[
---@module 'a'
local <~t~>
]],
    },
}

--if require 'bee.platform'.OS == 'Windows' then
--TEST {
--    {
--        path = 'a.lua',
--        content = '',
--        target = {0, 0},
--    },
--    {
--        path = 'b.lua',
--        content = 'require <?"A"?>',
--    },
--}
--end

TEST {
    {
        path = 'a.lua',
        content = 'return <!function () end!>',
    },
    {
        path = 'b.lua',
        content = 'local <~t~> = require "a"',
    },
}

TEST {
    {
        path = 'a.lua',
        content = [[
            local t = {
                <!x!> = 1,
            }
            return t
        ]],
    },
    {
        path = 'b.lua',
        content = [[
            local t = require "a"
            t.<?x?>()
        ]],
    },
}

TEST {
    {
        path = 'a.lua',
        content = [[
            return {
                <!x!> = 1,
            }
        ]],
    },
    {
        path = 'b.lua',
        content = [[
            local t = require "a"
            t.<?x?>()
        ]],
    },
}

--FA test
TEST {
    {
        path = 'a.lua',
        content = [[
            ---@export-env
            <!x!> = 1,
        ]],
    },
    {
        path = 'b.lua',
        content = [[
            local t = require "a"
            t.<?x?>()
        ]],
    },
}

TEST {
    {
        path = 'a.lua',
        content = [[
            return <!function ()
            end!>
        ]],
    },
    {
        path = 'b.lua',
        content = [[
            local <!f!> = require "a"
            <?f?>()
        ]],
    },
}

TEST {
    {
        path = 'a.lua',
        content = [[
            return a():b():c()
        ]],
    },
    {
        path = 'b.lua',
        content = [[
            local <~t~> = require 'a'
        ]],
    },
}

TEST {
    {
        path = 'a.lua',
        content = [[
            <!global!> = 1
        ]],
    },
    {
        path = 'b.lua',
        content = [[
            print(<?global?>)
        ]],
    }
}

TEST {
    {
        path = 'b.lua',
        content = [[
            print(<?global?>)
        ]],
    },
    {
        path = 'a.lua',
        content = [[
            <!global!> = 1
        ]],
    },
}

TEST {
    {
        path = 'a.lua',
        content = [[
            x = {}
            x.<!global!> = 1
        ]],
    },
    {
        path = 'b.lua',
        content = [[
            print(x.<?global?>)
        ]],
    },
}

TEST {
    {
        path = 'a.lua',
        content = [[
            x.<!global!> = 1
        ]],
    },
    {
        path = 'b.lua',
        content = [[
            print(x.<?global?>)
        ]],
    },
    {
        path = 'c.lua',
        content = [[
            x = {}
        ]]
    }
}

TEST {
    {
        path = 'a.lua',
        content = [[
            return function (<!arg!>)
                print(<?arg?>)
            end
        ]],
    },
    {
        path = 'b.lua',
        content = [[
            local f = require 'a'
            local v = 1
            f(v)
        ]],
    },
}

TEST {
    {
        path = 'a.lua',
        content = [[
            return <!function () end!>
        ]],
    },
    {
        path = 'b.lua',
        content = [[
            local <!t!> = require 'a'
            <?t?>
        ]],
    }
}

TEST {
    {
        path = 'a.lua',
        content = [[
            return <!function () end!>
        ]]
    },
    {
        path = 'b.lua',
        content = [[
            local f = require 'a'
        ]]
    },
    {
        path = 'c.lua',
        content = [[
            local <!f!> = require 'a'
            <?f?>
        ]]
    }
}

TEST {
    {
        path = 'a.lua',
        content = [[
            local <!function f()
            end!>
            return f
        ]]
    },
    {
        path = 'b.lua',
        content = [[
            local f = require 'a'
        ]]
    },
    {
        path = 'c.lua',
        content = [[
            local <!f!> = require 'a'
            <?f?>
        ]]
    }
}

TEST {
    {
        path = 'a/xxx.lua',
        content = [[
            return <!function () end!>
        ]]
    },
    {
        path = 'b/xxx.lua',
        content = [[
            local <!f!> = require 'xxx'
            <?f?>
            return function () end
        ]]
    }
}

TEST {
    {
        path = 'a.lua',
        content = [[
            local <!x!>
            return {
                <!x!> = x,
            }
        ]],
    },
    {
        path = 'b.lua',
        content = [[
            local t = require 'a'
            print(t.<?x?>)
        ]],
    },
}

TEST {
    {
        path = 'a.lua',
        content = [[
            local <!function f()
            end!>

            return {
                f = f,
            }
        ]]
    },
    {
        path = 'c.lua',
        content = [[
            local t = require 'a'
            local f = t.f

            f()

            return {
                f = f,
            }
        ]]
    },
    {
        path = 'b.lua',
        content = [[
            local t = require 'a'
            local <!f!> = t.f

            <?f?>()

            return {
                f = f,
            }
        ]]
    }
}

TEST {
    {
        path = 'a.lua',
        content = [[
            local m = {}
            function m.<!func!>()
            end
            return m
        ]]
    },
    {
        path = 'b.lua',
        content = [[
            local x = require 'a'
            print(x.<?func?>)
        ]]
    }
}

TEST {
    {
        path = 'a.lua',
        content = [[
            local m = {}
            function m.<!func!>()
            end
            return m
        ]]
    },
    {
        path = 'c.lua',
        content = [[
            local x = require 'a'
            print(x.func)
        ]]
    },
    {
        path = 'b.lua',
        content = [[
            local x = require 'a'
            print(x.<?func?>)
        ]]
    }
}

TEST {
    {
        path = 'a.lua',
        content = [[
            return <!function ()
            end!>
        ]]
    },
    {
        path = 'middle.lua',
        content = [[
            return {
                <!func!> = require 'a'
            }
        ]]
    },
    {
        path = 'b.lua',
        content = [[
            local x = require 'middle'
            print(x.<?func?>)
        ]]
    }
}

TEST {
    {
        path = 'a.lua',
        content = [[
            local mt = {}
            mt.__index = mt

            function mt:<!add!>(a, b)
            end
            
            return function ()
                return setmetatable({}, mt)
            end
        ]],
    },
    {
        path = 'b.lua',
        content = [[
            local m = require 'a'
            local obj = m()
            obj:<?add?>()
        ]]
    },
}

TEST {
    {
        path = 'a.lua',
        content = [[
            GlobalTable.settings = {
                <!test!> = 1
            }
        ]],
    },
    {
        path = 'b.lua',
        content = [[
            local b = GlobalTable.settings

            print(b.<?test?>)
        ]]
    },
}

TEST {
    {
        path = 'a.lua',
        content = [[
            ---@class Class
            local obj
        ]]
    },
    {
        path = 'b.lua',
        content = [[
            ---@type Class
            local <!obj!>
            <?obj?>
        ]]
    },
}

TEST {
    {
        path = 'a.lua',
        content = [[
            ---@type Class
            local <!obj!>
            <?obj?>
        ]]
    },
    {
        path = 'b.lua',
        content = [[
            ---@class Class
            local obj
        ]]
    },
}

TEST {
    {
        path = 'a.lua',
        content = [[
            local lib = {}

            function lib:fn1()
                return self
            end
            
            function lib:<!fn2!>()
            end
            
            return lib:fn1()
        ]]
    },
    {
        path = 'b.lua',
        content = [[
            local app = require 'a'
            print(app.<?fn2?>)
        ]]
    },
}

TEST {
    {
        path = 'a.lua',
        content = [[
            local m = {}

            function m.<!f!>()
            end

            return setmetatable(m, {})
        ]],
    },
    {
        path = 'b.lua',
        content = [[
            local m = require 'a'

            m.<?f?>()
        ]]
    }
}


if platform.OS == 'Linux' then

TEST {
    {
        path = 'test.lua',
        content = [[
            return {
                <!x!> = 1,
            }
        ]],
    },
    {
        path = 'Test.lua',
        content = [[
            return {
                x = 1,
            }
        ]],
    },
    {
        path = 'b.lua',
        content = [[
            local t = require 'test'
            print(t.<?x?>)
        ]]
    }
}

TEST {
    {
        path = 'test.lua',
        content = [[
            return {
                x = 1,
            }
        ]],
    },
    {
        path = 'Test.lua',
        content = [[
            return {
                <!x!> = 1,
            }
        ]],
    },
    {
        path = 'b.lua',
        content = [[
            local t = require 'Test'
            print(t.<?x?>)
        ]]
    }
}

end

local originRuntimePath = config.get(nil, 'Lua.runtime.path')
config.set(nil, 'Lua.runtime.path', {
    '?/1.lua',
})
TEST {
    {
        path = 'd:/xxxx/1.lua',
        content = [[
            return <!function () end!>
        ]],
    },
    {
        path = 'main.lua',
        content = [[
            local <!f!> = require 'xxxx'
            print(<?f?>)
        ]],
    },
}

config.set(nil, 'Lua.runtime.path', {
    'D:/?/1.lua',
})
TEST {
    {
        path = 'D:/xxxx/1.lua',
        content = [[
            return <!function () end!>
        ]],
    },
    {
        path = 'main.lua',
        content = [[
            local <!f!> = require 'xxxx'
            print(<?f?>)
        ]],
    },
}
config.set(nil, 'Lua.runtime.path', originRuntimePath)

TEST {
    {
        path = 'a.lua',
        content = [[
            a = b.x
        ]],
    },
    {
        path = 'b.lua',
        content = [[
            b = a.<?x?>
        ]],
    },
}

TEST {
    {
        path = 'a.lua',
        content = [[
GlobalTable.settings = {
    <!test!> = 1
}
        ]]
    },
    {
        path = 'b.lua',
        content = [[
local b = GlobalTable.settings

print(b.<?test?>)
        ]]
    }
}

TEST {
    {
        path = 'a.lua',
        content = [[
GlobalTable = {
    settings = {
        <!test!> = 1
    }
}
        ]]
    },
    {
        path = 'b.lua',
        content = [[
local b = GlobalTable.settings

print(b.<?test?>)
        ]]
    }
}

TEST {
    {
        path = 'a.lua',
        content = [[
---@class A
local t

t.<!a!> = 1
        ]]
    },
    {
        path = 'b.lua',
        content = [[
---@class B
local t

---@type A
t.x = nil

print(t.x.<?a?>)
        ]]
    }
}

TEST {
    {
        path = 'a.lua',
        content = [[
return {
    <!x!> = 1,
}
]],
    },
    {
        path = 'f/a.lua',
        content = [[
return {
    x = 1,
}
]]
    },
    {
        path = 'b.lua',
        content = [[
local t = require 'a'
print(t.<?x?>)
        ]]
    }
}

local originRuntimePath = config.get(nil, 'Lua.runtime.path')

config.set(nil, 'Lua.runtime.path', {
    './?.lua'
})
TEST {
    {
        path = 'a.lua',
        content = [[
return {
    <!x!> = 1,
}
]],
    },
    {
        path = 'b.lua',
        content = [[
local t = require 'a'
print(t.<?x?>)
        ]]
    }
}

-- config.set(nil, 'Lua.runtime.path', {
--     '/home/?.lua'
-- })
-- TEST {
--     {
--         path = '/home/a.lua',
--         content = [[
-- return {
--     <!x!> = 1,
-- }
-- ]],
--     },
--     {
--         path = 'b.lua',
--         content = [[
-- local t = require 'a'
-- print(t.<?x?>)
--         ]]
--     }
-- }

config.set(nil, 'Lua.runtime.pathStrict', true)
config.set(nil, 'Lua.runtime.path', {
    './?.lua'
})
TEST {
    {
        path = 'a.lua',
        content = [[
return {
    <!x!> = 1,
}
]],
    },
    {
        path = 'b.lua',
        content = [[
local t = require 'a'
print(t.<?x?>)
        ]]
    }
}

-- config.set(nil, 'Lua.runtime.path', {
--     '/home/?.lua'
-- })
-- TEST {
--     {
--         path = '/home/a.lua',
--         content = [[
-- return {
--     <!x!> = 1,
-- }
-- ]],
--     },
--     {
--         path = 'b.lua',
--         content = [[
-- local t = require 'a'
-- print(t.<?x?>)
--         ]]
--     }
-- }

config.set(nil, 'Lua.runtime.pathStrict', false)
config.set(nil, 'Lua.runtime.path', originRuntimePath)

-- Don't require self
TEST {
    {
        path = 'a.lua',
        content = [[
local <~f~> = require 'a'
return function () end
        ]]
    }
}
