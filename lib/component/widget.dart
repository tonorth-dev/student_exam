import 'dart:async';
import 'dart:ui';

import 'package:hongshi_admin/app/home/head/logic.dart';
import 'package:hongshi_admin/ex/ex_hint.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:searchfield/searchfield.dart';
import '../api/config_api.dart';
import '../theme/table_text_style.dart';

class CustomButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final double width;
  final double height;

  const CustomButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.width = 90, // 默认宽度
    this.height = 32, // 默认高度
  }) : super(key: key);

  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  final ValueNotifier<bool> _isHovered = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _isHovered.value = true,
      onExit: (_) => _isHovered.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isHovered,
        builder: (context, isHovered, _) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 100),
            width: widget.width,
            height: widget.height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isHovered ? Color(0xFF25B7E8) : Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                )
              ],
            ),
            child: TextButton(
              onPressed: widget.onPressed,
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                foregroundColor: MaterialStateProperty.all(Colors.transparent),
                backgroundColor: MaterialStateProperty.all(Colors.transparent),
              ),
              child: Center(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: isHovered ? Colors.white : Color(0xFF423F3F),
                    fontSize: 14,
                    fontFamily: 'PingFang SC',
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _isHovered.dispose();
    super.dispose();
  }
}

class ButtonState with ChangeNotifier {
  bool _isHovered = false;

  bool get isHovered => _isHovered;

  void setHovered(bool value) {
    _isHovered = value;
    notifyListeners();
  }
}

class DropdownField extends StatefulWidget {
  final double width;
  final double height;
  final String hint;
  final bool? label;
  final List<Map<String, dynamic>> items; // 修改为 Map 列表
  final ValueNotifier<String?> selectedValue; // 使用 ValueNotifier 来管理选中的值
  final void Function(String?)? onChanged; // 修改为 String? 类型

  const DropdownField({
    Key? key,
    required this.width,
    required this.height,
    required this.hint,
    required this.items,
    required this.selectedValue, // 必须传入一个 ValueNotifier
    this.label,
    this.onChanged,
  }) : super(key: key);

  @override
  DropdownFieldState createState() => DropdownFieldState();
}

