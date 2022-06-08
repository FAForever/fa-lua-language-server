-- if not set, the folder name will be used
name    = 'Forged Alliance'
-- match any word to load 
words   = {'.'}
-- lsit of settings to be changed
---@type config.change[]
configs = {
    {
        key    = 'Lua.runtime.version',
        action = 'set',
        value  = 'Lua 5.1',
    },
    {
        key    = 'Lua.runtime.path',
        action = 'add',
        value  = '/?',
    },
    {
        key    = 'Lua.completion.showWord',
        action = 'set',
        value  = 'Disable',
    },
    {
        key    = 'Lua.runtime.special',
        action = 'prop',
        prop   = 'import',
        value  = 'require',
    },
    {
        key    = 'Lua.runtime.special',
        action = 'prop',
        prop   = 'doscript',
        value  = 'require',
    },
    {
        key    = 'Lua.runtime.nonstandardSymbol',
        action = 'add',
        value  = 'continue',
    },
    {
        key    = 'Lua.runtime.nonstandardSymbol',
        action = 'add',
        value  = '!=',
    },
    {
        key    = 'Lua.completion.requireSeparator',
        action = 'set',
        value  = '/',
    },
    {
        key    = 'Lua.runtime.pathStrict',
        action = 'set',
        value  = false,
    },
    {
        key    = 'Lua.runtime.exportEnvDefault',
        action = 'set',
        value  = true,
    },
}
for _, name in ipairs {'moho'} do
    configs[#configs+1] = {
        key    = 'Lua.diagnostics.globals',
        action = 'add',
        value  = name,
    }
end
