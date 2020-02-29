local Unique_Array = require('__stdlib__/stdlib/utils/classes/unique_array')

local disable =
    Unique_Array {
    'LoaderRedux',
    'MoreLoaderRedux',
    'Loader_Redux'
}
local mods = Unique_Array.from_dictionary(mods)

if not mods:any(disable) then
    data:extend {
        {
            type = 'bool-setting',
            name = 'picker-loader-snapping',
            setting_type = 'runtime-global',
            default_value = true,
            order = 'loader-snapping'
        }
    }
end