class DropdownFieldState extends State<DropdownField>
    with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  final ValueNotifier<bool> _isHovered = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.selectedValue
        .addListener(_updateSelectedValue); // 监听 selectedValue 的变化
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _isHovered.value = false;
    }
    setState(() {});
  }

  void _updateSelectedValue() {
    // 当 selectedValue 变化时更新 UI
    setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _isHovered.dispose();
    widget.selectedValue.removeListener(_updateSelectedValue); // 移除监听
    super.dispose();
  }

  void reset() {
    setState(() {
      widget.selectedValue.value = null;
    });
    widget.onChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: MouseRegion(
        onEnter: (_) => _isHovered.value = true,
        onExit: (_) => _isHovered.value = false,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isHovered,
          builder: (context, isHovered, _) {
            // 确保 selectedValue 存在于 items 中
            final hasSelectedValue = widget.items
                .any((item) => item['id'] == widget.selectedValue.value);
            final effectiveValue =
            hasSelectedValue ? widget.selectedValue.value : null;

            // 添加重置选项到 items 列表
            final itemsWithReset = [
              ...widget.items,
              {'id': '', 'name': '清空选择'}
            ];

            return SizedBox(
              width: widget.width,
              height: widget.height,
              child: DropdownButtonFormField<String>(
                focusNode: _focusNode,
                value: effectiveValue,
                hint: effectiveValue == null ? Text(widget.hint) : null,
                onChanged: (String? newValue) {
                  if (newValue == 'reset') {
                    reset(); // 如果选择了重置选项，则调用 reset 方法
                  } else {
                    widget.selectedValue.value = newValue; // 更新 selectedValue
                    if (widget.onChanged != null) {
                      widget.onChanged!(newValue);
                    }
                  }
                },
                items: itemsWithReset.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['id'],
                    child: Text(
                      item['name'], // 显示的值是 name
                      style: const TextStyle(
                        color: Color(0xFF505050),
                        fontSize: 14,
                        fontFamily: 'PingFang SC',
                        fontWeight: FontWeight.w400,
                        height: 1,
                      ),
                    ),
                  );
                }).toList(),
                style: const TextStyle(
                  color: Color(0xFF505050),
                  fontSize: 14,
                  fontFamily: 'PingFang SC',
                  fontWeight: FontWeight.w400,
                  height: 1,
                ),
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  labelText: widget.label == true ? widget.hint : null,
                  labelStyle: const TextStyle(
                    color: Color(0xFF505050),
                    fontSize: 14,
                    fontFamily: 'PingFang SC',
                    fontWeight: FontWeight.w400,
                  ),
                  hintStyle: const TextStyle(
                    color: Color(0xFF505050),
                    fontSize: 14,
                    fontFamily: 'PingFang SC',
                    fontWeight: FontWeight.w400,
                  ),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide:
                    const BorderSide(color: Colors.grey, width: 1.0), // 非聚焦边框
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide:
                    const BorderSide(color: Colors.grey, width: 1.0), // 聚焦边框
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  // 背景填充色
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CascadingDropdownField extends StatefulWidget {
  final List<Map<String, dynamic>> level1Items;
  final Map<String, List<Map<String, dynamic>>> level2Items;
  final Map<String, List<Map<String, dynamic>>> level3Items;
  final String hint1;
  final String hint2;
  final String hint3;
  final double width;
  final double height;
  final ValueNotifier<dynamic> selectedLevel1;
  final ValueNotifier<dynamic> selectedLevel2;
  final ValueNotifier<dynamic> selectedLevel3;
  final void Function(dynamic, dynamic, dynamic)? onChanged;
  final Axis axis; // 新增参数，控制布局方向

  const CascadingDropdownField({
    Key? key,
    required this.level1Items,
    required this.level2Items,
    required this.level3Items,
    required this.hint1,
    required this.hint2,
    required this.hint3,
    this.width = 150,
    this.height = 34,
    required this.selectedLevel1,
    required this.selectedLevel2,
    required this.selectedLevel3,
    this.onChanged,
    this.axis = Axis.horizontal, // 默认横向排列
  }) : super(key: key);

  @override
  CascadingDropdownFieldState createState() => CascadingDropdownFieldState();
}

class CascadingDropdownFieldState extends State<CascadingDropdownField> {
  late TextEditingController _level1Controller;
  late TextEditingController _level2Controller;
  late TextEditingController _level3Controller;

  late FocusNode _level1FocusNode;
  late FocusNode _level2FocusNode;
  late FocusNode _level3FocusNode;

  @override
  void initState() {
    super.initState();
    _level1Controller = TextEditingController();
    _level2Controller = TextEditingController();
    _level3Controller = TextEditingController();

    _level1FocusNode = FocusNode();
    _level2FocusNode = FocusNode();
    _level3FocusNode = FocusNode();

    _updateControllers();
    widget.selectedLevel1.addListener(_updateControllers);
    widget.selectedLevel2.addListener(_updateControllers);
    widget.selectedLevel3.addListener(_updateControllers);
  }

  void _updateControllers() {
    setState(() {
      _level1Controller.text =
          _getNameById(widget.level1Items, widget.selectedLevel1.value);
      _level2Controller.text = _getNameById(
          widget.level2Items[widget.selectedLevel1.value.toString()] ?? [],
          widget.selectedLevel2.value);
      _level3Controller.text = _getNameById(
          widget.level3Items[widget.selectedLevel2.value.toString()] ?? [],
          widget.selectedLevel3.value);
    });
  }

  String _getNameById(List<Map<String, dynamic>> items, dynamic id) {
    final item =
        items.firstWhere((element) => element['id'] == id, orElse: () => {});
    return item['name'] ?? '';
  }

  void reset() {
    widget.selectedLevel1.value = null;
    widget.selectedLevel2.value = null;
    widget.selectedLevel3.value = null;
    _level1Controller.clear();
    _level2Controller.clear();
    _level3Controller.clear();
    widget.onChanged?.call(null, null, null);
  }

  void _onLevel1Changed(Map<String, dynamic> newValue) {
    widget.selectedLevel1.value = newValue['id'];
    _level1Controller.text = newValue['name'];
    widget.selectedLevel2.value = null;
    widget.selectedLevel3.value = null;
    _level2Controller.clear();
    _level3Controller.clear();
    widget.onChanged?.call(widget.selectedLevel1.value,
        widget.selectedLevel2.value, widget.selectedLevel3.value);
  }

  void _onLevel2Changed(Map<String, dynamic> newValue) {
    widget.selectedLevel2.value = newValue['id'];
    _level2Controller.text = newValue['name'];
    widget.selectedLevel3.value = null;
    _level3Controller.clear();
    widget.onChanged?.call(widget.selectedLevel1.value,
        widget.selectedLevel2.value, widget.selectedLevel3.value);
  }

  void _onLevel3Changed(Map<String, dynamic> newValue) {
    widget.selectedLevel3.value = newValue['id'];
    _level3Controller.text = newValue['name'];
    widget.onChanged?.call(widget.selectedLevel1.value,
        widget.selectedLevel2.value, widget.selectedLevel3.value);
  }

  @override
  Widget build(BuildContext context) {
    return widget.axis == Axis.horizontal
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _buildDropdownFields(),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildDropdownFields(),
          );
  }

  List<Widget> _buildDropdownFields() {
    return [
      _buildTypeAheadField(
        controller: _level1Controller,
        focusNode: _level1FocusNode,
        hint: widget.hint1,
        items: widget.level1Items,
        onSuggestionSelected: _onLevel1Changed,
      ),
      SizedBox(
          width: widget.axis == Axis.horizontal ? 5 : 0,
          height: widget.axis == Axis.vertical ? 5 : 0),
      _buildTypeAheadField(
        controller: _level2Controller,
        focusNode: _level2FocusNode,
        hint: widget.hint2,
        items: widget.selectedLevel1.value != null
            ? widget.level2Items[widget.selectedLevel1.value.toString()] ?? []
            : [],
        onSuggestionSelected: _onLevel2Changed,
      ),
      SizedBox(
          width: widget.axis == Axis.horizontal ? 5 : 0,
          height: widget.axis == Axis.vertical ? 5 : 0),
      _buildTypeAheadField(
        controller: _level3Controller,
        focusNode: _level3FocusNode,
        hint: widget.hint3,
        items: widget.selectedLevel2.value != null
            ? widget.level3Items[widget.selectedLevel2.value.toString()] ?? []
            : [],
        onSuggestionSelected: _onLevel3Changed,
      ),
    ];
  }

  Widget _buildTypeAheadField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required List<Map<String, dynamic>> items,
    required Function(Map<String, dynamic>) onSuggestionSelected,
  }) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: TypeAheadField<Map<String, dynamic>>(
        textFieldConfiguration: TextFieldConfiguration(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(
            color: Color(0xFF505050),
            fontSize: 14,
            fontFamily: 'PingFang SC',
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            labelText: hint,
            labelStyle: const TextStyle(
              color: Color(0xFF505050),
              fontSize: 14,
              fontFamily: 'PingFang SC',
              fontWeight: FontWeight.w400,
            ),
            hintStyle: const TextStyle(
              color: Color(0xFF505050),
              fontSize: 14,
              fontFamily: 'PingFang SC',
              fontWeight: FontWeight.w400,
            ),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide:
                  const BorderSide(color: Colors.grey, width: 1.0), // 非聚焦边框
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide:
                  const BorderSide(color: Colors.grey, width: 1.0), // 聚焦边框
            ),
            filled: true,
            fillColor: Colors.white,
            // 背景填充色
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        suggestionsCallback: (pattern) {
          if (pattern.isEmpty) return items;
          return items
              .where((item) =>
                  item['name'].toLowerCase().contains(pattern.toLowerCase()))
              .toList();
        },
        itemBuilder: (context, suggestion) {
          return ListTile(
            title: Text(
              suggestion['name'],
              style: const TextStyle(
                color: Color(0xFF505050),
                fontSize: 14,
                fontFamily: 'PingFang SC',
                fontWeight: FontWeight.w400,
              ),
            ),
          );
        },
        onSuggestionSelected: onSuggestionSelected,
        noItemsFoundBuilder: (context) => const Center(
          child: Text(
            'No items found',
            style: TextStyle(
              color: Color(0xFF505050),
              fontSize: 14,
              fontFamily: 'PingFang SC',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _level1Controller.dispose();
    _level2Controller.dispose();
    _level3Controller.dispose();
    _level1FocusNode.dispose();
    _level2FocusNode.dispose();
    _level3FocusNode.dispose();
    widget.selectedLevel1.removeListener(_updateControllers);
    widget.selectedLevel2.removeListener(_updateControllers);
    widget.selectedLevel3.removeListener(_updateControllers);
    super.dispose();
  }
}

class SearchBoxWidget extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onTextChanged;
  final RxString searchText;
  final String buttonText; // 按钮文字
  final double width; // 搜索框宽度
  final double height; // 搜索框高度

  const SearchBoxWidget({
    Key? key,
    required this.hint,
    required this.onTextChanged,
    required this.searchText,
    this.buttonText = "查询", // 默认按钮文字
    this.width = 160, // 默认宽度
    this.height = 34, // 默认高度
  }) : super(key: key);

  @override
  _SearchBoxWidgetState createState() => _SearchBoxWidgetState();
}

class _SearchBoxWidgetState extends State<SearchBoxWidget> {
  late TextEditingController _controller;
  late Worker _worker; // 用于监听 RxString 的变化

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchText.value);

    // Worker 只在 searchText 真正发生变化时更新 controller
    _worker = ever(widget.searchText, (String value) {
      if (_controller.text != value) {
        _controller.text = value;
        _controller.selection = TextSelection.collapsed(offset: value.length);
      }
    });
  }

  @override
  void dispose() {
    _worker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onExit: (event) {
        widget.searchText.value = _controller.text;
      },
      child: Row(
        children: [
          SizedBox(
            height: widget.height,
            width: widget.width,
            child: TextField(
              key: const Key('search_box'),
              controller: _controller,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: 'PingFang SC',
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onEditingComplete: () {
                widget.searchText.value = _controller.text;
              },
              onSubmitted: (value) {
                widget.onTextChanged(value);
                widget.searchText.value = value;
              },
            ),
          )
        ],
      ),
    );
  }
}

class SearchButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const SearchButtonWidget({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 34,
      decoration: ShapeDecoration(
        color: Color(0xFFD43030),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          '查询',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'PingFang SC',
            fontWeight: FontWeight.w400,
            height: 0.09,
          ),
        ),
      ),
    );
  }
}

class ResetButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const ResetButtonWidget({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 34,
      decoration: ShapeDecoration(
        color: Color(0x80706f6d),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          '重置',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'PingFang SC',
            fontWeight: FontWeight.w400,
            height: 0.09,
          ),
        ),
      ),
    );
  }
}

class SearchAndButtonWidget extends StatelessWidget {
  final String hint;
  final VoidCallback onSearch;

  const SearchAndButtonWidget(
      {Key? key, required this.onSearch, required this.hint})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 6),
          SizedBox(
            height: 34,
            width: 120,
            child: TextField(
              key: const Key('search_box'),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: 'PingFang SC',
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (value) => onSearch(),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 80,
            height: 34,
            decoration: ShapeDecoration(
              color: Color(0xFFD43030),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(width: 1, color: Colors.grey),
              ),
            ),
            child: TextButton(
              onPressed: onSearch,
              child: Text(
                '搜索',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'PingFang SC',
                  fontWeight: FontWeight.w400,
                  height: 0.09,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TextInputWidget extends StatefulWidget {
  final String hint; // 提示文本
  final ValueChanged<String> onTextChanged; // 输入变化时的回调
  final RxString text; // 用于绑定和监听的文本
  final double width; // 动态宽度
  final double height; // 动态高度
  final int maxLines; // 最大行数
  final FormFieldValidator<String>? validator; // 验证器

  const TextInputWidget({
    Key? key,
    required this.hint,
    required this.onTextChanged,
    required this.text,
    this.width = 120, // 默认宽度为120
    this.height = 40, // 默认高度为40
    this.maxLines = 1, // 默认单行输入
    this.validator, // 验证器
  }) : super(key: key);

  @override
  _TextInputWidgetState createState() => _TextInputWidgetState();
}

class _TextInputWidgetState extends State<TextInputWidget> {
  late TextEditingController _controller;
  String? _errorText; // 用于存储错误信息

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 手动触发验证
  void validate() {
    setState(() {
      _errorText = widget.validator?.call(_controller.text); // 更新错误信息
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height, // 动态高度
      width: widget.width, // 动态宽度
      child: Obx(() {
        // 同步 RxString 和 TextEditingController 的内容
        if (_controller.text != widget.text.value) {
          _controller.text = widget.text.value;
          _controller.selection =
              TextSelection.collapsed(offset: _controller.text.length);
        }

        return TextFormField(
          key: const Key('text_input_box'),
          // 唯一Key
          style: TextStyle(
            color: Color(0xFF505050),
            fontSize: 14,
            fontFamily: 'PingFang SC',
            fontWeight: FontWeight.w400,
          ),
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hint,
            // 提示文本
            hintStyle: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 12,
              fontFamily: 'PingFang SC',
              fontWeight: FontWeight.w400,
            ),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide:
                  const BorderSide(color: Colors.grey, width: 1.0), // 非聚焦边框
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide:
                  const BorderSide(color: Colors.grey, width: 1.0), // 聚焦边框
            ),
            filled: true,
            fillColor: Colors.white,
            // 背景填充色
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            suffix: _errorText != null && _errorText!.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(left: 8.0), // 左侧间距
                    child: Text(
                      _errorText!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _errorText = widget.validator?.call(value); // 更新错误信息
            });

            if (widget.text.value != value) {
              widget.text.value = value; // 更新 RxString
              widget.onTextChanged(value); // 输入变化时回调
            }
          },
          maxLines: widget.maxLines, // 设置最大行数
        );
      }),
    );
  }
}

