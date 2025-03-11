# REFramework SDK 文档翻译

主要入口点，大部分功能都从这里开始。
Main starting point for most things.

## 方法
## Methods
### `sdk.get_tdb_version()`
返回类型数据库的版本。这是游戏运行的RE引擎版本的一个很好的近似值。
Returns the version of the type database. A good approximation of the version of the RE Engine the game is running on.

### `sdk.game_namespace(name)`
返回`game_namespace.name`。
Returns `game_namespace.name`.

DMC5: `name`会被转换为`app.name`
DMC5: `name` would get converted to `app.name`

RE3: `name`会被转换为`offline.name`
RE3: `name` would get converted to `offline.name`

### `sdk.get_thread_context()`
获取线程上下文。

### `sdk.get_native_singleton(name)`
返回一个`void*`。可以与[sdk.call_native_func](#sdkcall_native_funcobject-type_definition-method_name-args)一起使用。
Returns a `void*`. Can be used with [sdk.call_native_func](#sdkcall_native_funcobject-type_definition-method_name-args)

可能的单例可以在对象浏览器的"Native Singletons"视图中找到。
Possible singletons can be found in the Native Singletons view in the Object Explorer.
### `sdk.get_managed_singleton(name)`
返回一个[REManagedObject*](types/REManagedObject.md)。
Returns an [REManagedObject*](types/REManagedObject.md).

可能的单例可以在对象浏览器的"Singletons"视图中找到。
Possible singletons can be found in the Singletons view in the Object Explorer.
### `sdk.find_type_definition(name)`
返回一个[RETypeDefinition*](types/RETypeDefinition.md)。
Returns an [RETypeDefinition*](types/RETypeDefinition.md).

### `sdk.typeof(name)`
返回一个`System.Type`对象。
Returns a `System.Type`. 

等同于调用`sdk.find_type_definition(name):get_runtime_type()`。
Equivalent to calling `sdk.find_type_definition(name):get_runtime_type()`.

相当于C#中的`typeof`。
Equivalent to `typeof` in C#.

### `sdk.create_instance(typename, simplify)`
返回一个[REManagedObject](types/REManagedObject.md)。
Returns an [REManagedObject](types/REManagedObject.md).

等同于调用`sdk.find_type_definition(typename):create_instance()`
Equivalent to calling `sdk.find_type_definition(typename):create_instance()`

`simplify` - 默认为`false`。如果此函数返回`nil`，请将此设置为`true`。
`simplify` - defaults to `false`. Set this to `true` if this function is returning `nil`.

### `sdk.create_managed_string(str)`
从`str`创建并返回一个新的`System.String`。
Creates and returns a new `System.String` from `str`.

### `sdk.create_managed_array(type, length)`
创建并返回一个给定`type`类型的新[SystemArray](types/SystemArray.md)，包含`length`个元素。
Creates and returns a new [SystemArray](types/SystemArray.md) of the given `type`, with `length` elements.

`type`可以是以下任何一种：
`type` can be any of the following:

* 从[sdk.typeof](#sdktypeofname)返回的`System.Type`
* A `System.Type` returned from [sdk.typeof](#sdktypeofname)
* 从[sdk.find_type_definition](#sdkfind_type_definitionname)返回的[RETypeDefinition](types/RETypeDefinition.md)
* An [RETypeDefinition](types/RETypeDefinition.md) returned from [sdk.find_type_definition](#sdkfind_type_definitionname)
* 表示类型名称的Lua`字符串`
* A Lua `string` representing the type name.

任何其他类型都会抛出Lua错误。
Any other type will throw a Lua error.

如果`type`无法解析为有效的`System.Type`，将抛出Lua错误。
If `type` cannot resolve to a valid `System.Type`, a Lua error will be thrown.

### `sdk.create_sbyte(value)`
根据给定的`value`返回一个完全构造的`System.SByte`类型的[REManagedObject](types/REManagedObject.md)。
Returns a fully constructed [REManagedObject](types/REManagedObject.md) of type `System.SByte` given the `value`.

### `sdk.create_byte(value)`
根据给定的`value`返回一个完全构造的`System.Byte`类型的[REManagedObject](types/REManagedObject.md)。
Returns a fully constructed [REManagedObject](types/REManagedObject.md) of type `System.Byte` given the `value`.

### `sdk.create_int16(value)`
根据给定的`value`返回一个完全构造的`System.Int16`类型的[REManagedObject](types/REManagedObject.md)。
Returns a fully constructed [REManagedObject](types/REManagedObject.md) of type `System.Int16` given the `value`.

### `sdk.create_uint16(value)`
根据给定的`value`返回一个完全构造的`System.UInt16`类型的[REManagedObject](types/REManagedObject.md)。
Returns a fully constructed [REManagedObject](types/REManagedObject.md) of type `System.UInt16` given the `value`.

### `sdk.create_int32(value)`
根据给定的`value`返回一个完全构造的`System.Int32`类型的[REManagedObject](types/REManagedObject.md)。
Returns a fully constructed [REManagedObject](types/REManagedObject.md) of type `System.Int32` given the `value`.

### `sdk.create_uint32(value)`
根据给定的`value`返回一个完全构造的`System.UInt32`类型的[REManagedObject](types/REManagedObject.md)。
Returns a fully constructed [REManagedObject](types/REManagedObject.md) of type `System.UInt32` given the `value`.

### `sdk.create_int64(value)`
根据给定的`value`返回一个完全构造的`System.Int64`类型的[REManagedObject](types/REManagedObject.md)。
Returns a fully constructed [REManagedObject](types/REManagedObject.md) of type `System.Int64` given the `value`.

### `sdk.create_uint64(value)`
根据给定的`value`返回一个完全构造的`System.UInt64`类型的[REManagedObject](types/REManagedObject.md)。
Returns a fully constructed [REManagedObject](types/REManagedObject.md) of type `System.UInt64` given the `value`.

### `sdk.create_single(value)`
根据给定的`value`返回一个完全构造的`System.Single`类型的[REManagedObject](types/REManagedObject.md)。
Returns a fully constructed [REManagedObject](types/REManagedObject.md) of type `System.Single` given the `value`.

### `sdk.create_double(value)`
根据给定的`value`返回一个完全构造的`System.Double`类型的[REManagedObject](types/REManagedObject.md)。
Returns a fully constructed [REManagedObject](types/REManagedObject.md) of type `System.Double` given the `value`.

### `sdk.create_resource(typename, resource_path)`
返回一个`REResource`。
Returns an `REResource`.

如果typename与资源文件不正确对应或不是资源类型，将返回`nil`。
If the typename does not correctly correspond to the resource file or is not a resource type, `nil` will be returned.

### `sdk.create_userdata(typename, userdata_path)`
返回一个作为`via.UserData`的[REManagedObject](types/REManagedObject.md)。除非你知道完整的类型名称，否则`typename`可以是`"via.UserData"`。
Returns an [REManagedObject](types/REManagedObject.md) which is a `via.UserData`. `typename` can be `"via.UserData"` unless you know the full typename.

### `sdk.deserialize(data)`
从`data`生成并返回[REManagedObject](types/REManagedObject.md)的列表。
Returns a list of [REManagedObject](types/REManagedObject.md) generated from `data`. 

`data`是原始RSZ数据，例如包含在`.scn`文件中，从header里的`RSZ`魔数开始。
`data` is the raw RSZ data contained for example in a `.scn` file, starting at the `RSZ` magic in the header.

`data`必须是`table`格式的字节数组。
`data` must in `table` format as an array of bytes.

使用示例：
Example usage:
```
local rsz_data = json.load_file("Foobar.json")
local objects = sdk.deserialize(rsz_data)

for i, v in ipairs(objects) do
    local obj_type = v:get_type_definition()
    log.info(obj_type:get_full_name())
end
```

### `sdk.call_native_func(object, type_definition, method_name, args...)`
返回值取决于方法返回的内容。
Return value is dependent on what the method returns.

如果有多个同名但参数不同的函数，可以将完整的函数原型作为`method_name`传递。
Full function prototype can be passed as `method_name` if there are multiple functions with the same name but different parameters.

应该只用于本地类型，而不是[REManagedObject](types/REManagedObject.md)（尽管如果需要，也可以用于它）。
Should only be used with native types, not [REManagedObject](types/REManagedObject.md) (though, it can be if wanted).

示例：
Example:
```lua
local scene_manager = sdk.get_native_singleton("via.SceneManager")
local scene_manager_type = sdk.find_type_definition("via.SceneManager")
local scene = sdk.call_native_func(scene_manager, scene_manager_type, "get_CurrentScene")

if scene ~= nil then
    -- 我们可以这样使用call，因为scene是一个托管对象，而不是本地对象。
    -- We can use call like this because scene is a managed object, not a native one.
    scene:call("set_TimeScale", 5.0)
end
```
### `sdk.call_object_func(managed_object, method_name, args...)`
返回值取决于方法返回的内容。
Return value is dependent on what the method returns.

如果有多个同名但参数不同的函数，可以将完整的函数原型作为`method_name`传递。
Full function prototype can be passed as `method_name` if there are multiple functions with the same name but different parameters.

替代调用方法：
Alternative calling method:
`managed_object:call(method_name, args...)`

### `sdk.get_native_field(object, type_definition, field_name)`
获取本机字段值。

### `sdk.set_native_field(object, type_definition, field_name, value)`
设置本机字段值。

### `sdk.get_primary_camera()`
返回一个[REManagedObject*](types/REManagedObject.md)。返回引擎当前使用的相机。
Returns a [REManagedObject*](types/REManagedObject.md). Returns the current camera being used by the engine.

### `sdk.hook(method_definition, pre_function, post_function, ignore_jmp)`
为[method_definition](types/REMethodDefinition.md)创建一个钩子，拦截游戏对它的所有传入调用。
Creates a hook for [method_definition](types/REMethodDefinition.md), intercepting all incoming calls the game makes to it.

`ignore_jmp` - 跳过尝试跟随函数中的第一个jmp。默认为`false`。
`ignore_jmp` - Skips trying to follow the first jmp in the function. Defaults to `false`.

使用`pre_function`和`post_function`，可以修改这些函数的行为。
Using `pre_function` and `post_function`, the behavior of these functions can be modified.

注意：有些本机方法可能无法通过此方式进行钩子，例如，如果它们只是本机函数的包装器。我们这边需要做一些额外的工作才能使这些方法工作。
NOTE: Some native methods may not be able to be hooked with this, e.g. if they are just a  wrapper over the native function. Some additional work will need to be done from our end to make those work.

pre_function和post_function的形式如下：
pre_function and post_function looks like so:
```lua
local function pre_function(args)
    -- args是可修改的
    -- args[1] = 线程上下文
    -- args[2] = "this"/对象指针
    -- 其余的args是实际参数
    -- 在静态函数中，实际参数从args[2]开始
    -- 一些本机函数会让对象从args[1]开始，其余从args[2]开始
    -- 所有args都是void*，不会自动转换为各自的类型。
    -- 你需要做类似于sdk.to_managed_object(args[2])
    -- 或sdk.to_int64(args[3])这样的事情，以便更好地与参数交互或读取。

    -- 如果参数是ValueType，你需要这样访问其字段：
    -- local type = sdk.find_type_definition("via.Position")
    -- local x = sdk.get_native_field(arg[3], type, "x")

    -- 可选：指定一个sdk.PreHookResult
    -- 例如
    -- return sdk.PreHookResult.SKIP_ORIGINAL -- 阻止调用原始函数
    -- return sdk.PreHookResult.CALL_ORIGINAL -- 调用原始函数，与不返回任何内容相同
end

local function post_function(retval)
    -- 如果你不想要原始返回值，可以返回其他内容
    -- 注意：即使从pre_function返回SKIP_ORIGINAL，post_function仍会被调用
    -- 因此，如果你的函数期望返回有效内容，请记住这一点，因为retval将无效。
    -- 确保将自定义retvals转换为sdk.to_ptr(retval)
    return retval
end
```

钩子示例：
Example hook:
```lua
local function on_pre_get_timescale(args)
end

local function on_post_get_timescale(retval)
    -- 让游戏运行速度比正常快5倍
    -- 待办：使得像这样转换返回值不再必要
    return sdk.float_to_ptr(5.0)
end

sdk.hook(sdk.find_type_definition("via.Scene"):get_method("get_TimeScale"), on_pre_get_timescale, on_post_get_timescale)
```

### `sdk.hook_vtable(obj, method, pre, post)`
与`sdk.hook`类似，但是是在**每个对象**的基础上进行钩子，而不是全局地为所有对象钩子该函数。
Similar to `sdk.hook` but hooks on a **per-object** basis instead, instead of hooking the function globally for all objects.

仅适用于目标方法是**虚拟方法**的情况。
Only works if the target method is a **virtual method**.

### `sdk.is_managed_object(value)`
如果`value`是一个有效的[REManagedObject](types/REManagedObject.md)，则返回true。
Returns true if `value` is a valid [REManagedObject](types/REManagedObject.md).

仅在必要时使用。进行大量检查并多次调用[IsBadReadPtr](https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-isbadreadptr)。
Use only if necessary. Does a bunch of checks and calls [IsBadReadPtr](https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-isbadreadptr) a lot.
### `sdk.to_managed_object(value)`
尝试将`value`转换为[REManagedObject*](types/REManagedObject.md)。
Attempts to convert `value` to an [REManagedObject*](types/REManagedObject.md).

`value`可以是以下任何类型：
`value` can be any of the following types:

* 一个[REManagedObject*](types/REManagedObject.md)，这种情况下它将原样返回
* An [REManagedObject*](types/REManagedObject.md), in which case it is returned as-is
* 可转换为`uintptr_t`的lua数字，表示对象的地址
* A lua number convertible to `uintptr_t`, representing the object's address
* 一个`void*`
* A `void*`

任何其他类型都将返回`nil`。
Any other type will return `nil`.

一个不是有效[REManagedObject*](types/REManagedObject.md)的`value`将返回`nil`，相当于对其调用[sdk.is_managed_object](#sdkis_managed_objectvalue)。
A `value` that is not a valid [REManagedObject*](types/REManagedObject.md) will return `nil`, equivalent to calling [sdk.is_managed_object](#sdkis_managed_objectvalue) on it.

### `sdk.to_double(value)`
尝试将`value`转换为`double`。
Attempts to convert `value` to a `double`.

`value`可以是以下任何类型：
`value` can be any of the following types:

* 一个`void*`
* A `void*`

### `sdk.to_float(value)`
尝试将`value`转换为`float`。
Attempts to convert `value` to a `float`.

`value`可以是以下任何类型：
`value` can be any of the following types:
* 一个`void*`
* A `void*`

### `sdk.to_int64(value)`
尝试将`value`转换为`int64`。
Attempts to convert `value` to a `int64`.

`value`可以是以下任何类型：
`value` can be any of the following types:
* 一个`void*`
* A `void*`

如果你需要更小的数据类型，可以这样做：
If you need a smaller datatype, you can do:
* `(sdk.to_int64(value) & 1) == 1` 用于布尔值
* `(sdk.to_int64(value) & 1) == 1` for a boolean
* `(sdk.to_int64(value) & 0xFF)` 用于无符号字节
* `(sdk.to_int64(value) & 0xFF)` for an unsigned byte
* `(sdk.to_int64(value) & 0xFFFF)` 用于无符号短整型（2字节）
* `(sdk.to_int64(value) & 0xFFFF)` for an unsigned short (2 bytes)
* `(sdk.to_int64(value) & 0xFFFFFFFF)` 用于无符号整型（4字节）
* `(sdk.to_int64(value) & 0xFFFFFFFF)` for an unsigned int (4 bytes)

### `sdk.to_ptr(value)`
尝试将`value`转换为`void*`。
Attempts to convert `value` to a `void*`.

`value`可以是以下任何类型：
`value` can be any of the following types:

* 一个[REManagedObject*](types/REManagedObject.md)
* An [REManagedObject*](types/REManagedObject.md)
* 可转换为`int64_t`的lua数字
* A lua number convertible to `int64_t`
* 可转换为`double`的lua数字
* A lua number convertible to `double`
* 一个lua布尔值
* A lua boolean
* 一个`void*`，这种情况下它将原样返回
* A `void*`, in which case it is returned as-is

任何其他类型都将返回`nil`。
Any other type will return `nil`.

### `sdk.to_valuetype(obj, t)`
尝试将`obj`转换为`t`
Attempts to convert `obj` to `t`

`obj`可以是：
`obj` can be a:

* 数字
* Number
* void*
* void*

`t`可以是：
`t` can be a:

* [RETypeDefinition](types/RETypeDefinition.md)
* [RETypeDefinition](types/RETypeDefinition.md)
* 字符串
* string

### `sdk.float_to_ptr(number)`
将`number`转换为`void*`。
Converts `number` to a `void*`.

## 枚举
## Enums
### `sdk.PreHookResult`
* `sdk.PreHookResult.CALL_ORIGINAL`
* `sdk.PreHookResult.SKIP_ORIGINAL`
