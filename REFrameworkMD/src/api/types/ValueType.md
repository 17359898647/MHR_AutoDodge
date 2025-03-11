# ValueType文档翻译

未知值类型的容器。
Container for unknown ValueTypes.

## 方法
## Methods
### `ValueType.new(type_definition)`
创建一个新的ValueType实例。

### `self:call(name, args...)`
调用值类型的方法。

### `self:get_field(name)`
获取字段值。

### `self:set_field(name, value)`
设置字段值。
Note that this does not change anything in-game. `ValueType` is just a local copy.

请注意，这不会更改游戏中的任何内容。`ValueType`只是一个本地副本。

您需要将`ValueType`传递给能够使用更改后数据的地方。
You'll need to pass the `ValueType` somewhere that would make use of the changed data.

### `self:address()`
获取地址。

### `self:get_type_definition()`
获取类型定义。

### `self.type`
类型属性。

### `self.data`
数据属性。
`std::vector<uint8_t>`

## 危险方法
## Dangerous Methods
仅在必要时使用这些方法！
Only use these if necessary!

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