class NumberInputWidget extends StatefulWidget {
  final String hint;
  final RxInt selectedValue;
  final double width;
  final double height;
  final ValueChanged<int> onValueChanged;
  final Key key;

  NumberInputWidget({
    required this.key,
    required this.hint,
    required this.selectedValue,
    required this.width,
    required this.height,
    required this.onValueChanged,
  });

  @override
  _NumberInputWidgetState createState() => _NumberInputWidgetState();
}

class _NumberInputWidgetState extends State<NumberInputWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  OverlayEntry? _overlayEntry;
  GlobalKey _inputKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selectedValue.value.toString());
    _focusNode = FocusNode();

    widget.selectedValue.listen((value) {
      if (_controller.text != value.toString()) {
        _controller.text = value.toString();
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    });

    _controller.addListener(() {
      final text = _controller.text.isEmpty ? '0' : _controller.text;
      final value = int.tryParse(text) ?? 0;
      widget.selectedValue.value = value;
      widget.onValueChanged(value);
      _removeOverlay();
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        RawKeyboard.instance.addListener(_handleKeyEvent);
      } else {
        RawKeyboard.instance.removeListener(_handleKeyEvent);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    _removeOverlay();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final value = widget.selectedValue.value;
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          widget.selectedValue.value += 1;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          widget.selectedValue.value = (value - 1).clamp(0, double.infinity).toInt();
        });
      }
      _controller.text = widget.selectedValue.value.toString();
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      widget.onValueChanged(widget.selectedValue.value);
    }
  }

  void _showNumberPicker() {
    _removeOverlay(); // Remove existing overlay before showing a new one
    final RenderBox renderBox = _inputKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeOverlay, // Close the overlay when tapping outside
              ),
            ),
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height,
              width: 100,
              child: Material(
                elevation: 8.0,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: 20,
                  itemBuilder: (context, index) {
                    final value = index;
                    return InkWell(
                      onTap: () {
                        widget.selectedValue.value = value;
                        _controller.text = value.toString();
                        _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: _controller.text.length),
                        );
                        widget.onValueChanged(value);
                        _removeOverlay(); // Close the overlay after selection
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Text(value.toString(), style: TextStyle(fontSize: 14)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context)?.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: TextField(
        key: _inputKey,
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(
            color: Color(0xFF999999),
            fontSize: 12,
            fontFamily: 'PingFang SC',
            fontWeight: FontWeight.w400,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide(color: Colors.grey, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide(color: Colors.grey, width: 1.0),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          suffixIconConstraints: BoxConstraints(
            minWidth: 24,
            minHeight: 24,
          ),
          suffixIcon: GestureDetector(
            onTap: () {
              _removeOverlay(); // Ensure any existing overlay is removed
              _showNumberPicker();
            },
            behavior: HitTestBehavior.translucent,
            child: Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: Color(0xFF505050),
            ),
          ),
        ),
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF505050),
        ),
        onChanged: (text) {
          if (text.isEmpty) {
            _controller.text = '0';
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
            widget.selectedValue.value = 0;
            widget.onValueChanged(0);
          }
        },
      ),
    );
  }
}

