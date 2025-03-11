# REManagedObject文档翻译

REManagedObject是引擎中大多数类型的基本构建块（除非它们是原生类型）。
REManagedObjects are the basic building blocks of most types in the engine (unless they're native types).

它们从以下方法中返回：
They are returned from methods like:
* `sdk.call_native_func`
* `sdk.call_object_func`
* `sdk.get_managed_singleton`
* `REManagedObject:call`

使用示例：
Example usage:
```lua
local scene_manager = sdk.get_native_singleton("via.SceneManager")
local scene_manager_type = sdk.find_type_definition("via.SceneManager")
local scene = sdk.call_native_func(scene_manager, scene_manager_type, "get_CurrentScene")

-- Scene是一个REManagedObject
-- Scene is an REManagedObject
if scene ~= nil then
    local current_timescale = scene:call("get_TimeScale")
    log.info("Current timescale: " .. tostring(current_timescale))

    scene:call("set_TimeScale", 5.0)
end
```

## 自定义索引器
## Custom indexers
### `self.foo`
如果`foo`是对象的字段或方法，则返回字段值或存在的`REMethodDefinition`。
If `foo` is a field or method of the object, returns either the field or `REMethodDefinition` if it exists.

### `self:foo(bar, baz)`
如果`foo`是对象的方法，则使用提供的参数调用`foo`。
If `foo` is a method of the object, calls `foo` with the supplied arguments.

如果该方法是重载函数，则必须使用正确的函数原型调用`self:call(name, args...)`，因为这不会根据传递的参数推断正确的函数。
If the method is an overloaded function, you must instead use `self:call(name, args...)` with the correct function prototype, as this does not deduce the correct function based on the passed arguments.

### `self.foo = bar`
如果`foo`是对象的字段，则将值`bar`赋给该字段。
If `foo` is a field of the object, assigns the value `bar` to the field.

这会自动处理旧字段和新字段的引用计数。在这种情况下，不要使用`:force_release()`和`:add_ref_permanent()`来处理引用。
This automatically handles the reference counting for the old and new field. Do not use `:force_release()` and `:add_ref_permanent()` in this case to handle the references.

### `self[i]`
检查对象是否有`get_Item`方法并用`i`调用它。
Checks if the object has a `get_Item` method and calls it with `i`.

### `self[i] = foo`
检查对象是否有`set_Item`方法并用`i`和`foo`作为相应的参数调用它。
Checks if the object has a `set_Item` method and calls it with `i` and `foo` as the respective parameters.

## 方法
## Methods
### `self:call(method_name, args...)`
返回值取决于方法的返回类型。包装了`sdk.call_object_func`。
Return value is dependent on the method's return type. Wrapper over `sdk.call_object_func`.

如果有多个同名但参数不同的函数，可以将完整的函数原型作为`method_name`传递。
Full function prototype can be passed as `method_name` if there are multiple functions with the same name but different parameters.

例如：`self:call("foo(System.String, System.Single, System.UInt32, System.Object)", a, b, c, d)`
e.g. `self:call("foo(System.String, System.Single, System.UInt32, System.Object)", a, b, c, d)`

有效的方法名称可以在对象浏览器中找到。找到你要查找的类型，有效的方法将在`TDB Methods`下找到。
Valid method names can be found in the Object Explorer. Find the type you're looking for, and valid methods will be found under `TDB Methods`.
### `self:get_type_definition()`
返回一个`RETypeDefinition*`。
Returns an `RETypeDefinition*`.
### `self:get_field(name)`
返回类型取决于字段类型。
Return type is dependent on the field type.
### `self:set_field(name, value)`
设置字段值。
### `self:get_address()`
获取地址。
### `self:get_reference_count()`
获取引用计数。

### `self:deserialize_native(data, objects)`
将`data`反序列化到`self`的实验性API。
Experimental API to deserialize `data` into `self`.

`data`是RSZ数据，格式为字节数组的`table`。
`data` is RSZ data, in `table` format as an array of bytes.

仅适用于原生`via`类型。
Will only work on native `via` types.

## 危险方法
## Dangerous Methods
仅在必要时使用这些方法！
Only use these if necessary!

### `self:add_ref()`
增加对象的内部引用计数。
Increments the object's internal reference count.

### `self:add_ref_permanent()`
增加对象的内部引用计数，而不由REFramework管理。任何使用REFramework创建并使用此方法的对象在Lua状态被销毁后不会被删除。
Increments the object's internal reference count without REFramework managing it. Any objects created with REFramework and also using this method will not be deleted after the Lua state is destroyed.

### `self:release()`
减少对象的内部引用计数。如果计数达到0，则销毁对象。只能用于由Lua管理的对象。
Decrements the object's internal reference count. Destroys the object if it reaches 0. Can only be used on objects managed by Lua.

### `self:force_release()`
减少对象的内部引用计数。如果计数达到0，则销毁对象。可用于任何REManagedObject。可能导致游戏崩溃或未定义行为。
Decrements the object's internal reference count. Destroys the object if it reaches 0. Can be used on any REManagedObject. Can crash the game or cause undefined behavior.

当创建对`REManagedObject`的新Lua引用时，REFramework会通过`self:add_ref()`自动增加其内部引用计数。这将保持对象活动状态，直到你在Lua中不再引用该对象。当Lua在任何地方不再引用该对象时，会自动调用`self:release()`。
When a new Lua reference is created to an `REManagedObject`, REFramework automatically increments its reference count internally with `self:add_ref()`. This will keep the object alive until you are no longer referencing the object in Lua. `self:release()` is automatically called when Lua is no longer referencing the object anywhere.

唯一需要手动调用`self:add_ref()`和`self:release()`的情况是当引擎返回新创建的对象时，例如数组或`sdk.create_instance()`创建的对象。
The only time you will need to manually call `self:add_ref()` and `self:release()` is when a newly created object is returned by the engine, e.g. an array, or something from `sdk.create_instance()`.

更详细的解释可以在Capcom的这个GDC演示的"FrameGC Algorithm"部分找到：
A more in-depth explanation can be found in the "FrameGC Algorithm" section of this GDC presentation by Capcom:

https://github.com/kasicass/blog/blob/master/3d-reengine/2021_03_10_achieve_rapid_iteration_re_engine_design.md#framegc-algorithm-17

### `self:read_byte(offset)`
读取一个字节。

### `self:read_short(offset)`
读取一个短整型值。

### `self:read_dword(offset)`
读取一个双字值。

### `self:read_qword(offset)`
读取一个四字值。

### `self:read_float(offset)`
读取一个浮点值。

### `self:read_double(offset)`
读取一个双精度浮点值。

### `self:write_byte(offset, value)`
写入一个字节。

### `self:write_short(offset, value)`
写入一个短整型值。

### `self:write_dword(offset, value)`
写入一个双字值。

### `self:write_qword(offset, value)`
写入一个四字值。

### `self:write_float(offset, value)`
写入一个浮点值。

### `self:write_double(offset, value)`
写入一个双精度浮点值。