class SelectableList extends StatefulWidget {
  final Key key;
  final RxList<Map<String, dynamic>> items;
  final Future<void> Function(Map<String, dynamic>) onDelete;
  final Function(Map<String, dynamic>) onSelected;

  SelectableList({
    required this.key,
    required this.items,
    required this.onDelete,
    required this.onSelected,
  }) : super(key: key);

  @override
  SelectableListState createState() => SelectableListState();
}

class SelectableListState extends State<SelectableList> {
  int selectedIndex = -1; // 初始化为 -1 表示没有选中项

  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        return ListView.builder(
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            return InkWell(
              // 使用 InkWell 包裹整个 Card
              onTap: () {
                setState(() {
                  selectedIndex = index;
                  widget.onSelected(item); // 调用 onSelected 回调并传递 item
                });
                refresh(); // 强制刷新列表
              },
              child: Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0), // 增大圆角
                ),
                color: selectedIndex == index
                    ? Colors.blueGrey[200]
                    : Colors.white,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: ListTile(
                    enableFeedback: false, // 禁用点击动效
                    dense: true, // 使 ListTile 更紧凑
                    title: Text(item['name'] ?? ''),
                    trailing: PopupMenuButton<String>(
                      onSelected: (String value) {
                        if (value == "Edit") {
                          _editItem(index);
                        } else if (value == "Delete") {
                          _confirmDelete(index);
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: "Edit",
                          child: Text("编辑"),
                        ),
                        PopupMenuItem<String>(
                          value: "Delete",
                          child: Text("删除"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _editItem(int index) {
    showDialog(
      context: context,
      builder: (context) {
        final item = widget.items[index];
        TextEditingController _controller =
            TextEditingController(text: item['name']);
        return AlertDialog(
          title: Text("编辑项目"),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: "项目名称"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("取消"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  widget.items[index]['name'] = _controller.text;
                });
                Navigator.of(context).pop();
                refresh(); // 编辑完成后刷新列表
              },
              child: Text("保存"),
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(int index) async {
    final item = widget.items[index];
    try {
      await widget.onDelete(item); // 调用 onDelete 回调并传递 item
      setState(() {
        widget.items.removeAt(index);
        if (selectedIndex >= widget.items.length) {
          selectedIndex = -1; // 如果删除的是最后一个项，重置选中状态
        } else if (selectedIndex == index) {
          selectedIndex = -1; // 如果删除的是当前选中的项，重置选中状态
        }
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("删除成功")));
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("删除失败: $error")));
    }
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("确认删除"),
          content: Text("确定要删除这个项目吗？"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("取消"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteItem(index);
              },
              child: Text("删除"),
            ),
          ],
        );
      },
    );
  }
}

class SingleSelectForm extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>) onSelected;
  final int? defaultSelectedId; // 默认选中的 ID

  const SingleSelectForm({
    Key? key,
    required this.items,
    required this.onSelected,
    this.defaultSelectedId, // 可选参数
  }) : super(key: key);

  @override
  _SingleSelectFormState createState() => _SingleSelectFormState();
}

class _SingleSelectFormState extends State<SingleSelectForm> {
  int? selectedId; // 当前选中的 ID

  @override
  void initState() {
    super.initState();
    // 根据默认选中的 ID 初始化
    selectedId = widget.defaultSelectedId;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: widget.items.map((item) {
        final itemId = item['id'];

        return Expanded(
          child: RadioListTile<int>(
            value: itemId,
            groupValue: selectedId,
            onChanged: (int? value) {
              if (value != null) {
                setState(() {
                  selectedId = value;
                  widget.onSelected(item);
                  print("选中值: ${item['name']}"); // 调试日志
                });
              }
            },
            title: Text(
              item['name'] ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            dense: true, // 紧凑布局
          ),
        );
      }).toList(),
    );
  }
}

class HoverTextButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final bool enabled;
  final TextStyle? style;

  HoverTextButton({
    required this.text,
    this.onTap,
    this.enabled = true,
    this.style,
  });

  @override
  _HoverTextButtonState createState() => _HoverTextButtonState();
}

class _HoverTextButtonState extends State<HoverTextButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.enabled ? widget.onTap : null,
        child: Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: _isHovered && widget.enabled
                ? Colors.grey[200]
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.0), // 可以根据需要调整圆角
          ),
          child: Text(
            widget.text,
            style: widget.style ??
                TextStyle(
                  color: _isHovered && widget.enabled
                      ? Colors.red
                      : Color(0xFFFD941D),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'PingFang SC',
                ),
          ),
        ),
      ),
    );
  }
}

class ProvinceCityDistrictSelector extends StatefulWidget {
  final String? defaultProvince;
  final String? defaultCity;
  final String? defaultDistrict;
  final Function(String?, String?, String?)? onChanged;

  ProvinceCityDistrictSelector({
    this.defaultProvince,
    this.defaultCity,
    this.defaultDistrict,
    this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  ProvinceCityDistrictSelectorState createState() =>
      ProvinceCityDistrictSelectorState();
}

class ProvinceCityDistrictSelectorState
    extends State<ProvinceCityDistrictSelector> {
  final ValueNotifier<String?> selectedProvince = ValueNotifier(null);
  final ValueNotifier<String?> selectedCity = ValueNotifier(null);
  final ValueNotifier<String?> selectedDistrict = ValueNotifier(null);

  List<Map<String, dynamic>>? provinces;
  Map<String, List<Map<String, dynamic>>> cities = {};
  Map<String, List<Map<String, dynamic>>> counties = {};

  Future<List<Map<String, dynamic>>> fetchDivisions({
    required String level,
    String? parentId,
  }) async {
    try {
      var areaData = await ConfigApi.configArea("area", level, parentId);

      List<Map<String, dynamic>> divisions = (areaData as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();

      return divisions;
    } catch (e) {
      print('Error fetching divisions: $e');
      rethrow;
    }
    return [];
  }

  Future<void> fetchProvinces() async {
    try {
      provinces = await fetchDivisions(level: "province");
      setState(() {});
    } catch (e) {
      print('Failed to load provinces: $e');
    }
  }

  Future<void> fetchCities(String provinceId) async {
    try {
      cities[provinceId] =
          await fetchDivisions(level: "city", parentId: provinceId);
      setState(() {});
    } catch (e) {
      print('Failed to load cities: $e');
    }
  }

  Future<void> fetchCounties(String cityId) async {
    try {
      counties[cityId] =
          await fetchDivisions(level: "county", parentId: cityId);
      setState(() {});
    } catch (e) {
      print('Failed to load counties: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProvinces();
    if (widget.defaultProvince != null) {
      selectedProvince.value = widget.defaultProvince;
      fetchCities(widget.defaultProvince!);
      if (widget.defaultCity != null) {
        selectedCity.value = widget.defaultCity;
        fetchCounties(widget.defaultCity!);
        if (widget.defaultDistrict != null) {
          selectedDistrict.value = widget.defaultDistrict;
        }
      }
    }
  }

  void reset() {
    if (!mounted) return; // 避免组件未初始化时调用
    setState(() {
      selectedProvince.value = null;
      selectedCity.value = null;
      selectedDistrict.value = null;
      cities.clear();
      counties.clear();
      fetchProvinces();
    });
    // 显式调用 onChanged 通知外部
    widget.onChanged?.call(null, null, null);
  }

  Widget buildDropdown({
    required ValueNotifier<String?> valueNotifier,
    required List<Map<String, dynamic>>? items,
    required void Function(String?)? onChanged,
    required String hintText,
    bool isEnabled = true,
  }) {
    return ValueListenableBuilder<String?>(
      valueListenable: valueNotifier,
      builder: (context, value, child) {
        return Container(
          width: 140,
          height: 34,
          decoration: BoxDecoration(
            border: Border.all(
              color: isEnabled ? Colors.grey : Colors.grey[300]!,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: DropdownButtonHideUnderline(
            child: Padding(
              padding: EdgeInsets.only(left: 0.0),
              child: DropdownButton<String>(
                value: value,
                items: items?.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['id'],
                    child: Text(
                      item['name'],
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: Colors.grey[900]),
                    ),
                  );
                }).toList(),
                onChanged: isEnabled
                    ? (newValue) {
                        onChanged?.call(newValue); // 内部更新
                        widget.onChanged?.call(
                          selectedProvince.value,
                          selectedCity.value,
                          selectedDistrict.value,
                        ); // 通知外部
                      }
                    : null,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down),
                hint: Text(hintText,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        buildDropdown(
          valueNotifier: selectedProvince,
          items: provinces,
          onChanged: (newValue) {
            setState(() {
              selectedProvince.value = newValue;
              selectedCity.value = null;
              selectedDistrict.value = null;
              cities.clear();
              counties.clear();
              if (newValue != null) fetchCities(newValue);
            });
          },
          hintText: '请选择省份',
          isEnabled: provinces != null,
        ),
        SizedBox(width: 1),
        buildDropdown(
          valueNotifier: selectedCity,
          items: selectedProvince.value != null
              ? cities[selectedProvince.value!]
              : null,
          onChanged: (newValue) {
            setState(() {
              selectedCity.value = newValue;
              selectedDistrict.value = null;
              counties.clear();
              if (newValue != null) fetchCounties(newValue);
            });
          },
          hintText: '请选择城市',
          isEnabled: selectedProvince.value != null,
        ),
        SizedBox(width: 1),
        // buildDropdown(
        //   valueNotifier: selectedDistrict,
        //   items: selectedCity.value != null
        //       ? counties[selectedCity.value!]
        //       : null,
        //   onChanged: (newValue) {
        //     setState(() {
        //       selectedDistrict.value = newValue;
        //     });
        //   },
        //   hintText: '请选择区县',
        //   isEnabled: selectedCity.value != null,
        // ),
      ],
    );
  }
}

class SuggestionTextField extends StatefulWidget {
  final String labelText;
  final String hintText;
  final double width; // 输入框宽度
  final double height; // 输入框高度
  final ValueListenable<Map?> initialValue; // 外部值监听器
  final Future<List<Map<String, dynamic>>> Function(String query) fetchSuggestions; // 支持 Map 类型
  final ValueChanged<Map>? onSelected; // 选择后的回调
  final ValueChanged<Map?>? onChanged; // 输入或重置后的回调

  const SuggestionTextField({
    Key? key,
    required this.labelText,
    required this.hintText,
    required this.width,
    required this.height,
    required this.initialValue,
    required this.fetchSuggestions,
    this.onSelected,
    this.onChanged,
  }) : super(key: key);

  @override
  SuggestionTextFieldState createState() => SuggestionTextFieldState();
}

class SuggestionTextFieldState extends State<SuggestionTextField> {
  late TextEditingController _textController;
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();

    // 监听外部值变化并更新文本控制器
    widget.initialValue.addListener(() {
      final newValue = widget.initialValue.value;
      if (newValue != null && newValue['name'] != null) {
        _textController.text = newValue['name'];
        setState(() {});
      }
    });

    // 初始化文本控制器
    final initialValue = widget.initialValue.value;
    if (initialValue != null && initialValue['name'] != null) {
      _textController.text = initialValue['name'];
    }

    _fetchSuggestions('');
  }

  Future<void> _fetchSuggestions(String query) async {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final results = await widget.fetchSuggestions(query);
      setState(() {
        _suggestions = results;
      });
    });
  }

  void reset() {
    setState(() {
      _textController.clear();
      _suggestions = [];
    });

    // 调用 onChanged 回调，传递 null 表示已重置
    widget.onChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map?>(
      valueListenable: widget.initialValue,
      builder: (context, value, child) {
        return Padding(
          padding: const EdgeInsets.only(left: 0, right: 0, top: 8, bottom: 8),
          child: SizedBox(
            height: 34, // 设置输入框的固定高度
            child: SearchField(
              dynamicHeight: true,
              controller: _textController,
              itemHeight: widget.height,
              scrollbarDecoration: ScrollbarDecoration(
                thickness: 2,
              ),
              suggestionStyle: TextStyle(fontSize: 14, color: Colors.grey[900]),
              searchInputDecoration: SearchInputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 12,
                  fontFamily: 'PingFang SC',
                  fontWeight: FontWeight.w400,
                ),
                cursorHeight: 14,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3), // 圆角
                  borderSide: BorderSide(color: Colors.grey, width: 1.0), // 失焦状态边框颜色
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3), // 圆角
                  borderSide: BorderSide(color: Colors.grey, width: 1.0), // 聚焦状态边框颜色
                ),
                filled: true,
                fillColor: Colors.white,
                searchStyle: const TextStyle(
                  color: Color(0xFF505050),
                  fontSize: 14,
                  fontFamily: 'PingFang SC',
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              ),
              suggestions: _suggestions.map((item) {
                return SearchFieldListItem(item['name'], item: item);
              }).toList(),
              suggestionState: Suggestion.expand,
              textInputAction: TextInputAction.search,
              onSuggestionTap: (SearchFieldListItem selection) {
                debugPrint('Selected: ${selection.item}');
                _textController.text = selection.item['name'] as String;

                // 调用父组件提供的回调
                widget.onSelected?.call(selection.item);
                widget.onChanged?.call(selection.item);
              },
              onSubmit: (_) async {
                await _fetchSuggestions(_textController.text);
              },
              onSearchTextChanged: (String value) {
                // 防抖处理
                _fetchSuggestions(value);

                if (value.isEmpty) {
                  widget.onChanged?.call(null);
                } else {
                  widget.onChanged?.call({'name': value});
                }
              },
              onTap: () async {
                _fetchSuggestions("");
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}

class TagInputField extends StatefulWidget {
  final List<String> defaultTags;
  final Future<String?> Function(String)? onTagModifyAsync;
  final Future<void> Function(List<String> tags)? onTagsUpdated;
  final String hintText;
  final double? width;
  final double? height;

  const TagInputField({
    Key? key,
    this.defaultTags = const [],
    this.onTagModifyAsync,
    this.onTagsUpdated,
    this.hintText = '请输入专业ID，按回车或逗号确认，最多可一次性添加三个',
    this.width,
    this.height,
  }) : super(key: key);

  @override
  _TagInputFieldState createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _tags = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tags.addAll(widget.defaultTags);
  }

  Future<void> _addTag(String value) async {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? modifiedTag = trimmedValue;

      // 调用异步方法修改标签
      if (widget.onTagModifyAsync != null) {
        modifiedTag = await widget.onTagModifyAsync!(trimmedValue);
      }

      if (modifiedTag == null || modifiedTag.isEmpty) {
        _showErrorMessage("请输入正确的专业ID");
        return;
      }

      // 检查标签是否已存在，避免重复
      if (_tags.contains(modifiedTag)) {
        _showErrorMessage("标签已存在");
        return;
      }

      // 临时生成一个新标签列表，包含当前标签
      final List<String> tempTags = List.from(_tags)..add(modifiedTag);

      // 在添加之前验证标签数量
      if (widget.onTagsUpdated != null) {
        await widget.onTagsUpdated!(tempTags).then((_) {
          setState(() {
            _tags.add(modifiedTag!);
          });
        }).catchError((error) {
          _showErrorMessage(error.toString());
        });
      } else {
        // 如果没有 onTagsUpdated 回调，直接添加
        setState(() {
          _tags.add(modifiedTag!);
        });
      }

      _controller.clear();
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _updateTags() async {
    if (widget.onTagsUpdated != null) {
      try {
        // 调用 onTagsUpdated，并等待其执行
        await widget.onTagsUpdated!(_tags);
        // 如果 onTagsUpdated 执行成功，返回 true
        return true;
      } catch (e) {
        // 如果执行失败，返回 false
        _showErrorMessage("添加失败：${e.toString()}");
        return false;
      }
    }
    // 默认返回 true，表示没有更新逻辑
    return true;
  }

  void _showErrorMessage(String message) {
    // 使用扩展方法或其他方式显示错误信息
    message.toHint();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 50.0,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey), // 灰色边框
            borderRadius: BorderRadius.circular(2.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 12,
                      fontFamily: 'PingFang SC',
                      fontWeight: FontWeight.w400,
                    ),
                    isCollapsed: true,
                    // 确保内容对齐
                    contentPadding: EdgeInsets.symmetric(
                      vertical: (widget.height ?? 50.0) / 2 - 10,
                      horizontal: 3.0,
                    ),
                  ),
                  onSubmitted: _addTag,
                  textInputAction: TextInputAction.done,
                ),
              ),
              if (_isLoading) const CircularProgressIndicator(strokeWidth: 2),
            ],
          ),
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _tags
              .map((tag) => Chip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
                        _updateTags();
                      });
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class CustomDateTimePickerController {
  ValueNotifier<String?> _timeNotifier = ValueNotifier<String?>(null);

  CustomDateTimePickerController({String? initialTime}) {
    _timeNotifier.value = initialTime;
  }

  String? get time => _timeNotifier.value;

  Future<void> showPicker(BuildContext context) async {
    final pickedDate = await DateTimePickerWidget.show(
      context: context,
      initialTime: _timeNotifier.value,
    );

    if (pickedDate != null) {
      _timeNotifier.value = _formatDateTime(pickedDate);
    }
  }

  void updateTime(String? newTime) {
    _timeNotifier.value = newTime;
  }

  void dispose() {
    _timeNotifier.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
  }
}

class CustomDateTimePicker extends StatelessWidget {
  final CustomDateTimePickerController controller;
  String hintText;

  CustomDateTimePicker({
    Key? key,
    required this.controller,
    required this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: controller._timeNotifier,
      builder: (context, time, child) {
        return Container(
          width: 200,
          height: 40,
          child:
          TextField(
            onTap: () async {
              await controller.showPicker(context);
            },
            readOnly: true, // 禁止直接编辑文本框
            style: const TextStyle(
              color: Color(0xFF505050),
              fontSize: 14,
              fontFamily: 'PingFang SC',
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              labelText: hintText,
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide:
                const BorderSide(color: Colors.black87, width: 1.0), // 非聚焦边框
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide:
                const BorderSide(color: Colors.black87, width: 1.0), // 聚焦边框
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: () async {
                  await controller.showPicker(context);
                },
              ),
            ),
            controller: TextEditingController(text: time ?? ''), // 使用controller设置TextField的值
          ),
        );
      },
    );
  }
}

class DateTimePickerWidget {
  static Future<DateTime?> show({
    required BuildContext context,
    String? initialTime,
  }) async {
    final DateTime? initialDate = initialTime != null ? DateTime.parse(initialTime) : DateTime.now();
    final DateTime? pickedDate = await showOmniDateTimePicker(
      context: context,
      type: OmniDateTimePickerType.dateAndTime,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
      is24HourMode: true,
      isShowSeconds: false,
      constraints: BoxConstraints(maxWidth: 300), // 限制弹窗的最大宽度
      theme: ThemeData(
        buttonTheme: ButtonThemeData(
          height: 50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.light,
        ),
      ),
    );

    return pickedDate;
  }
}

class StyledTitleText extends StatelessWidget {
  final String data;
  final TextStyle? style;

  const StyledTitleText(this.data, {Key? key, this.style}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      data,
      style: style ?? TableTitleTextStyles.tableTextStyle,
    );
  }
}

class StyledNormalText extends StatelessWidget {
  final String data;
  final TextStyle? style;

  const StyledNormalText(this.data, {Key? key, this.style}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      data,
      style: style ?? TableNormalTextStyles.tableTextStyle,
    );
  }
}
