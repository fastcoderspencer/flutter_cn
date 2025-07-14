// 版权所有 2014 The Flutter Authors. 保留所有权利。
// 本源代码的使用受 BSD 风格的许可证约束，该许可证可在
// LICENSE 文件中找到。

/// @docImport 'dart:ui';
///
/// @docImport 'package:flutter/animation.dart';
/// @docImport 'package:flutter/material.dart';
/// @docImport 'package:flutter/widgets.dart';
/// @docImport 'package:flutter_test/flutter_test.dart';
library;

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'binding.dart';
import 'debug.dart';
import 'focus_manager.dart';
import 'inherited_model.dart';
import 'notification_listener.dart';
import 'widget_inspector.dart';

export 'package:flutter/foundation.dart'
    show
        factory,
        immutable,
        mustCallSuper,
        optionalTypeArgs,
        protected,
        required,
        visibleForTesting;
export 'package:flutter/foundation.dart'
    show ErrorDescription, ErrorHint, ErrorSummary, FlutterError, debugPrint, debugPrintStack;
export 'package:flutter/foundation.dart' show DiagnosticLevel, DiagnosticsNode;
export 'package:flutter/foundation.dart' show Key, LocalKey, ValueKey;
export 'package:flutter/foundation.dart' show ValueChanged, ValueGetter, ValueSetter, VoidCallback;
export 'package:flutter/rendering.dart'
    show RenderBox, RenderObject, debugDumpLayerTree, debugDumpRenderTree;

// 示例可以假定：
// late BuildContext context;
// void setState(VoidCallback fn) { }
// abstract class RenderFrogJar extends RenderObject { }
// abstract class FrogJar extends RenderObjectWidget { const FrogJar({super.key}); }
// abstract class FrogJarParentData extends ParentData { late Size size; }
// abstract class SomeWidget extends StatefulWidget { const SomeWidget({super.key}); }
// typedef ChildWidget = Placeholder;
// class _SomeWidgetState extends State<SomeWidget> { @override Widget build(BuildContext context) => widget; }
// abstract class RenderFoo extends RenderObject { }
// abstract class Foo extends RenderObjectWidget { const Foo({super.key}); }
// abstract class StatefulWidgetX { const StatefulWidgetX({this.key}); final Key? key; Widget build(BuildContext context, State state); }
// class SpecialWidget extends StatelessWidget { const SpecialWidget({ super.key, this.handler }); final VoidCallback? handler; @override Widget build(BuildContext context) => this; }
// late Object? _myState, newValue;
// int _counter = 0;
// Future<Directory> getApplicationDocumentsDirectory() async => Directory('');
// late AnimationController animation;

class _DebugOnly {
  const _DebugOnly();
}

/// test_analysis 包使用的一个注解，用于验证是否遵循了
/// 允许对字段及其初始化器进行 tree-shaking 的模式。
/// 此注解本身对代码没有影响，但表明
/// 对于给定字段应遵循以下模式：
///
/// ```dart
/// class Bar {
///   final Object? bar = kDebugMode ? Object() : null;
/// }
/// ```
const _DebugOnly _debugOnly = _DebugOnly();

// 键

/// 一个键，其标识来自用作其值的对象。
///
/// 用于将 widget 的标识与用于
/// 生成该 widget 的对象的标识相关联。
///
/// 另请参阅：
///
///  * [Key]，所有键的基类。
///  * [Widget.key] 处的讨论，以获取有关 widget 如何使用
///    键的更多信息。
class ObjectKey extends LocalKey {
  /// 创建一个键，该键在其 [operator==] 中对 [value] 使用 [identical]。
  const ObjectKey(this.value);

  /// 其标识被此键的 [operator==] 使用的对象。
  final Object? value;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ObjectKey && identical(other.value, value);
  }

  @override
  int get hashCode => Object.hash(runtimeType, identityHashCode(value));

  @override
  String toString() {
    if (runtimeType == ObjectKey) {
      return '[${describeIdentity(value)}]';
    }
    return '[${objectRuntimeType(this, 'ObjectKey')} ${describeIdentity(value)}]';
  }
}

/// 在整个应用程序中唯一的键。
///
/// 全局键唯一地标识元素。全局键提供对与
/// 这些元素关联的其他对象的访问，例如 [BuildContext]。
/// 对于 [StatefulWidget]，全局键还提供对 [State] 的访问。
///
/// 具有全局键的 widget 在从树中的一个位置移动到
/// 树中的另一个位置时会重新挂载其子树。为了
/// 重新挂载其子树，widget 必须在其从旧位置
/// 移除的同一动画帧中到达其在树中的新位置。
///
/// 使用全局键重新挂载 [Element] 的成本相对较高，因为
/// 此操作将触发对关联的
/// [State] 及其所有后代调用 [State.deactivate]；然后强制所有依赖于
/// [InheritedWidget] 的 widget 重建。
///
/// 如果您不需要上面列出的任何功能，请考虑改用 [Key]、
/// [ValueKey]、[ObjectKey] 或 [UniqueKey]。
///
/// 您不能同时在树中包含两个具有相同
/// 全局键的 widget。尝试这样做将在运行时触发断言。
///
/// ## 陷阱
///
/// 不应在每次构建时重新创建 GlobalKey。它们通常应该是
/// 由 [State] 对象拥有的长寿命对象，例如。
///
/// 在每次构建时创建一个新的 GlobalKey 将丢弃与
/// 旧键关联的子树的状态，并为
/// 新键创建一个新的全新子树。除了损害性能外，这还可能导致
/// 子树中的 widget 出现意外行为。例如，
/// 子树中的 [GestureDetector] 将无法跟踪正在进行的手势，因为它将在
/// 每次构建时重新创建。
///
/// 相反，一个好的做法是让 State 对象拥有 GlobalKey，并在
/// build 方法之外实例化它，例如在 [State.initState] 中。
///
/// 另请参阅：
///
///  * [Widget.key] 处的讨论，以获取有关 widget 如何使用
///    键的更多信息。
@optionalTypeArgs
abstract class GlobalKey<T extends State<StatefulWidget>> extends Key {
  /// 创建一个 [LabeledGlobalKey]，它是一个带有用于
  /// 调试的标签的 [GlobalKey]。
  ///
  /// 该标签纯粹用于调试，不用于比较键的
  /// 标识。
  factory GlobalKey({String? debugLabel}) => LabeledGlobalKey<T>(debugLabel);

  /// 创建一个没有标签的全局键。
  ///
  /// 由子类使用，因为工厂构造函数隐藏了隐式
  /// 构造函数。
  const GlobalKey.constructor() : super.empty();

  Element? get _currentElement => WidgetsBinding.instance.buildOwner!._globalKeyRegistry[this];

  /// 带有此键的 widget 在其中构建的构建上下文。
  ///
  /// 如果树中没有与
  /// 此全局键匹配的 widget，则当前上下文为 null。
  BuildContext? get currentContext => _currentElement;

  /// 当前在树中具有此全局键的 widget。
  ///
  /// 如果树中没有与
  /// 此全局键匹配的 widget，则当前 widget 为 null。
  Widget? get currentWidget => _currentElement?.widget;

  /// 树中当前具有此全局键的 widget 的 [State]。
  ///
  /// 如果 (1) 树中没有与
  /// 此全局键匹配的 widget，(2) 该 widget 不是 [StatefulWidget]，或者
  /// 关联的 [State] 对象不是 `T` 的子类型，则当前状态为 null。
  T? get currentState => switch (_currentElement) {
    StatefulElement(:final T state) => state,
    _ => null,
  };
}

/// 带有调试标签的全局键。
///
/// 调试标签对于文档和调试很有用。该标签
/// 不影响键的标识。
@optionalTypeArgs
class LabeledGlobalKey<T extends State<StatefulWidget>> extends GlobalKey<T> {
  /// 创建一个带有调试标签的全局键。
  ///
  /// 该标签不影响键的标识。
  // ignore: prefer_const_constructors_in_immutables , never use const for this class
  LabeledGlobalKey(this._debugLabel) : super.constructor();

  final String? _debugLabel;

  @override
  String toString() {
    final String label = _debugLabel != null ? ' $_debugLabel' : '';
    if (runtimeType == LabeledGlobalKey) {
      return '[GlobalKey#${shortHash(this)}$label]';
    }
    return '[${describeIdentity(this)}$label]';
  }
}

/// 一个全局键，其标识来自用作其值的对象。
///
/// 用于将 widget 的标识与用于
/// 生成该 widget 的对象的标识相关联。
///
/// 为同一对象创建的任何 [GlobalObjectKey] 都将匹配。
///
/// 如果对象不是私有的，则可能会发生冲突，
/// 其中独立的 widget 将在树的不同部分重用同一对象作为其
/// [GlobalObjectKey] 值，从而导致全局
/// 键冲突。为避免此问题，请创建一个私有的 [GlobalObjectKey]
/// 子类，如下所示：
///
/// ```dart
/// class _MyKey extends GlobalObjectKey {
///   const _MyKey(super.value);
/// }
/// ```
///
/// 由于键的 [runtimeType] 是其标识的一部分，因此即使它们具有相同的
/// 值，这也将防止与其他 [GlobalObjectKey] 发生冲突。
@optionalTypeArgs
class GlobalObjectKey<T extends State<StatefulWidget>> extends GlobalKey<T> {
  /// 创建一个全局键，该键在其 [operator==] 中对 [value] 使用 [identical]。
  const GlobalObjectKey(this.value) : super.constructor();

  /// 其标识被此键的 [operator==] 使用的对象。
  final Object value;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is GlobalObjectKey<T> && identical(other.value, value);
  }

  @override
  int get hashCode => identityHashCode(value);

  @override
  String toString() {
    String selfType = objectRuntimeType(this, 'GlobalObjectKey');
    // GlobalObjectKey() 的 runtimeType 字符串返回 'GlobalObjectKey<State<StatefulWidget>>'
    // 因为 GlobalObjectKey 被实例化为其边界。为了避免使输出混乱，
    // 我们删除了后缀。
    const String suffix = '<State<StatefulWidget>>';
    if (selfType.endsWith(suffix)) {
      selfType = selfType.substring(0, selfType.length - suffix.length);
    }
    return '[$selfType ${describeIdentity(value)}]';
  }
}

/// 描述 [Element] 的配置。
///
/// Widget 是 Flutter 框架中的核心类层级。Widget 是用户界面某部分的不可变描述，
/// 可以被扩充为 element 来管理底层的渲染树。
///
/// Widget 本身没有可变状态（所有字段都必须是 final）。如果需要给 widget 关联可变
/// 状态，请考虑使用 [StatefulWidget]。当 widget 被扩充为 element 并合入树中时，
/// 会通过 [StatefulWidget.createState] 创建相应的 [State] 对象。
///
/// 同一个 widget 可以在树中出现零次或多次。每次将 widget 放入树中时，都会被扩充为
/// 一个 [Element]，因此多次合入树的 widget 会被多次扩充。
///
/// [key] 属性控制一个 widget 如何在树中替换另一个 widget。如果两个 widget 的
/// [runtimeType] 和 [key] 分别相等，那么新的 widget 会通过更新底层 element
///（即使用新的 widget 调用 [Element.update]）来替换旧的 widget。否则旧 element 会
/// 从树中移除，新的 widget 会被扩充为 element 并插入树中。
///
/// 另请参阅：
///
///  * [StatefulWidget] 与 [State]，用于在其生命周期内可以多次以不同方式构建的 widget。
///  * [InheritedWidget]，用于引入可供后代 widget 读取的环境状态的 widget。
///  * [StatelessWidget]，用于在给定特定配置和环境状态下始终以相同方式构建的 widget。
@immutable
abstract class Widget extends DiagnosticableTree {
  /// 为子类初始化 [key]。
  const Widget({this.key});

  /// 控制一个 widget 如何在树中替换另一个 widget。
  ///
  /// 如果两个 widget 的 [runtimeType] 和 [key] 属性
  /// 分别是 [operator==]，那么新的 widget 将通过
  /// 更新底层的 element（即，通过使用新的 widget 调用 [Element.update]）来替换旧的 widget。
  /// 否则，旧的 element 将从树中移除，新的
  /// widget 将被扩充为一个 element，然后新的 element 将被插入到
  /// 树中。
  ///
  /// 此外，使用 [GlobalKey] 作为 widget 的 [key] 允许 element
  /// 在树中移动（更改父级）而不会丢失状态。当
  /// 找到一个新的 widget（其键和类型与同一位置的先前 widget 不匹配）
  ///，但前一帧中树中其他地方有一个具有相同全局键的 widget
  /// 时，该 widget 的 element 将
  /// 被移动到新位置。
  ///
  /// 通常，作为另一个 widget 的唯一子级的 widget 不需要
  /// 显式键。
  ///
  /// 另请参阅：
  ///
  ///  * [Key] 和 [GlobalKey] 处的讨论。
  final Key? key;

  /// 将此配置扩充为具体实例。
  ///
  /// 一个给定的 widget 可以在树中包含零次或多次。特别是
  /// 一个给定的 widget 可以多次放置在树中。每次将 widget
  /// 放置在树中时，它都会被扩充为一个 [Element]，这意味着
  /// 多次合并到树中的 widget 将被扩充
  /// 多次。
  @protected
  @factory
  Element createElement();

  /// 此 widget 的简短文本描述。
  @override
  String toStringShort() {
    final String type = objectRuntimeType(this, 'Widget');
    return key == null ? type : '$type-$key';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.defaultDiagnosticsTreeStyle = DiagnosticsTreeStyle.dense;
  }

  @override
  @nonVirtual
  bool operator ==(Object other) => super == other;

  @override
  @nonVirtual
  int get hashCode => super.hashCode;

  /// `newWidget` 是否可用于更新当前
  /// 将 `oldWidget` 作为其配置的 [Element]。
  ///
  /// 使用给定 widget 作为其配置的 element 可以更新为
  /// 使用另一个 widget 作为其配置，当且仅当这两个 widget
  /// 具有 [operator==] 的 [runtimeType] 和 [key] 属性。
  ///
  /// 如果 widget 没有键（其键为 null），那么如果它们具有相同的类型，则它们被视为
  /// 匹配，即使它们的子级完全
  /// 不同。
  static bool canUpdate(Widget oldWidget, Widget newWidget) {
    return oldWidget.runtimeType == newWidget.runtimeType && oldWidget.key == newWidget.key;
  }

  // 返回特定 `Widget` 具体子类型的数字编码。
  // 这在 `Element.updateChild` 中用于确定热重载是否修改了
  // 已挂载元素的配置的超类。每个 `Widget` 的编码
  // 必须与 `Element._debugConcreteSubtype` 中相应的 `Element` 编码匹配。
  static int _debugConcreteSubtype(Widget widget) {
    return widget is StatefulWidget
        ? 1
        : widget is StatelessWidget
        ? 2
        : 0;
  }
}

/// 不需要可变状态的 widget。
///
/// 无状态 widget 是通过
/// 构建一个更具体地描述用户界面的其他 widget 的星座来描述用户界面的一部分的 widget。
/// 构建过程递归地继续，直到
/// 用户界面的描述完全具体（例如，完全由
/// [RenderObjectWidget] 组成，它们描述具体的 [RenderObject]）。
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=wE7khGHVkYY}
///
/// 当您描述的用户界面部分
/// 不依赖于对象本身中的配置信息和
/// widget 被扩充的 [BuildContext] 之外的任何东西时，无状态 widget 非常有用。
/// 对于可以动态更改的组合，例如由于
/// 具有内部时钟驱动的状态，或取决于某些系统状态，
/// 请考虑使用 [StatefulWidget]。
///
/// ## 性能注意事项
///
/// 无状态 widget 的 [build] 方法通常仅在三种
/// 情况下调用：第一次将 widget 插入树中时，当
/// widget 的父级更改其配置时（请参阅 [Element.rebuild]），以及当
/// 它依赖的 [InheritedWidget] 更改时。
///
/// 如果 widget 的父级将定期更改 widget 的配置，或者如果
/// 它依赖于经常更改的继承 widget，那么优化
/// [build] 方法的性能以保持流畅的
/// 渲染性能非常重要。
///
/// 有几种技术可用于最大限度地减少
/// 重建无状态 widget 的影响：
///
///  * 最大限度地减少由 build 方法和
///    它创建的任何 widget 可传递创建的节点数。例如，与其使用精心设计的
///    [Row]、[Column]、[Padding] 和 [SizedBox] 的排列来以
///    特别花哨的方式定位单个
///    子级，不如考虑仅使用 [Align] 或
///    [CustomSingleChildLayout]。与其使用多个
///    [Container] 和 [Decoration] 的复杂分层来绘制恰到好处的图形
///    效果，不如考虑使用单个 [CustomPaint] widget。
///
///  * 在可能的情况下使用 `const` widget，并为
///    widget 提供一个 `const` 构造函数，以便 widget 的用户也可以这样做。
///
///  * 考虑将无状态 widget 重构为有状态 widget，以便
///    它可以使用 [StatefulWidget] 中描述的一些技术，例如
///    缓存子树的公共部分以及在更改
///    树结构时使用 [GlobalKey]。
///
///  * 如果由于使用
///    [InheritedWidget] 而可能频繁重建 widget，请考虑将无状态 widget 重构为
///    多个 widget，并将更改的树的部分推向
///    叶子。例如，与其构建一个包含四个 widget 的树，
///    最内部的 widget 依赖于 [Theme]，不如考虑将
///    构建最内部 widget 的 build 函数的部分分解为其自己的
///    widget，以便在主题更改时只需要重建最内部的 widget。
/// {@template flutter.flutter.widgets.framework.prefer_const_over_helper}
///  * 在尝试创建可重用的 UI 片段时，首选使用 widget
///    而不是辅助方法。例如，如果有一个用于
///    构建 widget 的函数，则 [State.setState] 调用将需要 Flutter 完全
///    重建返回的包装 widget。如果改用 [Widget]，
///    Flutter 将能够有效地仅重新渲染那些
///    真正需要更新的部分。更好的是，如果创建的 widget 是 `const`，
///    Flutter 将短路大部分重建工作。
/// {@endtemplate}
///
/// 此视频详细解释了为什么 `const` 构造函数很重要
/// 以及为什么 [Widget] 比辅助方法更好。
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=IOyq-eTRhvo}
///
/// {@tool snippet}
///
/// 以下是名为 `GreenFrog` 的无状态 widget 子类的骨架。
///
/// 通常，widget 具有更多的构造函数参数，每个参数都对应于
/// 一个 `final` 属性。
///
/// ```dart
/// class GreenFrog extends StatelessWidget {
///   const GreenFrog({ super.key });
///
///   @override
///   Widget build(BuildContext context) {
///     return Container(color: const Color(0xFF2DBD3A));
///   }
/// }
/// ```
/// {@end-tool}
///
/// {@tool snippet}
///
/// 下一个示例显示了更通用的 widget `Frog`，可以为其指定
/// 颜色和子级：
///
/// ```dart
/// class Frog extends StatelessWidget {
///   const Frog({
///     super.key,
///     this.color = const Color(0xFF2DBD3A),
///     this.child,
///   });
///
///   final Color color;
///   final Widget? child;
///
///   @override
///   Widget build(BuildContext context) {
///     return ColoredBox(color: color, child: child);
///   }
/// }
/// ```
/// {@end-tool}
///
/// 按照惯例，widget 构造函数只使用命名参数。同样按照惯例，
/// 第一个参数是 [key]，最后一个参数是 `child`、
/// `children` 或等效项。
///
/// 另请参阅：
///
///  * [StatefulWidget] 和 [State]，用于在其生命周期内可以多次
///    以不同方式构建的 widget。
///  * [InheritedWidget]，用于引入可被
///    后代 widget 读取的环境状态的 widget。
abstract class StatelessWidget extends Widget {
  /// 为子类初始化 [key]。
  const StatelessWidget({super.key});

  /// 创建一个 [StatelessElement] 来管理此 widget 在树中的位置。
  ///
  /// 子类覆盖此方法的情况并不常见。
  @override
  StatelessElement createElement() => StatelessElement(this);

  /// 描述此 widget 表示的用户界面部分。
  ///
  /// 框架在将此 widget 插入到给定 [BuildContext] 的树中时以及
  /// 此 widget 的依赖项发生更改（例如，此 widget 引用的 [InheritedWidget] 发生更改）时调用此方法。
  /// 此方法可能在每一帧中被调用，除了构建 widget 之外不应有任何副作用。
  ///
  /// 框架使用此方法返回的 widget 替换此 widget 下方的子树，
  /// 方法是更新现有子树或删除子树并扩充新的子树，
  /// 具体取决于此方法返回的 widget 是否可以更新现有
  /// 子树的根，如通过调用 [Widget.canUpdate] 所确定的。
  ///
  /// 通常，实现会返回一个新创建的 widget 星座，
  /// 这些 widget 使用此 widget 的构造函数和
  /// 给定 [BuildContext] 中的信息进行配置。
  ///
  /// 给定的 [BuildContext] 包含有关
  /// 正在构建此 widget 的树中位置的信息。例如，上下文
  /// 为树中的此位置提供了一组继承的 widget。一个
  /// 给定的 widget 可能会随着时间的推移使用多个不同的 [BuildContext]
  /// 参数进行构建，如果该 widget 在树中四处移动或者如果
  /// 该 widget 同时插入到树中的多个位置。
  ///
  /// 此方法的实现必须仅依赖于：
  ///
  /// * widget 的字段，这些字段本身不得随时间更改，
  ///   和
  /// * 使用
  ///   [BuildContext.dependOnInheritedWidgetOfExactType] 从 `context` 获取的任何环境状态。
  ///
  /// 如果 widget 的 [build] 方法要依赖于任何其他东西，请改用
  /// [StatefulWidget]。
  ///
  /// 另请参阅：
  ///
  ///  * [StatelessWidget]，其中包含有关性能注意事项的讨论。
  @protected
  Widget build(BuildContext context);
}

/// 具有可变状态的 widget。
///
/// 状态是 (1) 在构建 widget 时可以同步读取并且
/// (2) 可能在 widget 的生命周期内更改的信息。widget 实现者有责任确保在状态发生此类更改时及时通知 [State]，
/// 使用 [State.setState]。
///
/// 有状态 widget 是通过
/// 构建一个更具体地描述用户界面的其他 widget 的星座来描述用户界面的一部分的 widget。
/// 构建过程递归地继续，直到
/// 用户界面的描述完全具体（例如，完全由
/// [RenderObjectWidget] 组成，它们描述具体的 [RenderObject]）。
///
/// 当您描述的用户界面部分可以动态更改时，有状态 widget 非常有用，
/// 例如由于具有内部时钟驱动的状态，或取决于某些系统状态。
/// 对于仅依赖于对象本身中的配置信息和
/// widget 被扩充的 [BuildContext] 的组合，请考虑使用
/// [StatelessWidget]。
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=AqCMFXEmf3w}
///
/// [StatefulWidget] 实例本身是不可变的，并将其可变
/// 状态存储在由
/// [createState] 方法创建的单独的 [State] 对象中，或存储在 [State] 订阅的对象中，
/// 例如 [Stream] 或 [ChangeNotifier] 对象，对这些对象的引用存储在
/// [StatefulWidget] 本身的 final 字段中。
///
/// 框架在扩充
/// [StatefulWidget] 时随时调用 [createState]，这意味着如果该 widget 已被插入
/// 到树中的多个位置，则多个 [State] 对象可能与同一个 [StatefulWidget] 相关联。
/// 同样，如果一个 [StatefulWidget] 从树中移除然后稍后再次插入到树中，框架
/// 将再次调用 [createState] 来创建一个新的 [State] 对象，从而简化
/// [State] 对象的生命周期。
///
/// 如果其创建者为其
/// [key] 使用了 [GlobalKey]，则 [StatefulWidget] 在从树中的一个
/// 位置移动到另一个位置时会保留相同的 [State] 对象。
/// 因为具有 [GlobalKey] 的 widget 最多只能在树中的一个
/// 位置使用，所以使用 [GlobalKey] 的 widget 最多只有一个
/// 关联的 element。框架在
/// 将具有全局键的 widget 从树中的一个位置移动到另一个位置时利用此属性，
/// 方法是将与该 widget 关联的（唯一的）子树从旧
/// 位置嫁接到新位置（而不是在
/// 新位置重新创建子树）。与 [StatefulWidget] 关联的 [State] 对象
/// 与子树的其余部分一起嫁接，这意味着 [State] 对象在新位置被重用
/// （而不是被重新创建）。但是，为了
/// 有资格进行嫁接，该 widget 必须在
/// 从旧位置移除的同一动画帧中插入到新位置。
///
/// ## 性能注意事项
///
/// [StatefulWidget] 主要有两类。
///
/// 第一类是在 [State.initState] 中分配资源并在 [State.dispose] 中释放
/// 它们，但不依赖于 [InheritedWidget]
/// 或调用 [State.setState]。此类 widget 通常用于
/// 应用程序或页面的根部，并通过 [ChangeNotifier]、
/// [Stream] 或其他此类对象与子 widget 通信。
/// 遵循这种模式的有状态 widget 相对便宜（就 CPU 和 GPU 周期而言），因为它们
/// 只构建一次，然后从不更新。因此，它们可以具有相当复杂
/// 和深入的构建方法。
///
/// 第二类是使用 [State.setState] 或依赖于
/// [InheritedWidget] 的 widget。这些 widget 通常会在
/// 应用程序的生命周期内重建多次，因此最大限度地减少
/// 重建此类 widget 的影响非常重要。（它们也可能使用 [State.initState] 或
/// [State.didChangeDependencies] 并分配资源，但重要的是
/// 它们会重建。）
///
/// 有几种技术可用于最大限度地减少
/// 重建有状态 widget 的影响：
///
///  * 将状态推送到叶子。例如，如果您的页面有一个滴答作响的
///    时钟，而不是将状态放在页面顶部并
///    在时钟每次滴答时重建整个页面，而是创建一个专用的
///    时钟 widget，它只更新自己。
///
///  * 最大限度地减少由 build 方法和
///    它创建的任何 widget 可传递创建的节点数。理想情况下，一个有状态的 widget 只会创建一个
///    单个 widget，并且该 widget 将是一个 [RenderObjectWidget]。
///    （显然这并不总是可行的，但 widget 越接近
///    这个理想，它就会越高效。）
///
///  * 如果子树不更改，则缓存表示该
///    子树的 widget，并在每次可以使用时重复使用它。为此，请将
///    一个 widget 分配给一个 `final` 状态变量，并在 build 方法中重复使用它。
///    重复使用 widget 比创建新的（但
///    配置相同的）widget 要高效得多。另一种缓存策略
///    包括将 widget 的可变部分提取到一个接受
///    子参数的 [StatefulWidget] 中。
///
///  * 在可能的情况下使用 `const` widget。（这相当于缓存一个
///    widget 并重复使用它。）
///
///  * 避免更改任何创建的子树的深度或更改
///    子树中任何 widget 的类型。例如，与其返回
///    子级或包装在 [IgnorePointer] 中的子级，不如始终将子
///    widget 包装在 [IgnorePointer] 中并控制 [IgnorePointer.ignoring]
///    属性。这是因为更改子树的深度需要
///    重建、布局和绘制整个子树，而仅仅
///    更改属性将需要对
///    渲染树进行尽可能少的更改（在 [IgnorePointer] 的情况下，例如，根本不需要布局或
///    重绘）。
///
///  * 如果由于某种原因必须更改深度，请考虑将
///    子树的公共部分包装在具有
///    在有状态 widget 的生命周期内保持一致的 [GlobalKey] 的 widget 中。（如果其他 widget
///    不能方便地分配键，则 [KeyedSubtree] widget 可能对此目的有用。）
///
/// {@macro flutter.flutter.widgets.framework.prefer_const_over_helper}
///
/// 此视频详细解释了为什么 `const` 构造函数很重要
/// 以及为什么 [Widget] 比辅助方法更好。
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=IOyq-eTRhvo}
///
/// 有关重建 widget 的机制的更多详细信息，请参阅
/// [Element.rebuild] 处的讨论。
///
/// {@tool snippet}
///
/// 这是一个名为 `YellowBird` 的有状态 widget 子类的框架示例。
///
/// 在这个例子中，[State] 没有实际状态。状态通常表示为私有成员字段。
/// 此外，widget 通常会有更多的构造函数参数，每个参数都对应一个 `final` 属性。
///
/// ```dart
/// class YellowBird extends StatefulWidget {
///   const YellowBird({ super.key });
///
///   @override
///   State<YellowBird> createState() => _YellowBirdState();
/// }
///
/// class _YellowBirdState extends State<YellowBird> {
///   @override
///   Widget build(BuildContext context) {
///     return Container(color: const Color(0xFFFFE306));
///   }
/// }
/// ```
/// {@end-tool}
/// {@tool snippet}
///
/// 下一个示例展示了更通用的 widget `Bird`，可以为其指定颜色和子级，
/// 它还有内部状态，可通过方法来修改：
///
/// ```dart
/// class Bird extends StatefulWidget {
///   const Bird({
///     super.key,
///     this.color = const Color(0xFFFFE306),
///     this.child,
///   });
///
///   final Color color;
///   final Widget? child;
///
///   @override
///   State<Bird> createState() => _BirdState();
/// }
///
/// class _BirdState extends State<Bird> {
///   double _size = 1.0;
///
///   void grow() {
///     setState(() { _size += 0.1; });
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Container(
///       color: widget.color,
///       transform: Matrix4.diagonal3Values(_size, _size, 1.0),
///       child: widget.child,
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// 按照惯例，widget 构造函数仅使用命名参数。同样按照惯例，
/// 第一个参数是 [key]，最后一个参数是 `child`、`children` 或等效项。
///
/// 另请参阅：
///
///  * [State]，其中存放 [StatefulWidget] 的逻辑。
///  * [StatelessWidget]，用于在给定特定配置和环境状态下始终以同样方式构建的 widget。
///  * [InheritedWidget]，用于引入可供后代 widget 读取的环境状态的 widget。
abstract class StatefulWidget extends Widget {
  /// Initializes [key] for subclasses.
  const StatefulWidget({super.key});

  /// 创建一个 [StatefulElement] 来管理此 widget 在树中的位置。
  ///
  /// 子类极少需要重写此方法。
  @override
  StatefulElement createElement() => StatefulElement(this);

  /// 为此 widget 在树中的给定位置创建可变状态。
  ///
  /// 子类应覆盖此方法以返回其关联 [State] 子类的新实例：
  ///
  /// ```dart
  /// @override
  /// State<SomeWidget> createState() => _SomeWidgetState();
  /// ```
  ///
  /// 在 [StatefulWidget] 的生命周期内，框架可能多次调用此方法。
  /// 例如，如果该 widget 被插入到树中的多个位置，框架会为每个位置
  /// 创建一个单独的 [State] 对象。类似地，如果该 widget 从树中移除后
  /// 又重新插入，框架也会再次调用 [createState] 创建新的 [State] 对象，
  /// 从而简化 [State] 对象的生命周期。
  @protected
  @factory
  State createState();
}

/// 在启用断言时跟踪 [State] 对象的生命周期。
enum _StateLifecycle {
  /// 已创建 [State] 对象，此时会调用 [State.initState]。
  created,

  /// 已调用 [State.initState]，但该 [State] 对象尚未准备好构建。
  /// 此时会调用 [State.didChangeDependencies]。
  initialized,

  /// [State] 对象已准备好构建，且尚未调用 [State.dispose]。
  ready,

  /// 已调用 [State.dispose]，该 [State] 对象不再能够构建。
  defunct,
}

/// [State.setState] 函数的签名。
typedef StateSetter = void Function(VoidCallback fn);

/// [StatefulWidget] 的逻辑和内部状态。
///
/// 状态是在构建 widget 时可以同步读取，并且可能在 widget 生命周期内变化的信息。
/// widget 实现者有责任在状态变化时及时通过 [State.setState] 通知 [State]。
///
/// 当扩充 [StatefulWidget] 将其插入树中时，框架会调用
/// [StatefulWidget.createState] 来创建 [State] 对象。由于同一个
/// [StatefulWidget] 实例可能在树中的多个位置被扩充，因此可能会有多个
/// [State] 对象与该实例关联。类似地，如果该 widget 从树中移除后又重新插入，
/// 框架也会再次调用 [StatefulWidget.createState] 来创建新的 [State] 对象，
/// 从而简化 [State] 对象的生命周期。
///
/// [State] 对象遵循以下生命周期：
///
///  * 框架通过调用 [StatefulWidget.createState] 创建 [State] 对象。
///  * 新创建的 [State] 对象会与一个 [BuildContext] 关联。此关联是永久的：
///    [State] 对象不会改变其 [BuildContext]；但 [BuildContext] 本身可以连同
///    其子树在树中移动。此时，该 [State] 对象被认为已 [mounted]。
///  * 框架调用 [initState]。 [State] 的子类应重写该方法，
///    执行依赖于 [BuildContext] 或 widget 的一次性初始化；
///    在调用该方法时可分别通过 [context] 和 [widget] 属性获取这些值。
///  * 框架调用 [didChangeDependencies]。 [State] 的子类应重写此方法，
///    以完成涉及 [InheritedWidget] 的初始化。如果调用了
///    [BuildContext.dependOnInheritedWidgetOfExactType]，当继承的 widget
///    随后发生变化或该 widget 在树中移动时，会再次调用此方法。
///  * 此时 [State] 对象已完全初始化，框架可能多次调用其 [build] 方法，
///    以获取此子树的界面描述。[State] 对象可以通过调用 [setState]
///    主动请求重新构建其子树，以反映内部状态的变化。
///  * 在此期间，父 widget 可能重新构建，并要求该位置显示新的 widget，
///    其 [runtimeType] 和 [Widget.key] 与原先相同。此时框架会更新 [widget]
///    属性指向新的 widget，并以旧 widget 作为参数调用 [didUpdateWidget]。
///    [State] 对象应重写该方法以响应关联 widget 的变化（例如启动隐式动画）。
///    框架总是在调用 [didUpdateWidget] 后调用 [build]，因此在其中再调用
///    [setState] 是多余的。（另见 [Element.rebuild] 的讨论。）
///  * 开发过程中，如果发生热重载（通过命令行 `flutter` 工具按 `r` 或在 IDE 中触发），
///    会调用 [reassemble] 方法，可在其中重新初始化在 [initState] 中准备的数据。
///  * 如果包含此 [State] 对象的子树从树中移除（例如父级构建了具有不同
///    [runtimeType] 或 [Widget.key] 的 widget），框架会调用 [deactivate]。
///    子类应在此方法中清理该对象与树中其他元素的连接（例如向祖先提供了指向
///    某个后代 [RenderObject] 的指针）。
///  * 此时，框架可能会将该子树重新插入到树的其他位置。如果发生这种情况，
///    框架会调用 [build]，让 [State] 对象有机会适应新的位置。如果框架确实
///    重新插入此子树，会在其从旧位置移除的同一帧结束前完成。基于此原因，
///    [State] 对象可以推迟释放大部分资源，直到框架调用它们的 [dispose] 方法。
///  * 如果到当前动画帧结束时框架没有重新插入该子树，就会调用 [dispose]，
///    表明此 [State] 对象将不再构建。子类应在此方法中释放对象持有的资源，
///    例如停止正在运行的动画。
///  * 当框架调用 [dispose] 后，该 [State] 对象被视为未挂载，[mounted] 为 false。
///    此时调用 [setState] 是错误的。该阶段是终结性的：无法重新挂载已 dispose 的
///    [State] 对象。
///
/// 另请参阅：
///
///  * [StatefulWidget]，其文档提供了 [State] 的示例代码并保存当前配置。
///  * [StatelessWidget]，用于在给定特定配置和环境状态下始终以相同方式构建的 widget。
///  * [InheritedWidget]，用于引入可供后代 widget 读取的环境状态的 widget。
///  * [Widget]，对 widget 的整体介绍。
@optionalTypeArgs
abstract class State<T extends StatefulWidget> with Diagnosticable {
  /// The current configuration.
  ///
  /// A [State] object's configuration is the corresponding [StatefulWidget]
  /// instance. This property is initialized by the framework before calling
  /// [initState]. If the parent updates this location in the tree to a new
  /// widget with the same [runtimeType] and [Widget.key] as the current
  /// configuration, the framework will update this property to refer to the new
  /// widget and then call [didUpdateWidget], passing the old configuration as
  /// an argument.
  T get widget => _widget!;
  T? _widget;

  /// The current stage in the lifecycle for this state object.
  ///
  /// This field is used by the framework when asserts are enabled to verify
  /// that [State] objects move through their lifecycle in an orderly fashion.
  _StateLifecycle _debugLifecycleState = _StateLifecycle.created;

  /// Verifies that the [State] that was created is one that expects to be
  /// created for that particular [Widget].
  bool _debugTypesAreRight(Widget widget) => widget is T;

  /// 此 widget 在树中构建的位置。
  ///
  /// 框架在通过 [StatefulWidget.createState] 创建 [State] 对象并在调用
  /// [initState] 之前，会将其与一个 [BuildContext] 关联。此关联是永久的：
  /// [State] 对象的 [BuildContext] 不会改变，但 [BuildContext] 本身可以在树中移动。
  ///
  /// 调用 [dispose] 后，框架会断开此 [State] 与其 [BuildContext] 的联系。
  BuildContext get context {
    assert(() {
      if (_element == null) {
        throw FlutterError(
          'This widget has been unmounted, so the State no longer has a context (and should be considered defunct). \n'
          'Consider canceling any active work during "dispose" or using the "mounted" getter to determine if the State is still active.',
        );
      }
      return true;
    }());
    return _element!;
  }

  StatefulElement? _element;

  /// 此 [State] 对象当前是否在树中。
  ///
  /// 在创建 [State] 对象并调用 [initState] 之前，框架会将其与
  /// [BuildContext] 关联，即“挂载”该对象。此对象在 [dispose] 调用之前一直
  /// 处于挂载状态，之后框架将不再要求它执行 [build]。
  ///
  /// 除非 [mounted] 为 true，否则调用 [setState] 会报错。
  bool get mounted => _element != null;

  /// 当此对象插入到树中时调用。
  ///
  /// 框架在创建每个 [State] 对象时只会调用一次此方法。
  ///
  /// 覆写该方法以执行依赖于此对象插入位置（即 [context]）或
  /// 用于配置该对象的 widget（即 [widget]）的初始化操作。
  ///
  /// {@template flutter.widgets.State.initState}
  /// 如果 [State] 的 [build] 方法依赖于其他会改变状态的对象，
  /// 例如 [ChangeNotifier] 或 [Stream]，或其他可以订阅通知的对象，
  /// 请确保在 [initState]、[didUpdateWidget] 和 [dispose] 中正确订阅和取消订阅：
  ///
  ///  * 在 [initState] 中订阅该对象。
  ///  * 在 [didUpdateWidget] 中，如更新后的 widget 配置需要替换对象，
  ///    则取消旧对象的订阅并订阅新对象。
  ///  * 在 [dispose] 中取消订阅该对象。
  ///
  /// {@endtemplate}
  ///
  /// 不应在此方法中使用 [BuildContext.dependOnInheritedWidgetOfExactType]，
  /// 但在此方法之后会立即调用 [didChangeDependencies]，可在那里使用它。
  ///
  /// 重写此方法时应首先调用父类实现，例如 `super.initState()`。
  @protected
  @mustCallSuper
  void initState() {
    assert(_debugLifecycleState == _StateLifecycle.created);
    assert(debugMaybeDispatchCreated('widgets', 'State', this));
  }

  /// 每当 widget 的配置发生变化时调用。
  ///
  /// 如果父 widget 重新构建并要求此位置显示具有相同 [runtimeType]
  /// 和 [Widget.key] 的新 widget，框架会更新此 [State] 的 [widget] 属性
  /// 指向新的 widget，并以旧 widget 作为参数调用此方法。
  ///
  /// 当 [widget] 发生变化（例如启动隐式动画）时，可重写此方法以作出响应。
  ///
  /// 框架在调用 [didUpdateWidget] 之后总会调用 [build]，
  /// 因此在 [didUpdateWidget] 中调用 [setState] 是多余的。
  ///
  /// {@macro flutter.widgets.State.initState}
  ///
  /// 重写此方法时应首先调用父类实现，例如 `super.didUpdateWidget(oldWidget)`。
  ///
  /// _See the discussion at [Element.rebuild] for more information on when this
  /// method is called._
  @mustCallSuper
  @protected
  void didUpdateWidget(covariant T oldWidget) {}

  /// {@macro flutter.widgets.Element.reassemble}
  ///
  /// In addition to this method being invoked, it is guaranteed that the
  /// [build] method will be invoked when a reassemble is signaled. Most
  /// widgets therefore do not need to do anything in the [reassemble] method.
  ///
  /// See also:
  ///
  ///  * [Element.reassemble]
  ///  * [BindingBase.reassembleApplication]
  ///  * [Image], which uses this to reload images.
  @protected
  @mustCallSuper
  void reassemble() {}

  /// 通知框架此对象的内部状态已发生变化。
  ///
  /// 每当更改 [State] 对象的内部状态时，都应在传递给 [setState] 的函数中完成：
  ///
  /// ```dart
  /// setState(() { _myState = newValue; });
  /// ```
  ///
  /// 提供的回调会立即同步执行，且不能返回 Future（即回调不能为 `async`），
  /// 否则状态的设置时机将变得不确定。
  ///
  /// 调用 [setState] 会通知框架此对象的内部状态已发生可能影响界面的变化，
  /// 从而促使框架为该 [State] 安排一次 [build]。
  ///
  /// 如果直接修改状态而不调用 [setState]，框架可能不会安排 [build]，
  /// 此子树的界面也就无法更新以反映新的状态。
  ///
  /// 通常建议仅在 [setState] 中包裹实际的状态更改，而非与更改相关的其他计算。
  /// 例如，下例中增加了 [build] 函数使用的值，并将变化写入磁盘，
  /// 但只有递增操作包裹在 [setState] 中：
  ///
  /// ```dart
  /// Future<void> _incrementCounter() async {
  ///   setState(() {
  ///     _counter++;
  ///   });
  ///   Directory directory = await getApplicationDocumentsDirectory(); // from path_provider package
  ///   final String dirName = directory.path;
  ///   await File('$dirName/counter.txt').writeAsString('$_counter');
  /// }
  /// ```
  ///
  /// 有时，发生变化的状态位于该 widget 的 [State] 之外的对象中，
  /// 但 widget 仍需更新以响应新的状态。这在使用 [Listenable]
  ///（例如 [AnimationController]）时尤为常见。
  ///
  /// 在这种情况下，最好在传递给 [setState] 的回调中写明状态变更的原因：
  ///
  /// ```dart
  /// void _update() {
  ///   setState(() { /* The animation changed. */ });
  /// }
  /// //...
  /// animation.addListener(_update);
  /// ```
  ///
  /// 在框架调用 [dispose] 之后再调用此方法是错误的。
  /// 是否可以调用此方法可以通过检查 [mounted] 属性来确定。
  /// 但更好的做法是取消可能触发 [setState] 的工作，
  /// 而不是仅在调用前检查 [mounted]，否则会浪费 CPU 周期。
  ///
  /// ## 设计讨论
  ///
  /// 此 API 的最初版本名为 `markNeedsBuild`，
  /// 以与 [RenderObject.markNeedsLayout]、
  /// [RenderObject.markNeedsPaint] 等保持一致。
  ///
  /// 然而早期的用户测试表明，开发者会在很多情况下不必要地调用 `markNeedsBuild()`。
  /// 基本上，他们把它当成“护身符”，只要不确定是否需要调用就会调用。
  ///
  /// 这自然导致了应用性能问题。
  ///
  /// 当 API 改为接收回调函数后，这种现象大幅减少。
  /// 一个猜想是，要求开发者在回调中实际更新状态，
  /// 促使他们更谨慎地思考究竟更新了什么，
  /// 因而更好地理解了调用该方法的合适时机。
  ///
  /// 实际上，[setState] 的实现很简单：同步调用提供的回调，
  /// 然后调用 [Element.markNeedsBuild]。
  ///
  /// ## 性能考虑
  ///
  /// 调用此函数本身几乎没有开销，并且预期每帧最多调用一次，
  /// 其开销可忽略不计。尽管如此，仍应避免在循环等情况下反复调用，
  /// 因为它需要创建并执行闭包。该方法具备幂等性，
  /// 每帧在同一 [State] 上多次调用不会带来任何好处。
  ///
  /// 然而其 _间接_ 成本很高：它会导致该 widget 重新构建，
  /// 可能进一步触发以此 widget 为根的整个子树的重建，
  /// 以及相应 [RenderObject] 子树的重新布局和绘制。
  ///
  /// 因此，只有在状态变化会实质性地影响 [build] 方法的结果时，
  /// 才应调用此方法。
  ///
  /// 另请参阅：
  ///
  ///  * [StatefulWidget]，其文档中有一节与此相关的性能注意事项。
  @protected
  void setState(VoidCallback fn) {
    assert(() {
      if (_debugLifecycleState == _StateLifecycle.defunct) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('setState() called after dispose(): $this'),
          ErrorDescription(
            'This error happens if you call setState() on a State object for a widget that '
            'no longer appears in the widget tree (e.g., whose parent widget no longer '
            'includes the widget in its build). This error can occur when code calls '
            'setState() from a timer or an animation callback.',
          ),
          ErrorHint(
            'The preferred solution is '
            'to cancel the timer or stop listening to the animation in the dispose() '
            'callback. Another solution is to check the "mounted" property of this '
            'object before calling setState() to ensure the object is still in the '
            'tree.',
          ),
          ErrorHint(
            'This error might indicate a memory leak if setState() is being called '
            'because another object is retaining a reference to this State object '
            'after it has been removed from the tree. To avoid memory leaks, '
            'consider breaking the reference to this object during dispose().',
          ),
        ]);
      }
      if (_debugLifecycleState == _StateLifecycle.created && !mounted) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('setState() called in constructor: $this'),
          ErrorHint(
            'This happens when you call setState() on a State object for a widget that '
            "hasn't been inserted into the widget tree yet. It is not necessary to call "
            'setState() in the constructor, since the state is already assumed to be dirty '
            'when it is initially created.',
          ),
        ]);
      }
      return true;
    }());
    final Object? result = fn() as dynamic;
    assert(() {
      if (result is Future) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('setState() callback argument returned a Future.'),
          ErrorDescription(
            'The setState() method on $this was called with a closure or method that '
            'returned a Future. Maybe it is marked as "async".',
          ),
          ErrorHint(
            'Instead of performing asynchronous work inside a call to setState(), first '
            'execute the work (without updating the widget state), and then synchronously '
            'update the state inside a call to setState().',
          ),
        ]);
      }
      // We ignore other types of return values so that you can do things like:
      //   setState(() => x = 3);
      return true;
    }());
    _element!.markNeedsBuild();
  }

  /// 当该对象从树中移除时调用。
  ///
  /// 每当框架将此 [State] 对象从树中移除时都会调用此方法。
  /// 在某些情况下，框架会将该对象重新插入树中的其他位置
  ///（例如由于使用 [GlobalKey]，包含此 [State] 对象的子树从一个位置
  /// 移植到另一个位置）。如果发生这种情况，框架会调用 [activate]
  /// 让 [State] 有机会重新获取在 [deactivate] 中释放的资源，
  /// 然后再调用 [build]，使其能够适应新的树位置。
  /// 如果框架重新插入该子树，会在其被移除的同一动画帧结束前完成。
  /// 因此，通常可以推迟释放大部分资源，直到框架调用 [dispose]。
  ///
  /// 子类应该重写此方法，以清理该对象与树中其他元素之间的任何连接
  ///（例如曾经向祖先提供指向后代 [RenderObject] 的指针）。
  ///
  /// 实现此方法时应在末尾调用父类实现，如 `super.deactivate()`。
  ///
  /// 另请参阅：
  ///
  ///  * [dispose]，若 widget 被永久移除，则在 [deactivate] 之后调用。
  @protected
  @mustCallSuper
  void deactivate() {}

  /// 当该对象在经过 [deactivate] 移除后重新插入树中时调用。
  ///
  /// 在大多数情况下，[State] 一旦被停用就不会再被插入树中，
  /// 它的 [dispose] 方法将被调用以通知可以被垃圾回收。
  ///
  /// 但有时，在停用后框架会将 [State] 重新插入树的其他位置
  ///（例如使用 [GlobalKey] 从一个位置移植到另一个位置）。
  /// 这时框架会先调用 [activate]，让该对象重新获取在
  /// [deactivate] 中释放的资源，然后调用 [build]，
  /// 使其适应新的树位置。如果框架要重新插入该子树，
  /// 会在移除它的同一帧结束前完成。 因此 [State] 可以推迟释放
  /// 大部分资源，直到框架调用 [dispose]。
  ///
  /// 第一次将 [State] 插入树时不会调用此方法，
  /// 当时框架会调用 [initState]。
  ///
  /// 实现此方法时应首先调用父类方法，如 `super.activate()`。
  ///
  /// 另请参阅：
  ///
  ///  * [Element.activate]，元素从“inactive”过渡到“active”状态时对应的方法。
  @protected
  @mustCallSuper
  void activate() {}

  /// 当该对象永久从树中移除时调用。
  ///
  /// 框架在此 [State] 对象不再构建时调用此方法。调用 [dispose] 后，
  /// 该对象被视为未挂载，其 [mounted] 属性为 false，此时再调用 [setState]
  /// 会导致错误。此阶段是终点，已被销毁的 [State] 无法重新挂载。
  ///
  /// 子类应在此方法中释放该对象持有的任何资源（例如停止动画）。
  ///
  /// {@macro flutter.widgets.State.initState}
  ///
  /// 实现此方法时应在末尾调用父类实现，如 `super.dispose()`。
  ///
  /// ## 注意
  ///
  /// 此方法不会在开发者可能期望的某些时机被调用，
  /// 例如应用退出或通过平台方法关闭等。
  ///
  /// ### 应用关闭
  ///
  /// 无法预测应用何时会关闭。比如电池故障、设备落水，或操作系统因内存
  /// 压力而强制终止进程等。
  ///
  /// 应用自身应确保即便遭遇突发终止也能正确处理。
  ///
  /// 如需主动销毁整个 widget 树，可调用 [runApp] 并提供诸如
  /// [SizedBox.shrink] 之类的 widget。
  ///
  /// 若要监听平台的关闭消息（及其他生命周期变化），可使用
  /// [AppLifecycleListener] API。
  ///
  /// {@macro flutter.widgets.runApp.dismissal}
  ///
  /// 参见启动应用的方法（例如 [runApp] 或 [runWidget]），了解如何更积极地
  /// 释放资源。
  ///
  /// 另请参阅：
  ///
  ///  * [deactivate]，在 [dispose] 之前调用。
  @protected
  @mustCallSuper
  void dispose() {
    assert(_debugLifecycleState == _StateLifecycle.ready);
    assert(() {
      _debugLifecycleState = _StateLifecycle.defunct;
      return true;
    }());
    assert(debugMaybeDispatchDisposed(this));
  }

  /// 描述该 widget 所表示的用户界面部分。
  ///
  /// 框架会在多种情况下调用此方法，例如：
  ///
  ///  * 调用 [initState] 之后；
  ///  * 调用 [didUpdateWidget] 之后；
  ///  * 收到 [setState] 调用之后；
  ///  * 当该 [State] 的依赖项发生变化时（如先前 [build] 中引用的
  ///    [InheritedWidget] 发生变化）；
  ///  * 调用 [deactivate] 并重新将该 [State] 插入树中其他位置之后。
  ///
  /// 此方法可能在每一帧都被调用，且不应产生除构建 widget 外的任何副作用。
  ///
  /// 框架会用此方法返回的 widget 替换该 widget 以下的子树，
  /// 具体是更新现有子树还是移除并重新构建，取决于该返回的 widget
  /// 是否可以更新现有子树的根（由 [Widget.canUpdate] 决定）。
  ///
  /// 通常实现会返回一组新创建的 widget，
  /// 这些 widget 使用构造函数信息、给定的 [BuildContext]
  /// 以及此 [State] 的内部状态进行配置。
  ///
  /// 提供的 [BuildContext] 包含此 widget 构建位置的相关信息，
  /// 例如该位置可获取的继承 widget 集合。
  /// 此参数始终与该对象的 [context] 属性相同，且在对象生命周期内保持不变，
  /// 在这里冗余提供是为了让此方法符合 [WidgetBuilder] 的签名。
  ///
  /// ## 设计讨论
  ///
  /// ### 为什么 [build] 方法在 [State] 上，而不是 [StatefulWidget]？
  ///
  /// 将 `Widget build(BuildContext context)` 方法放在 [State] 上，
  /// 而不是放在 `StatefulWidget` 上并额外传入 `State state` 参数，
  /// 可以让开发者在继承 [StatefulWidget] 时拥有更大的灵活性。
  ///
  /// 例如，[AnimatedWidget] 是 [StatefulWidget] 的子类，
  /// 它定义了一个抽象的 `Widget build(BuildContext context)` 方法供子类实现。
  /// 如果 [StatefulWidget] 已经拥有一个接收 [State] 参数的 [build] 方法，
  /// 那么 [AnimatedWidget] 就不得不将其 [State] 对象暴露给子类，
  /// 尽管该对象只是 [AnimatedWidget] 的内部实现细节。
  ///
  /// 从概念上讲，[StatelessWidget] 也可以以类似方式实现为 [StatefulWidget]
  /// 的子类。如果 [build] 方法定义在 [StatefulWidget] 而不是 [State] 上，
  /// 这种实现将不再可能。
  ///
  /// 将 [build] 函数放在 [State] 上还可以避免闭包隐式捕获 `this`
  /// 所导致的一类 bug。如果在 [StatefulWidget] 的 [build] 函数中定义闭包，
  /// 该闭包会隐式捕获当前 widget 实例 `this`，并持有其中的（不可变）字段：
  ///
  /// ```dart
  /// // (this is not valid Flutter code)
  /// class MyButton extends StatefulWidgetX {
  ///   MyButton({super.key, required this.color});
  ///
  ///   final Color color;
  ///
  ///   @override
  ///   Widget build(BuildContext context, State state) {
  ///     return SpecialWidget(
  ///       handler: () { print('color: $color'); },
  ///     );
  ///   }
  /// }
  /// ```
  ///
  /// 例如，父级构建 `MyButton` 时传入蓝色 `color`，
  /// 闭包中的 `$color` 会打印蓝色。这时如果父级重新构建 `MyButton` 并传入绿色，
  /// 首次构建产生的闭包仍隐式指向原来的 widget，
  /// `$color` 依旧打印蓝色；如果闭包生命周期长于 widget，便会输出过时信息。
  ///
  /// 相反，当 [build] 函数位于 [State] 上时，
  /// 在 [build] 过程中创建的闭包会隐式捕获 [State] 实例，而非 widget 实例：
  ///
  /// ```dart
  /// class MyButton extends StatefulWidget {
  ///   const MyButton({super.key, this.color = Colors.teal});
  ///
  ///   final Color color;
  ///   // ...
  /// }
  ///
  /// class MyButtonState extends State<MyButton> {
  ///   // ...
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return SpecialWidget(
  ///       handler: () { print('color: ${widget.color}'); },
  ///     );
  ///   }
  /// }
  /// ```
  ///
  /// 当父级再次以绿色重建 `MyButton` 时，首次构建的闭包仍指向同一个 [State]
  /// 对象，该对象在重建间保留，但框架已将其 [widget] 属性更新为新的
  /// `MyButton` 实例，因此 `${widget.color}` 会按预期打印绿色。
  ///
  /// 另请参阅：
  ///
  ///  * [StatefulWidget]，其中包含关于性能注意事项的讨论。
  @protected
  Widget build(BuildContext context);

  /// 当此 [State] 对象的依赖发生变化时调用。
  ///
  /// 例如，若上一次 [build] 调用了某个 [InheritedWidget]，
  /// 而该 widget 之后发生了变化，框架会调用此方法以通知该对象。
  ///
  /// 此方法也会在 [initState] 之后立即被调用。
  /// 在该方法中调用 [BuildContext.dependOnInheritedWidgetOfExactType] 是安全的。
  ///
  /// 子类很少重写此方法，因为依赖发生变化后框架总会调用 [build]。
  /// 只有在依赖变化时需要执行较耗时的操作（例如网络请求），
  /// 且不适合在每次构建时都执行时，才会重写此方法。
  @protected
  @mustCallSuper
  void didChangeDependencies() {}

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    assert(() {
      properties.add(
        EnumProperty<_StateLifecycle>(
          'lifecycle state',
          _debugLifecycleState,
          defaultValue: _StateLifecycle.ready,
        ),
      );
      return true;
    }());
    properties.add(ObjectFlagProperty<T>('_widget', _widget, ifNull: 'no widget'));
    properties.add(
      ObjectFlagProperty<StatefulElement>('_element', _element, ifNull: 'not mounted'),
    );
  }

  // If @protected State methods are added or removed, the analysis rule should be
  // updated accordingly (dev/bots/custom_rules/protect_public_state_subtypes.dart)
}

/// 一个拥有子 widget 的容器，而非自行构建新 widget。
///
/// 可作为其他 widget（如 [InheritedWidget]、[ParentDataWidget]）的基类。
///
/// 另请参阅：
///
///  * [InheritedWidget]，用于引入可供后代读取的环境状态的 widget；
///  * [ParentDataWidget]，用于填充子节点 [RenderObject.parentData]
///    以配置父 widget 布局；
///  * [StatefulWidget] 和 [State]，用于在生命周期内可多次构建的 widget；
///  * [StatelessWidget]，用于在给定配置和环境状态下始终以相同方式构建的 widget；
///  * [Widget]，了解关于 widget 的概述。
abstract class ProxyWidget extends Widget {
  /// Creates a widget that has exactly one child widget.
  const ProxyWidget({super.key, required this.child});

  /// The widget below this widget in the tree.
  ///
  /// {@template flutter.widgets.ProxyWidget.child}
  /// This widget can only have one child. To lay out multiple children, let this
  /// widget's child be a widget such as [Row], [Column], or [Stack], which have a
  /// `children` property, and then provide the children to that widget.
  /// {@endtemplate}
  final Widget child;
}

/// Base class for widgets that hook [ParentData] information to children of
/// [RenderObjectWidget]s.
///
/// This can be used to provide per-child configuration for
/// [RenderObjectWidget]s with more than one child. For example, [Stack] uses
/// the [Positioned] parent data widget to position each child.
///
/// A [ParentDataWidget] is specific to a particular kind of [ParentData]. That
/// class is `T`, the [ParentData] type argument.
///
/// {@tool snippet}
///
/// This example shows how you would build a [ParentDataWidget] to configure a
/// `FrogJar` widget's children by specifying a [Size] for each one.
///
/// ```dart
/// class FrogSize extends ParentDataWidget<FrogJarParentData> {
///   const FrogSize({
///     super.key,
///     required this.size,
///     required super.child,
///   });
///
///   final Size size;
///
///   @override
///   void applyParentData(RenderObject renderObject) {
///     final FrogJarParentData parentData = renderObject.parentData! as FrogJarParentData;
///     if (parentData.size != size) {
///       parentData.size = size;
///       final RenderFrogJar targetParent = renderObject.parent! as RenderFrogJar;
///       targetParent.markNeedsLayout();
///     }
///   }
///
///   @override
///   Type get debugTypicalAncestorWidgetClass => FrogJar;
/// }
/// ```
/// {@end-tool}
///
/// 另请参阅：
///
///  * [RenderObject]，布局算法的基类；
///  * [RenderObject.parentData]，由此类配置的槽位；
///  * [ParentData]，其 `T` 类型参数即为 [ParentData]；
///  * [RenderObjectWidget]，包装 [RenderObject] 的 widget 类；
///  * [StatefulWidget] 和 [State]，可以在生命周期内多次构建的 widget。
abstract class ParentDataWidget<T extends ParentData> extends ProxyWidget {
  /// 抽象 const 构造函数，使得子类可以拥有 const 构造函数，
  /// 以便在 const 表达式中使用。
  const ParentDataWidget({super.key, required super.child});

  @override
  ParentDataElement<T> createElement() => ParentDataElement<T>(this);

  /// 检查此 widget 是否能将父数据应用于给定的 `renderObject`。
  ///
  /// 提供的 `renderObject` 的 [RenderObject.parentData] 通常由
  /// [debugTypicalAncestorWidgetClass] 指定类型的祖先 [RenderObjectWidget]
  /// 进行初始化。
  ///
  /// 该方法在调用 [applyParentData] 之前被触发，
  /// 当时会传入同一个 [RenderObject]。
  bool debugIsValidRenderObject(RenderObject renderObject) {
    assert(T != dynamic);
    assert(T != ParentData);
    return renderObject.parentData is T;
  }

  /// 描述通常用于设置 [applyParentData] 将写入的 [ParentData] 的
  /// [RenderObjectWidget] 类型。
  ///
  /// 仅在错误信息中使用，通过 [debugTypicalAncestorWidgetDescription]
  /// 告知用户哪个 widget 通常会包裹此 [ParentDataWidget]。
  ///
  /// ## Implementations
  ///
  /// The returned Type should describe a subclass of `RenderObjectWidget`. If
  /// 如果支持多种类型，请使用 [debugTypicalAncestorWidgetDescription]，
  /// 该方法通常插入此值，但可重写以描述多种有效父类型。
  ///
  /// ```dart
  ///   @override
  ///   Type get debugTypicalAncestorWidgetClass => FrogJar;
  /// ```
  ///
  /// 若“典型”父级是泛型（如 `Foo<T>`），可考虑指定常见的类型参数
  ///（例如一般使用 `int` 时写成 `Foo<int>`），或指定其上界（如 `Foo<Object?>`）。
  Type get debugTypicalAncestorWidgetClass;

  /// Describes the [RenderObjectWidget] that is typically used to set up the
  /// [ParentData] that [applyParentData] will write to.
  ///
  /// This is only used in error messages to tell users what widget typically
  /// wraps this [ParentDataWidget].
  ///
  /// 默认返回 [debugTypicalAncestorWidgetClass] 的字符串形式，
  /// 可重写以描述多个有效的父类型。
  String get debugTypicalAncestorWidgetDescription => '$debugTypicalAncestorWidgetClass';

  Iterable<DiagnosticsNode> _debugDescribeIncorrectParentDataType({
    required ParentData? parentData,
    RenderObjectWidget? parentDataCreator,
    DiagnosticsNode? ownershipChain,
  }) {
    assert(T != dynamic);
    assert(T != ParentData);

    final String description =
        'ParentDataWidget $this 想要向 RenderObject 应用 $T 类型的 ParentData';
    return <DiagnosticsNode>[
      if (parentData == null)
        ErrorDescription('$description，但其尚未设置为接收任何 ParentData')
      else
        ErrorDescription(
          '$description，但其已设置为接收与之不兼容的 ParentData 类型 ${parentData.runtimeType}',
        ),
        ErrorHint(
          '通常意味着 $runtimeType widget 拥有错误的祖先 RenderObjectWidget。'
          '通常 $runtimeType widget 应直接放在 $debugTypicalAncestorWidgetDescription widget 内。',
        ),
      if (parentDataCreator != null)
        ErrorHint(
          '问题 $runtimeType 当前被放置在 ${parentDataCreator.runtimeType} widget 中。',
        ),
      if (ownershipChain != null)
        ErrorDescription(
          '接收到不兼容 ParentData 的 RenderObject 的所有权链为：\n  $ownershipChain',
        ),
    ];
  }

  /// 将此 widget 的数据写入给定渲染对象的父数据中。
  ///
  /// 当框架检测到 [child] 对应的 [RenderObject] 所持有的
  /// [RenderObject.parentData] 已不再正确时会调用此函数。例如渲染对象刚被
  /// 插入渲染树时，其父数据可能与该 widget 中的数据不匹配。
  ///
  /// 子类应重写此函数，将自身字段中的数据复制到给定渲染对象的
  /// [RenderObject.parentData] 字段中。该渲染对象的父级保证由 `T` 类型的
  /// widget 创建，因此通常可以假设其父数据对象继承自特定类。
  ///
  /// 如果此函数修改了会影响父布局或绘制的数据，需要自行调用
  /// [RenderObject.markNeedsLayout] 或 [RenderObject.markNeedsPaint] 通知父级。
  @protected
  void applyParentData(RenderObject renderObject);

  /// 是否允许使用 [ParentDataElement.applyWidgetOutOfTurn] 方法处理此 widget。
  ///
  /// 仅当该 widget 的 [ParentData] 配置不会影响布局或绘制阶段时才应返回 true。
  ///
  /// 另请参阅：
  ///
  ///  * [ParentDataElement.applyWidgetOutOfTurn]，调试模式下会对此进行校验。
  @protected
  bool debugCanApplyOutOfTurn() => false;
}

/// 在树中高效向下传播信息的 widget 的基类。
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=og-vJqLzg2c}
///
/// 若要在构建上下文中获取最近的某种类型的继承 widget，
/// 请使用 [BuildContext.dependOnInheritedWidgetOfExactType]。
///
/// 以这种方式引用继承 widget 时，当其自身状态发生变化，
/// 依赖它的 widget 会重新构建。
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=Zbm3hjPjQMk}
///
/// {@tool snippet}
///
/// 以下示例展示名为 `FrogColor` 的继承 widget 框架：
///
/// ```dart
/// class FrogColor extends InheritedWidget {
///   const FrogColor({
///     super.key,
///     required this.color,
///     required super.child,
///   });
///
///   final Color color;
///
///   static FrogColor? maybeOf(BuildContext context) {
///     return context.dependOnInheritedWidgetOfExactType<FrogColor>();
///   }
///
///   static FrogColor of(BuildContext context) {
///     final FrogColor? result = maybeOf(context);
///     assert(result != null, 'No FrogColor found in context');
///     return result!;
///   }
///
///   @override
///   bool updateShouldNotify(FrogColor oldWidget) => color != oldWidget.color;
/// }
/// ```
/// {@end-tool}
///
/// ## 实现 `of` 与 `maybeOf` 方法
///
/// 通常会在 [InheritedWidget] 上提供两个静态方法 `of` 与 `maybeOf`，
/// 它们内部调用 [BuildContext.dependOnInheritedWidgetOfExactType]。
/// 这样便可以在作用域内找不到相应 widget 时自行定义回退逻辑。
///
/// `of` 通常返回非空实例，若未找到相应 [InheritedWidget] 则会断言；
/// `maybeOf` 返回可空实例，找不到时返回 null。`of` 通常内部调用 `maybeOf` 实现。
///
/// 有时 `of` 和 `maybeOf` 返回的不是继承 widget 本身，而是其中的数据；
/// 本例中完全可以直接返回 [Color] 而非 `FrogColor` widget。
///
/// 有时继承 widget 只是其它类的实现细节并保持私有，
/// 此时 `of` 和 `maybeOf` 方法一般实现在公共类上。例如 [Theme]
/// 实际是构建一个私有继承 widget 的 [StatelessWidget]；
/// [Theme.of] 会通过 [BuildContext.dependOnInheritedWidgetOfExactType]
/// 查找该私有继承 widget，并返回其中的 [ThemeData]。
///
/// ## 调用 `of` 或 `maybeOf`
///
/// 使用 `of` 或 `maybeOf` 时，传入的 `context` 必须是该 [InheritedWidget]
/// 的后代，也就是说它在树中必须位于该继承 widget 之“下”。
///
/// {@tool snippet}
///
/// 在此示例中，使用的是 [Builder] 提供的 `context`，它是 `FrogColor` 的子级，
/// 因此可以正常工作。
///
/// ```dart
/// // 承接前面的示例...
/// class MyPage extends StatelessWidget {
///   const MyPage({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: FrogColor(
///         color: Colors.green,
///         child: Builder(
///           builder: (BuildContext innerContext) {
///             return Text(
///               'Hello Frog',
///               style: TextStyle(color: FrogColor.of(innerContext).color),
///             );
///           },
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// {@tool snippet}
///
/// 在此示例中，使用的是 `MyOtherPage` widget 的 `context`，
/// 它是 `FrogColor` 的父级，因此此用法无效，
/// 调用 `FrogColor.of` 时会触发断言。
///
/// ```dart
/// // continuing from previous example...
///
/// class MyOtherPage extends StatelessWidget {
///   const MyOtherPage({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: FrogColor(
///         color: Colors.green,
///         child: Text(
///           'Hello Frog',
///           style: TextStyle(color: FrogColor.of(context).color),
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool} {@youtube 560 315 https://www.youtube.com/watch?v=1t-8rBCGBYw}
///
/// 另请参阅：
///
/// * [StatefulWidget] 与 [State]，用于多次构建的 widget。
/// * [StatelessWidget]，在给定配置和环境下始终构建相同内容的 widget。
/// * [Widget]，了解 widget 的整体概念。
/// * [InheritedNotifier]，其值为 [Listenable] 时会在通知时告知依赖者。
/// * [InheritedModel]，允许依赖者仅订阅部分值变化的继承 widget。
abstract class InheritedWidget extends ProxyWidget {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const InheritedWidget({super.key, required super.child});

  @override
  InheritedElement createElement() => InheritedElement(this);

  /// 框架是否应该通知继承了此 widget 的子孙重新构建。
  ///
  /// 当该 widget 重建时，有时需要重建所有依赖它的 widget，有时又不必。例如
  /// 如果此 widget 持有的数据与 `oldWidget` 持有的数据相同，就无需重建依赖
  /// `oldWidget` 的 widget。
  ///
  /// 框架通过将先前位于此位置的 widget 作为参数调用此函数来区分上述情况。
  /// 传入的 widget 与当前对象具有相同的 [runtimeType]。
  @protected
  bool updateShouldNotify(covariant InheritedWidget oldWidget);
}

/// [RenderObjectWidget]s provide the configuration for [RenderObjectElement]s,
/// which wrap [RenderObject]s, which provide the actual rendering of the
/// application.
///
/// Usually, rather than subclassing [RenderObjectWidget] directly, render
/// object widgets subclass one of:
///
///  * [LeafRenderObjectWidget], if the widget has no children.
///  * [SingleChildRenderObjectWidget], if the widget has exactly one child.
///  * [MultiChildRenderObjectWidget], if the widget takes a list of children.
///  * [SlottedMultiChildRenderObjectWidget], if the widget organizes its
///    children in different named slots.
///
/// Subclasses must implement [createRenderObject] and [updateRenderObject].
abstract class RenderObjectWidget extends Widget {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const RenderObjectWidget({super.key});

  /// RenderObjectWidgets always inflate to a [RenderObjectElement] subclass.
  @override
  @factory
  RenderObjectElement createElement();

  /// Creates an instance of the [RenderObject] class that this
  /// [RenderObjectWidget] represents, using the configuration described by this
  /// [RenderObjectWidget].
  ///
  /// This method should not do anything with the children of the render object.
  /// That should instead be handled by the method that overrides
  /// [RenderObjectElement.mount] in the object rendered by this object's
  /// [createElement] method. See, for example,
  /// [SingleChildRenderObjectElement.mount].
  @protected
  @factory
  RenderObject createRenderObject(BuildContext context);

  /// Copies the configuration described by this [RenderObjectWidget] to the
  /// given [RenderObject], which will be of the same type as returned by this
  /// object's [createRenderObject].
  ///
  /// This method should not do anything to update the children of the render
  /// object. That should instead be handled by the method that overrides
  /// [RenderObjectElement.update] in the object rendered by this object's
  /// [createElement] method. See, for example,
  /// [SingleChildRenderObjectElement.update].
  @protected
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {}

  /// A render object previously associated with this widget has been removed
  /// from the tree. The given [RenderObject] will be of the same type as
  /// returned by this object's [createRenderObject].
  @protected
  void didUnmountRenderObject(covariant RenderObject renderObject) {}
}

/// A superclass for [RenderObjectWidget]s that configure [RenderObject] subclasses
/// that have no children.
///
/// Subclasses must implement [createRenderObject] and [updateRenderObject].
abstract class LeafRenderObjectWidget extends RenderObjectWidget {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const LeafRenderObjectWidget({super.key});

  @override
  LeafRenderObjectElement createElement() => LeafRenderObjectElement(this);
}

/// A superclass for [RenderObjectWidget]s that configure [RenderObject] subclasses
/// that have a single child slot.
///
/// The render object assigned to this widget should make use of
/// [RenderObjectWithChildMixin] to implement a single-child model. The mixin
/// exposes a [RenderObjectWithChildMixin.child] property that allows retrieving
/// the render object belonging to the [child] widget.
///
/// Subclasses must implement [createRenderObject] and [updateRenderObject].
abstract class SingleChildRenderObjectWidget extends RenderObjectWidget {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SingleChildRenderObjectWidget({super.key, this.child});

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  @override
  SingleChildRenderObjectElement createElement() => SingleChildRenderObjectElement(this);
}

/// A superclass for [RenderObjectWidget]s that configure [RenderObject] subclasses
/// that have a single list of children. (This superclass only provides the
/// storage for that child list, it doesn't actually provide the updating
/// logic.)
///
/// Subclasses must use a [RenderObject] that mixes in
/// [ContainerRenderObjectMixin], which provides the necessary functionality to
/// visit the children of the container render object (the render object
/// belonging to the [children] widgets). Typically, subclasses will use a
/// [RenderBox] that mixes in both [ContainerRenderObjectMixin] and
/// [RenderBoxContainerDefaultsMixin].
///
/// Subclasses must implement [createRenderObject] and [updateRenderObject].
///
/// See also:
///
///  * [Stack], which uses [MultiChildRenderObjectWidget].
///  * [RenderStack], for an example implementation of the associated render
///    object.
///  * [SlottedMultiChildRenderObjectWidget], which configures a
///    [RenderObject] that instead of having a single list of children organizes
///    its children in named slots.
abstract class MultiChildRenderObjectWidget extends RenderObjectWidget {
  /// Initializes fields for subclasses.
  const MultiChildRenderObjectWidget({super.key, this.children = const <Widget>[]});

  /// The widgets below this widget in the tree.
  ///
  /// If this list is going to be mutated, it is usually wise to put a [Key] on
  /// each of the child widgets, so that the framework can match old
  /// configurations to new configurations and maintain the underlying render
  /// objects.
  ///
  /// Also, a [Widget] in Flutter is immutable, so directly modifying the
  /// [children] such as `someMultiChildRenderObjectWidget.children.add(...)` or
  /// as the example code below will result in incorrect behaviors. Whenever the
  /// children list is modified, a new list object should be provided.
  ///
  /// ```dart
  /// // This code is incorrect.
  /// class SomeWidgetState extends State<SomeWidget> {
  ///   final List<Widget> _children = <Widget>[];
  ///
  ///   void someHandler() {
  ///     setState(() {
  ///       _children.add(const ChildWidget());
  ///     });
  ///   }
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     // Reusing `List<Widget> _children` here is problematic.
  ///     return Row(children: _children);
  ///   }
  /// }
  /// ```
  ///
  /// The following code corrects the problem mentioned above.
  ///
  /// ```dart
  /// class SomeWidgetState extends State<SomeWidget> {
  ///   final List<Widget> _children = <Widget>[];
  ///
  ///   void someHandler() {
  ///     setState(() {
  ///       // The key here allows Flutter to reuse the underlying render
  ///       // objects even if the children list is recreated.
  ///       _children.add(ChildWidget(key: UniqueKey()));
  ///     });
  ///   }
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     // Always create a new list of children as a Widget is immutable.
  ///     return Row(children: _children.toList());
  ///   }
  /// }
  /// ```
  final List<Widget> children;

  @override
  MultiChildRenderObjectElement createElement() => MultiChildRenderObjectElement(this);
}

// ELEMENTS

enum _ElementLifecycle { initial, active, inactive, defunct }

class _InactiveElements {
  bool _locked = false;
  final Set<Element> _elements = HashSet<Element>();

  void _unmount(Element element) {
    assert(element._lifecycleState == _ElementLifecycle.inactive);
    assert(() {
      if (debugPrintGlobalKeyedWidgetLifecycle) {
        if (element.widget.key is GlobalKey) {
          debugPrint('Discarding $element from inactive elements list.');
        }
      }
      return true;
    }());
    element.visitChildren((Element child) {
      assert(child._parent == element);
      _unmount(child);
    });
    element.unmount();
    assert(element._lifecycleState == _ElementLifecycle.defunct);
  }

  void _unmountAll() {
    _locked = true;
    final List<Element> elements = _elements.toList()..sort(Element._sort);
    _elements.clear();
    try {
      elements.reversed.forEach(_unmount);
    } finally {
      assert(_elements.isEmpty);
      _locked = false;
    }
  }

  static void _deactivateRecursively(Element element) {
    assert(element._lifecycleState == _ElementLifecycle.active);
    element.deactivate();
    assert(element._lifecycleState == _ElementLifecycle.inactive);
    element.visitChildren(_deactivateRecursively);
    assert(() {
      element.debugDeactivated();
      return true;
    }());
  }

  void add(Element element) {
    assert(!_locked);
    assert(!_elements.contains(element));
    assert(element._parent == null);
    if (element._lifecycleState == _ElementLifecycle.active) {
      _deactivateRecursively(element);
    }
    _elements.add(element);
  }

  void remove(Element element) {
    assert(!_locked);
    assert(_elements.contains(element));
    assert(element._parent == null);
    _elements.remove(element);
    assert(element._lifecycleState != _ElementLifecycle.active);
  }

  bool debugContains(Element element) {
    late bool result;
    assert(() {
      result = _elements.contains(element);
      return true;
    }());
    return result;
  }
}

  /// [BuildContext.visitChildElements] 回调的签名。
  ///
  /// 参数为正在被访问的子元素。
  ///
  /// 在此回调中可安全地再次调用 `element.visitChildElements`。
typedef ElementVisitor = void Function(Element element);

  /// [BuildContext.visitAncestorElements] 回调的签名。
  ///
  /// 参数为正在被访问的祖先元素。
  ///
  /// 返回 false 可停止继续遍历。
typedef ConditionalElementVisitor = bool Function(Element element);

/// 表示 widget 在树中位置的句柄。
///
/// 该类提供一组方法，可在 [StatelessWidget.build] 或 [State] 的方法中使用。
///
/// [BuildContext] 会传递给 [WidgetBuilder]（如 [StatelessWidget.build]），
/// 也可通过 [State.context] 获取。部分静态函数（如 [showDialog]、[Theme.of] 等）
/// 也接收 context 参数，以便代表调用 widget 操作，或获得与该 context 相关的数据。
///
/// 每个 widget 都有自己的 [BuildContext]，它将成为 [StatelessWidget.build]
/// 或 [State.build] 返回的 widget 的父级，同样也是任何 [RenderObjectWidget]
/// 子节点的父级。
///
/// 这意味着在一次构建方法内部，当前 widget 的构建上下文与其返回的
/// 子 widget 的构建上下文并不相同，这可能导致一些棘手问题。
/// 例如，调用 [Theme.of(context)] 会查找给定上下文最近的 [Theme]。
/// 如果 widget Q 的构建方法在其返回的子树中包含了 [Theme]，
/// 却在自身上下文上调用 [Theme.of]，则无法找到刚插入的 [Theme]，
/// 只会找到 Q 以上最近的祖先 [Theme]。若需要获取返回树中特定部分的
/// 构建上下文，可使用 [Builder]，它的 [Builder.builder] 回调
/// 会提供 [Builder] 自身的上下文。
///
/// 例如，下面的代码在构建方法创建的 [Scaffold] 上调用
/// [ScaffoldState.showBottomSheet]。若未使用 [Builder]，直接使用
/// 构建方法自身的 `context`，将找不到 [Scaffold]，`Scaffold.of` 会返回 null。
///
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   // here, Scaffold.of(context) returns null
///   return Scaffold(
///     appBar: AppBar(title: const Text('Demo')),
///     body: Builder(
///       builder: (BuildContext context) {
///         return TextButton(
///           child: const Text('BUTTON'),
///           onPressed: () {
///             Scaffold.of(context).showBottomSheet(
///               (BuildContext context) {
///                 return Container(
///                   alignment: Alignment.center,
///                   height: 200,
///                   color: Colors.amber,
///                   child: Center(
///                     child: Column(
///                       mainAxisSize: MainAxisSize.min,
///                       children: <Widget>[
///                         const Text('BottomSheet'),
///                         ElevatedButton(
///                           child: const Text('Close BottomSheet'),
///                           onPressed: () {
///                             Navigator.pop(context);
///                           },
///                         )
///                       ],
///                     ),
///                   ),
///                 );
///               },
///             );
///           },
///         );
///       },
///     )
///   );
/// }
/// ```
///
/// 随着 widget 在树中移动，特定 widget 的 [BuildContext] 可能会改变位置。
/// 因此，从此类方法返回的值不应在单次同步函数执行之外缓存。
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=rIaaH87z1-g}
///
/// 避免存储 [BuildContext] 实例，因为当其关联的 widget 从树中卸载时，
/// 这些实例可能会失效。
/// {@template flutter.widgets.BuildContext.asynchronous_gap}
/// 如果在异步间隙（例如执行异步操作后）使用 [BuildContext]，在交互前请考虑
/// 检查 [mounted] 以确定该上下文是否仍然有效：
///
/// ```dart
///   @override
///   Widget build(BuildContext context) {
///     return OutlinedButton(
///       onPressed: () async {
///         await Future<void>.delayed(const Duration(seconds: 1));
///         if (context.mounted) {
///           Navigator.of(context).pop();
///         }
///       },
///       child: const Text('Delayed pop'),
///     );
///   }
/// ```
/// {@endtemplate}
///
/// [BuildContext] 实际上就是 [Element] 对象，该接口存在是为了避免直接
/// 操作 [Element]。
abstract class BuildContext {
  /// The current configuration of the [Element] that is this [BuildContext].
  Widget get widget;

  /// 该上下文所属的 [BuildOwner]，负责管理与此上下文有关的渲染管线。
  BuildOwner? get owner;

  /// 此上下文关联的 [Widget] 当前是否挂载在组件树中。
  ///
  /// 只有当 mounted 为 true 时，访问 [BuildContext] 的属性或调用其方法才有效；
  /// 若 mounted 为 false，将触发断言。
  ///
  /// 一旦被卸载，某个 [BuildContext] 将不会再次被挂载。
  ///
  /// {@macro flutter.widgets.BuildContext.asynchronous_gap}
  bool get mounted;

  /// 当前 [widget] 是否正在更新 widget 树或渲染树。
  ///
  /// 对于 [StatefulWidget] 和 [StatelessWidget]，在其 build 方法执行期间该值为 true。
  /// [RenderObjectWidget] 在创建或配置关联的 [RenderObject] 时也会将其设为 true。
  /// 其他 [Widget] 类型在生命周期的类似阶段也可能会将其设为 true。
  ///
  /// 当该值为 true 时，可安全地通过调用 [dependOnInheritedElement] 或
  /// [dependOnInheritedWidgetOfExactType] 建立对某个 [InheritedWidget] 的依赖。
  ///
  /// Accessing this flag in release mode is not valid.
  bool get debugDoingBuild;

  /// The current [RenderObject] for the widget. If the widget is a
  /// [RenderObjectWidget], this is the render object that the widget created
  /// 如果 widget 是 [RenderObjectWidget]，则返回它为自己创建的渲染对象；
  /// 否则返回其第一个后代 [RenderObjectWidget] 的渲染对象。
  ///
  /// 仅在构建阶段完成后，此方法才会返回有效结果，因此不能在 build 方法中调用。
  /// 它只能在交互事件（如手势回调）或布局、绘制回调中使用；若 [State.mounted]
  /// 为 false 也不能调用。
  ///
  /// 如果渲染对象是常见的 [RenderBox]，则可通过 [size] 获取其尺寸。此操作仅在
  /// 布局阶段之后有效，因此应只在绘制回调或交互事件回调（如手势回调）中查看。
  ///
  /// 有关帧各阶段的详细说明，请参阅 [WidgetsBinding.drawFrame]。
  ///
  /// 此方法理论上开销与树的深度成 O(N) 关系，但实际通常较廉价，因为距离最近的
  /// 渲染对象通常很近。
  RenderObject? findRenderObject();

  /// [findRenderObject] 返回的 [RenderBox] 的尺寸。
  ///
  /// 仅在布局阶段完成后此 getter 才会返回有效结果，因此不能在 build 方法中调
  /// 用，只能在绘制回调或交互事件回调（如手势回调）中使用。
  ///
  /// 有关帧不同阶段的详细信息，请参阅 [WidgetsBinding.drawFrame]。
  ///
  /// 仅当 [findRenderObject] 实际返回 [RenderBox] 时此 getter 才有效。若返回
  /// 的渲染对象不是 [RenderBox] 的子类（如 [RenderView]），该 getter 在调试
  /// 模式下会抛出异常，在发布模式下则返回 null。
  ///
  /// 理论上，此 getter 的开销与树的深度成 O(N) 关系，但实际上通常较低，因为
  /// 树中通常有很多渲染对象，所以离最近渲染对象的距离通常很短。
  Size? get size;

  /// Registers this build context with [ancestor] such that when
  /// [ancestor]'s widget changes this build context is rebuilt.
  ///
  /// Returns `ancestor.widget`.
  ///
  /// This method is rarely called directly. Most applications should use
  /// [dependOnInheritedWidgetOfExactType], which calls this method after finding
  /// the appropriate [InheritedElement] ancestor.
  ///
  /// All of the qualifications about when [dependOnInheritedWidgetOfExactType] can
  /// be called apply to this method as well.
  InheritedWidget dependOnInheritedElement(InheritedElement ancestor, {Object? aspect});

  /// Returns the nearest widget of the given type `T` and creates a dependency
  /// on it, or null if no appropriate widget is found.
  ///
  /// The widget found will be a concrete [InheritedWidget] subclass, and
  /// calling [dependOnInheritedWidgetOfExactType] registers this build context
  /// with the returned widget. When that widget changes (or a new widget of
  /// that type is introduced, or the widget goes away), this build context is
  /// rebuilt so that it can obtain new values from that widget.
  ///
  /// {@template flutter.widgets.BuildContext.dependOnInheritedWidgetOfExactType}
  /// This is typically called implicitly from `of()` static methods, e.g.
  /// [Theme.of].
  ///
  /// This method should not be called from widget constructors or from
  /// [State.initState] methods, because those methods would not get called
  /// again if the inherited value were to change. To ensure that the widget
  /// correctly updates itself when the inherited value changes, only call this
  /// （直接或间接地）只能在 build 方法、布局和绘制回调，或
  /// [State.didChangeDependencies]（在 [State.initState] 后立即调用）中使用。
  ///
  /// 不应在 [State.dispose] 中调用此方法，因为此时元素树已不稳定。若要在该
  /// 方法中引用祖先，请在 [State.didChangeDependencies] 中保存引用。该方法在
  /// [State.deactivate] 中是安全的，后者在 widget 从树中移除时被调用。
  ///
  /// 也可以在交互事件回调（如手势）或定时器中调用此方法以获取一次性值，但不要
  /// 缓存或复用该值。
  ///
  /// 调用此方法的复杂度为 O(1)，但会导致该 widget 更频繁地重新构建。
  ///
  /// 一旦 widget 通过调用此方法注册了对某个类型的依赖，只要与该 widget 相关的
  /// 状态发生变化，它就会被重新构建，并调用 [State.didChangeDependencies]，直
  /// 到该 widget 或其某个祖先被移动（例如祖先被添加或移除）。
  ///
  /// 参数 [aspect] 仅在 `T` 为支持局部更新的 [InheritedWidget] 子类（如
  /// [InheritedModel]）时使用，用于指定此上下文依赖于该继承 widget 的哪个
  /// “方面”。
  /// {@endtemplate}
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({Object? aspect});

  /// 返回给定 [InheritedWidget] 子类 `T` 最近的 widget，若未找到合适的祖先则返
  /// 回 null。
  ///
  /// 该方法不会像 [dependOnInheritedWidgetOfExactType] 那样建立依赖，因此当
  /// [InheritedWidget] 变化时不会重新构建此 context。它适用于不希望建立依赖
  /// 的少数情况。
  ///
  /// 不应在 [State.dispose] 中调用此方法，因为那时元素树已不稳定。若需在该
  /// 方法中引用祖先，请在 [State.didChangeDependencies] 中保存引用。此方法在
  /// [State.deactivate] 中使用是安全的，该回调会在 widget 从树中移除时触发。
  ///
  /// 也可以在交互事件回调（如手势）或定时器中调用此方法获取一次性值，只要不
  /// 缓存或复用该值即可。
  ///
  /// 调用此方法的复杂度为 O(1)。
  T? getInheritedWidgetOfExactType<T extends InheritedWidget>();

  /// Obtains the element corresponding to the nearest widget of the given type `T`,
  /// which must be the type of a concrete [InheritedWidget] subclass.
  ///
  /// Returns null if no such element is found.
  ///
  /// {@template flutter.widgets.BuildContext.getElementForInheritedWidgetOfExactType}
  /// Calling this method is O(1) with a small constant factor.
  ///
  /// This method does not establish a relationship with the target in the way
  /// that [dependOnInheritedWidgetOfExactType] does.
  ///
  /// This method should not be called from [State.dispose] because the element
  /// tree is no longer stable at that time. To refer to an ancestor from that
  /// method, save a reference to the ancestor by calling
  /// [dependOnInheritedWidgetOfExactType] in [State.didChangeDependencies]. It is
  /// safe to use this method from [State.deactivate], which is called whenever
  /// the widget is removed from the tree.
  /// {@endtemplate}
  InheritedElement? getElementForInheritedWidgetOfExactType<T extends InheritedWidget>();

  /// Returns the nearest ancestor widget of the given type `T`, which must be the
  /// type of a concrete [Widget] subclass.
  ///
  /// {@template flutter.widgets.BuildContext.findAncestorWidgetOfExactType}
  /// In general, [dependOnInheritedWidgetOfExactType] is more useful, since
  /// inherited widgets will trigger consumers to rebuild when they change. This
  /// method is appropriate when used in interaction event handlers (e.g.
  /// gesture callbacks) or for performing one-off tasks such as asserting that
  /// you have or don't have a widget of a specific type as an ancestor. The
  /// return value of a Widget's build method should not depend on the value
  /// returned by this method, because the build context will not rebuild if the
  /// return value of this method changes. This could lead to a situation where
  /// data used in the build method changes, but the widget is not rebuilt.
  ///
  /// 调用此方法相对开销较大（与树的深度成 O(N) 关系）。仅当确定此 widget 与目
  /// 标祖先之间的距离较小且有上限时才调用。
  ///
  /// 不应在 [State.deactivate] 或 [State.dispose] 中调用此方法，因为此时 widget
  /// 树已不稳定。若要在这些方法中引用祖先，请在 [State.didChangeDependencies]
  /// 中调用 [findAncestorWidgetOfExactType] 保存引用。
  ///
  /// 如果该上下文的祖先中没有请求类型的 widget，则返回 null。
  /// {@endtemplate}
  T? findAncestorWidgetOfExactType<T extends Widget>();

  /// 返回最近的祖先 [StatefulWidget] 中类型为 `T` 的 [State] 对象。
  ///
  /// {@template flutter.widgets.BuildContext.findAncestorStateOfType}
  /// 不应在 build 方法中使用，因为当返回值发生变化时，该 build context 不会被
  /// 重新构建。
  /// 通常应使用 [dependOnInheritedWidgetOfExactType]，但此方法可在某些场景下
  /// 用于一次性地修改祖先 widget 的状态，例如让祖先的滚动列表滚动到当前 widget
  /// 所在位置，或在用户交互时移动焦点。
  ///
  /// 通常更推荐通过回调触发祖先的状态更新，而不是使用这种命令式方式，这样代码
  /// 更易维护和复用，因为各 widget 之间解耦。
  ///
  /// 调用此方法的开销与树的深度成 O(N) 关系，仅当确定到目标祖先的距离较小且有
  /// 上限时使用。
  ///
  /// 不应在 [State.deactivate] 或 [State.dispose] 中调用，因为此时 widget 树已
  /// 不稳定。若需在这些方法中引用祖先，请在 [State.didChangeDependencies]
  /// 中调用 [findAncestorStateOfType] 保存引用。
  /// {@endtemplate}
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// ScrollableState? scrollable = context.findAncestorStateOfType<ScrollableState>();
  /// ```
  /// {@end-tool}
  T? findAncestorStateOfType<T extends State>();

  /// 返回最远的祖先 [StatefulWidget] 中类型为 `T` 的 [State] 对象。
  ///
  /// {@template flutter.widgets.BuildContext.findRootAncestorStateOfType}
  /// 与 [findAncestorStateOfType] 类似，但会一直向上查找，直到没有类型为 `T`
  /// 的祖先为止，并返回找到的最后一个。
  ///
  /// 该操作同样是 O(N) 的，其中 N 是整个 widget 树的大小，而不仅仅是某个子树。
  /// {@endtemplate}
  T? findRootAncestorStateOfType<T extends State>();

  /// Returns the [RenderObject] object of the nearest ancestor [RenderObjectWidget] widget
  /// that is an instance of the given type `T`.
  ///
  /// {@template flutter.widgets.BuildContext.findAncestorRenderObjectOfType}
  /// 不应在 build 方法中使用此方法，因为返回值变化时 build context 不会重新构建。
  /// 通常应使用 [dependOnInheritedWidgetOfExactType]，此方法仅在少数情况下需要
  /// 让祖先改变布局或绘制行为时才使用。例如 [Material] 会使用它以便 [InkWell]
  /// 能在 [Material] 的渲染对象上触发水波效果。
  ///
  /// 调用此方法的开销与树的深度成 O(N) 关系，仅在确定此 widget 与目标祖先的距
  /// 离较小且有上限时使用。
  ///
  /// 不应在 [State.deactivate] 或 [State.dispose] 中调用，因为此时 widget 树已
  /// 不稳定。若需在这些方法中引用祖先，请在 [State.didChangeDependencies]
  /// 中调用 [findAncestorRenderObjectOfType] 保存引用。
  /// {@endtemplate}
  T? findAncestorRenderObjectOfType<T extends RenderObject>();

  /// 遍历祖先链，从此构建上下文的父级开始，对每个祖先调用给定回调。
  ///
  /// {@template flutter.widgets.BuildContext.visitAncestorElements}
  /// 回调会收到祖先 widget 对应的 [Element] 引用。遍历在到达根 widget 或回调
  /// 返回 false 时停止。回调不得返回 null。
  ///
  /// 这对于检查 widget 树很有用。
  ///
  /// 调用此方法的开销与树的深度成 O(N) 关系。
  ///
  /// 不应在 [State.deactivate] 或 [State.dispose] 中调用，因为此时元素树已不
  /// 稳定。若需在这些方法中引用祖先，请在 [State.didChangeDependencies]
  /// 中调用 [visitAncestorElements] 保存引用。
  /// {@endtemplate}
  void visitAncestorElements(ConditionalElementVisitor visitor);

  /// 遍历该 widget 的子节点。
  ///
  /// {@template flutter.widgets.BuildContext.visitChildElements}
  /// 这在子节点已构建完成后立即应用变更时非常有用，尤其在已知子节点或仅有一
  /// 个子节点（如 [StatefulWidget] 或 [StatelessWidget]）的情况下。
  ///
  /// 对于对应 [StatefulWidget] 或 [StatelessWidget] 的上下文，调用此方法非常
  /// 便宜（O(1)，因为只有一个子节点）。
  ///
  /// 对于对应 [RenderObjectWidget] 的上下文，调用此方法可能代价较高（与子节
  /// 点数量成 O(N) 关系）。
  ///
  /// 递归调用此方法开销极大（与后代数量成 O(N) 关系），应尽量避免。通常使用
  /// [InheritedWidget] 让后代自行向下获取数据要比递归调用
  /// [visitChildElements] 向下推送数据便宜得多。
  /// {@endtemplate}
  void visitChildElements(ElementVisitor visitor);

  /// 在给定的构建上下文开始冒泡此通知。
  ///
  /// 通知会传递给给定 [BuildContext] 的祖先中所有具有相应类型参数的
  /// [NotificationListener] widget。
  void dispatchNotification(Notification notification);

  /// 返回与当前构建上下文关联的 [Element] 的描述。
  ///
  /// `name` 通常类似于 "The element being rebuilt was" 这样的描述信息。
  ///
  /// See also:
  ///
  ///  * [Element.describeElements], which can be used to describe a list of elements.
  DiagnosticsNode describeElement(
    String name, {
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty,
  });

  /// 返回与当前构建上下文关联的 [Widget] 的描述。
  ///
  /// `name` 通常类似于 "The widget being rebuilt was"。
  DiagnosticsNode describeWidget(
    String name, {
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty,
  });

  /// 将当前构建上下文的祖先树中缺失的某种 widget 类型的信息加入描述。
  ///
  /// 在 [debugCheckHasMaterial] 中可以找到使用该方法的示例。
  List<DiagnosticsNode> describeMissingAncestor({required Type expectedAncestorType});

  /// 将特定 [Element] 的所有权链描述添加到错误报告中。
  ///
  /// 所有权链对于调试元素来源非常有用。
  DiagnosticsNode describeOwnershipChain(String name);
}

/// 用于确定 [BuildOwner.buildScope] 操作范围的类。
///
/// [BuildOwner.buildScope] 方法会重建所有与其 `context` 参数拥有相同
/// [Element.buildScope] 的脏 [Element]，并跳过其他作用域的元素。
///
/// [Element] 默认与其父级拥有相同的 `buildScope`。某些特殊 [Element]
/// 可以重写 [Element.buildScope]，为其后代创建独立的构建作用域。例如
/// [LayoutBuilder] widget 就会建立自己的 [BuildScope]，使得在获取到约束
/// 之前其后代不会过早重建。
final class BuildScope {
  /// 创建 [BuildScope]，可选 [scheduleRebuild] 回调。
  BuildScope({this.scheduleRebuild});

  // 是否已调用 `scheduleRebuild`。
  bool _buildScheduled = false;
  // 当前 [BuildOwner.buildScope] 是否正在此 [BuildScope] 中运行。
  bool _building = false;

  /// 当此 [BuildScope] 中的 [Element] 首次被标记为脏时要调用的可选
  /// [VoidCallback]。
  ///
  /// 该回调通常意味着需要在当前帧稍后调用 [BuildOwner.buildScope]，以重建此
  /// [BuildScope] 中的脏元素。如果该作用域正在被 [BuildOwner.buildScope]
  /// 构建，则不会调用此回调，因为在 [BuildOwner.buildScope] 返回时作用域已
  /// 清理完毕。
  final VoidCallback? scheduleRebuild;

  /// 构建过程中是否有更多元素变脏从而需要重新排序 [_dirtyElements]。
  ///
  /// 这样做是为了保持 [Element._sort] 定义的排序顺序。
  ///
  /// 当 [BuildOwner.buildScope] 未在主动重建 widget 树时，该字段会被设为
  /// null。
  bool? _dirtyElementsNeedsResorting;
  final List<Element> _dirtyElements = <Element>[];

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  void _scheduleBuildFor(Element element) {
    assert(identical(element.buildScope, this));
    if (!element._inDirtyList) {
      _dirtyElements.add(element);
      element._inDirtyList = true;
    }
    if (!_buildScheduled && !_building) {
      _buildScheduled = true;
      scheduleRebuild?.call();
    }
    if (_dirtyElementsNeedsResorting != null) {
      _dirtyElementsNeedsResorting = true;
    }
  }

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('vm:notify-debugger-on-exception')
  void _tryRebuild(Element element) {
    assert(element._inDirtyList);
    assert(identical(element.buildScope, this));
    final bool isTimelineTracked = !kReleaseMode && _isProfileBuildsEnabledFor(element.widget);
    if (isTimelineTracked) {
      Map<String, String>? debugTimelineArguments;
      assert(() {
        if (kDebugMode && debugEnhanceBuildTimelineArguments) {
          debugTimelineArguments = element.widget.toDiagnosticsNode().toTimelineArguments();
        }
        return true;
      }());
      FlutterTimeline.startSync('${element.widget.runtimeType}', arguments: debugTimelineArguments);
    }
    try {
      element.rebuild();
    } catch (e, stack) {
      _reportException(
        ErrorDescription('while rebuilding dirty elements'),
        e,
        stack,
        informationCollector:
            () => <DiagnosticsNode>[
              if (kDebugMode) DiagnosticsDebugCreator(DebugCreator(element)),
              element.describeElement('The element being rebuilt at the time was'),
            ],
      );
    }
    if (isTimelineTracked) {
      FlutterTimeline.finishSync();
    }
  }

  bool _debugAssertElementInScope(Element element, Element debugBuildRoot) {
    final bool isInScope = element._debugIsDescendantOf(debugBuildRoot) || !element.debugIsActive;
    if (isInScope) {
      return true;
    }
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('尝试在错误的构建作用域中构建已标记为脏的 widget。'),
      ErrorDescription(
        '一个已标记为脏且仍处于活动状态的 widget 被安排构建，'
        '但当前的构建作用域意外地不包含该 widget。',
      ),
      ErrorHint(
        '有时在元素从 widget 树移除但未被标记为非活动状态时会出现此问题，'
        '可能是某个祖先元素未正确实现 visitChildren，导致部分或全部后代无法正确停用。',
      ),
      DiagnosticsProperty<Element>(
        '构建作用域的根为',
        debugBuildRoot,
        style: DiagnosticsTreeStyle.errorProperty,
      ),
      DiagnosticsProperty<Element>(
        '问题元素（似乎并不是该构建作用域根的后代）为',
        element,
        style: DiagnosticsTreeStyle.errorProperty,
      ),
    ]);
  }

  @pragma('vm:notify-debugger-on-exception')
  void _flushDirtyElements({required Element debugBuildRoot}) {
    assert(_dirtyElementsNeedsResorting == null, '_flushDirtyElements must be non-reentrant');
    _dirtyElements.sort(Element._sort);
    _dirtyElementsNeedsResorting = false;
    try {
      for (int index = 0; index < _dirtyElements.length; index = _dirtyElementIndexAfter(index)) {
        final Element element = _dirtyElements[index];
        if (identical(element.buildScope, this)) {
          assert(_debugAssertElementInScope(element, debugBuildRoot));
          _tryRebuild(element);
        }
      }
      assert(() {
        final Iterable<Element> missedElements = _dirtyElements.where(
          (Element element) =>
              element.debugIsActive && element.dirty && identical(element.buildScope, this),
        );
        if (missedElements.isNotEmpty) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('buildScope 漏掉了一些脏元素。'),
            ErrorHint(
              '这通常意味着脏元素列表本应重新排序却没有进行。',
            ),
            DiagnosticsProperty<Element>(
              'buildScope 调用时传入的 context 为',
              debugBuildRoot,
              style: DiagnosticsTreeStyle.errorProperty,
            ),
            Element.describeElements(
              '在 buildScope 调用结束时遗漏的元素列表为',
              missedElements,
            ),
          ]);
        }
        return true;
      }());
    } finally {
      for (final Element element in _dirtyElements) {
        if (identical(element.buildScope, this)) {
          element._inDirtyList = false;
        }
      }
      _dirtyElements.clear();
      _dirtyElementsNeedsResorting = null;
      _buildScheduled = false;
    }
  }

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  int _dirtyElementIndexAfter(int index) {
    if (!_dirtyElementsNeedsResorting!) {
      return index + 1;
    }
    index += 1;
    _dirtyElements.sort(Element._sort);
    _dirtyElementsNeedsResorting = false;
    while (index > 0 && _dirtyElements[index - 1].dirty) {
      // It is possible for previously dirty but inactive widgets to move right in the list.
      // We therefore have to move the index left in the list to account for this.
      // We don't know how many could have moved. However, we do know that the only possible
      // change to the list is that nodes that were previously to the left of the index have
      // now moved to be to the right of the right-most cleaned node, and we do know that
      // all the clean nodes were to the left of the index. So we move the index left
      // until just after the right-most clean node.
      index -= 1;
    }
    assert(() {
      for (int i = index - 1; i >= 0; i -= 1) {
        final Element element = _dirtyElements[i];
        assert(!element.dirty || element._lifecycleState != _ElementLifecycle.active);
      }
      return true;
    }());
    return index;
  }
}

/// Manager class for the widgets framework.
///
/// This class tracks which widgets need rebuilding, and handles other tasks
/// that apply to widget trees as a whole, such as managing the inactive element
/// list for the tree and triggering the "reassemble" command when necessary
/// during hot reload when debugging.
///
/// The main build owner is typically owned by the [WidgetsBinding], and is
/// driven from the operating system along with the rest of the
/// build/layout/paint pipeline.
///
/// Additional build owners can be built to manage off-screen widget trees.
///
/// To assign a build owner to a tree, use the
/// [RootElementMixin.assignOwner] method on the root element of the
/// widget tree.
///
/// {@tool dartpad}
/// This example shows how to build an off-screen widget tree used to measure
/// the layout size of the rendered tree. For some use cases, the simpler
/// [Offstage] widget may be a better alternative to this approach.
///
/// ** See code in examples/api/lib/widgets/framework/build_owner.0.dart **
/// {@end-tool}
class BuildOwner {
  /// Creates an object that manages widgets.
  ///
  /// If the `focusManager` argument is not specified or is null, this will
  /// construct a new [FocusManager] and register its global input handlers
  /// via [FocusManager.registerGlobalHandlers], which will modify static
  /// state. Callers wishing to avoid altering this state can explicitly pass
  /// a focus manager here.
  BuildOwner({this.onBuildScheduled, FocusManager? focusManager})
    : focusManager = focusManager ?? (FocusManager()..registerGlobalHandlers());

  /// Called on each build pass when the first buildable element is marked
  /// dirty.
  VoidCallback? onBuildScheduled;

  final _InactiveElements _inactiveElements = _InactiveElements();

  bool _scheduledFlushDirtyElements = false;

  /// The object in charge of the focus tree.
  ///
  /// Rarely used directly. Instead, consider using [FocusScope.of] to obtain
  /// the [FocusScopeNode] for a given [BuildContext].
  ///
  /// See [FocusManager] for more details.
  ///
  /// This field will default to a [FocusManager] that has registered its
  /// global input handlers via [FocusManager.registerGlobalHandlers]. Callers
  /// wishing to avoid registering those handlers (and modifying the associated
  /// static state) can explicitly pass a focus manager to the [BuildOwner.new]
  /// constructor.
  FocusManager focusManager;

  /// Adds an element to the dirty elements list so that it will be rebuilt
  /// when [WidgetsBinding.drawFrame] calls [buildScope].
  void scheduleBuildFor(Element element) {
    assert(element.owner == this);
    assert(element._parentBuildScope != null);
    assert(() {
      if (debugPrintScheduleBuildForStacks) {
        debugPrintStack(
          label:
              'scheduleBuildFor() called for $element${element.buildScope._dirtyElements.contains(element) ? " (ALREADY IN LIST)" : ""}',
        );
      }
      if (!element.dirty) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('scheduleBuildFor() called for a widget that is not marked as dirty.'),
          element.describeElement('The method was called for the following element'),
          ErrorDescription(
            'This element is not current marked as dirty. Make sure to set the dirty flag before '
            'calling scheduleBuildFor().',
          ),
          ErrorHint(
            'If you did not attempt to call scheduleBuildFor() yourself, then this probably '
            'indicates a bug in the widgets framework. Please report it:\n'
            '  https://github.com/flutter/flutter/issues/new?template=02_bug.yml',
          ),
        ]);
      }
      return true;
    }());
    final BuildScope buildScope = element.buildScope;
    assert(() {
      if (debugPrintScheduleBuildForStacks && element._inDirtyList) {
        debugPrintStack(
          label:
              'BuildOwner.scheduleBuildFor() called; '
              '_dirtyElementsNeedsResorting was ${buildScope._dirtyElementsNeedsResorting} (now true); '
              'The dirty list for the current build scope is: ${buildScope._dirtyElements}',
        );
      }
      if (!_debugBuilding && element._inDirtyList) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('BuildOwner.scheduleBuildFor() called inappropriately.'),
          ErrorHint(
            'The BuildOwner.scheduleBuildFor() method called on an Element '
            'that is already in the dirty list.',
          ),
          element.describeElement('the dirty Element was'),
        ]);
      }
      return true;
    }());
    if (!_scheduledFlushDirtyElements && onBuildScheduled != null) {
      _scheduledFlushDirtyElements = true;
      onBuildScheduled!();
    }
    buildScope._scheduleBuildFor(element);
    assert(() {
      if (debugPrintScheduleBuildForStacks) {
        debugPrint("...the build scope's dirty list is now: $buildScope._dirtyElements");
      }
      return true;
    }());
  }

  int _debugStateLockLevel = 0;
  bool get _debugStateLocked => _debugStateLockLevel > 0;

  /// Whether this widget tree is in the build phase.
  ///
  /// Only valid when asserts are enabled.
  bool get debugBuilding => _debugBuilding;
  bool _debugBuilding = false;
  Element? _debugCurrentBuildTarget;

  /// Establishes a scope in which calls to [State.setState] are forbidden, and
  /// calls the given `callback`.
  ///
  /// This mechanism is used to ensure that, for instance, [State.dispose] does
  /// not call [State.setState].
  void lockState(VoidCallback callback) {
    assert(_debugStateLockLevel >= 0);
    assert(() {
      _debugStateLockLevel += 1;
      return true;
    }());
    try {
      callback();
    } finally {
      assert(() {
        _debugStateLockLevel -= 1;
        return true;
      }());
    }
    assert(_debugStateLockLevel >= 0);
  }

  /// Establishes a scope for updating the widget tree, and calls the given
  /// `callback`, if any. Then, builds all the elements that were marked as
  /// dirty using [scheduleBuildFor], in depth order.
  ///
  /// This mechanism prevents build methods from transitively requiring other
  /// build methods to run, potentially causing infinite loops.
  ///
  /// The dirty list is processed after `callback` returns, building all the
  /// elements that were marked as dirty using [scheduleBuildFor], in depth
  /// order. If elements are marked as dirty while this method is running, they
  /// must be deeper than the `context` node, and deeper than any
  /// previously-built node in this pass.
  ///
  /// To flush the current dirty list without performing any other work, this
  /// function can be called with no callback. This is what the framework does
  /// each frame, in [WidgetsBinding.drawFrame].
  ///
  /// Only one [buildScope] can be active at a time.
  ///
  /// A [buildScope] implies a [lockState] scope as well.
  ///
  /// To print a console message every time this method is called, set
  /// [debugPrintBuildScope] to true. This is useful when debugging problems
  /// involving widgets not getting marked dirty, or getting marked dirty too
  /// often.
  @pragma('vm:notify-debugger-on-exception')
  void buildScope(Element context, [VoidCallback? callback]) {
    final BuildScope buildScope = context.buildScope;
    if (callback == null && buildScope._dirtyElements.isEmpty) {
      return;
    }
    assert(_debugStateLockLevel >= 0);
    assert(!_debugBuilding);
    assert(() {
      if (debugPrintBuildScope) {
        debugPrint(
          'buildScope called with context $context; '
          "its build scope's dirty list is: ${buildScope._dirtyElements}",
        );
      }
      _debugStateLockLevel += 1;
      _debugBuilding = true;
      return true;
    }());
    if (!kReleaseMode) {
      Map<String, String>? debugTimelineArguments;
      assert(() {
        if (debugEnhanceBuildTimelineArguments) {
          debugTimelineArguments = <String, String>{
            'build scope dirty count': '${buildScope._dirtyElements.length}',
            'build scope dirty list': '${buildScope._dirtyElements}',
            'lock level': '$_debugStateLockLevel',
            'scope context': '$context',
          };
        }
        return true;
      }());
      FlutterTimeline.startSync('BUILD', arguments: debugTimelineArguments);
    }
    try {
      _scheduledFlushDirtyElements = true;
      buildScope._building = true;
      if (callback != null) {
        assert(_debugStateLocked);
        Element? debugPreviousBuildTarget;
        assert(() {
          debugPreviousBuildTarget = _debugCurrentBuildTarget;
          _debugCurrentBuildTarget = context;
          return true;
        }());
        try {
          callback();
        } finally {
          assert(() {
            assert(_debugCurrentBuildTarget == context);
            _debugCurrentBuildTarget = debugPreviousBuildTarget;
            _debugElementWasRebuilt(context);
            return true;
          }());
        }
      }
      buildScope._flushDirtyElements(debugBuildRoot: context);
    } finally {
      buildScope._building = false;
      _scheduledFlushDirtyElements = false;
      if (!kReleaseMode) {
        FlutterTimeline.finishSync();
      }
      assert(_debugBuilding);
      assert(() {
        _debugBuilding = false;
        _debugStateLockLevel -= 1;
        if (debugPrintBuildScope) {
          debugPrint('buildScope finished');
        }
        return true;
      }());
    }
    assert(_debugStateLockLevel >= 0);
  }

  Map<Element, Set<GlobalKey>>? _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans;

  void _debugTrackElementThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans(
    Element node,
    GlobalKey key,
  ) {
    final Map<Element, Set<GlobalKey>> map =
        _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans ??=
            HashMap<Element, Set<GlobalKey>>();
    final Set<GlobalKey> keys = map.putIfAbsent(node, () => HashSet<GlobalKey>());
    keys.add(key);
  }

  void _debugElementWasRebuilt(Element node) {
    _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans?.remove(node);
  }

  final Map<GlobalKey, Element> _globalKeyRegistry = <GlobalKey, Element>{};

  // In Profile/Release mode this field is initialized to `null`. The Dart compiler can
  // eliminate unused fields, but not their initializers.
  @_debugOnly
  final Set<Element>? _debugIllFatedElements = kDebugMode ? HashSet<Element>() : null;

  // This map keeps track which child reserves the global key with the parent.
  // Parent, child -> global key.
  // This provides us a way to remove old reservation while parent rebuilds the
  // child in the same slot.
  //
  // In Profile/Release mode this field is initialized to `null`. The Dart compiler can
  // eliminate unused fields, but not their initializers.
  @_debugOnly
  final Map<Element, Map<Element, GlobalKey>>? _debugGlobalKeyReservations =
      kDebugMode ? <Element, Map<Element, GlobalKey>>{} : null;

  /// The number of [GlobalKey] instances that are currently associated with
  /// [Element]s that have been built by this build owner.
  int get globalKeyCount => _globalKeyRegistry.length;

  void _debugRemoveGlobalKeyReservationFor(Element parent, Element child) {
    assert(() {
      _debugGlobalKeyReservations?[parent]?.remove(child);
      return true;
    }());
  }

  void _registerGlobalKey(GlobalKey key, Element element) {
    assert(() {
      if (_globalKeyRegistry.containsKey(key)) {
        final Element oldElement = _globalKeyRegistry[key]!;
        assert(element.widget.runtimeType != oldElement.widget.runtimeType);
        _debugIllFatedElements?.add(oldElement);
      }
      return true;
    }());
    _globalKeyRegistry[key] = element;
  }

  void _unregisterGlobalKey(GlobalKey key, Element element) {
    assert(() {
      if (_globalKeyRegistry.containsKey(key) && _globalKeyRegistry[key] != element) {
        final Element oldElement = _globalKeyRegistry[key]!;
        assert(element.widget.runtimeType != oldElement.widget.runtimeType);
      }
      return true;
    }());
    if (_globalKeyRegistry[key] == element) {
      _globalKeyRegistry.remove(key);
    }
  }

  void _debugReserveGlobalKeyFor(Element parent, Element child, GlobalKey key) {
    assert(() {
      _debugGlobalKeyReservations?[parent] ??= <Element, GlobalKey>{};
      _debugGlobalKeyReservations?[parent]![child] = key;
      return true;
    }());
  }

  void _debugVerifyGlobalKeyReservation() {
    assert(() {
      final Map<GlobalKey, Element> keyToParent = <GlobalKey, Element>{};
      _debugGlobalKeyReservations?.forEach((Element parent, Map<Element, GlobalKey> childToKey) {
        // We ignore parent that are unmounted or detached.
        if (parent._lifecycleState == _ElementLifecycle.defunct ||
            parent.renderObject?.attached == false) {
          return;
        }
        childToKey.forEach((Element child, GlobalKey key) {
          // If parent = null, the node is deactivated by its parent and is
          // not re-attached to other part of the tree. We should ignore this
          // node.
          if (child._parent == null) {
            return;
          }
          // It is possible the same key registers to the same parent twice
          // with different children. That is illegal, but it is not in the
          // scope of this check. Such error will be detected in
          // _debugVerifyIllFatedPopulation or
          // _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans.
          if (keyToParent.containsKey(key) && keyToParent[key] != parent) {
            // We have duplication reservations for the same global key.
            final Element older = keyToParent[key]!;
            final Element newer = parent;
            final FlutterError error;
            if (older.toString() != newer.toString()) {
              error = FlutterError.fromParts(<DiagnosticsNode>[
                ErrorSummary('Multiple widgets used the same GlobalKey.'),
                ErrorDescription(
                  'The key $key was used by multiple widgets. The parents of those widgets were:\n'
                  '- $older\n'
                  '- $newer\n'
                  'A GlobalKey can only be specified on one widget at a time in the widget tree.',
                ),
              ]);
            } else {
              error = FlutterError.fromParts(<DiagnosticsNode>[
                ErrorSummary('Multiple widgets used the same GlobalKey.'),
                ErrorDescription(
                  'The key $key was used by multiple widgets. The parents of those widgets were '
                  'different widgets that both had the following description:\n'
                  '  $parent\n'
                  'A GlobalKey can only be specified on one widget at a time in the widget tree.',
                ),
              ]);
            }
            // Fix the tree by removing the duplicated child from one of its
            // parents to resolve the duplicated key issue. This allows us to
            // tear down the tree during testing without producing additional
            // misleading exceptions.
            if (child._parent != older) {
              older.visitChildren((Element currentChild) {
                if (currentChild == child) {
                  older.forgetChild(child);
                }
              });
            }
            if (child._parent != newer) {
              newer.visitChildren((Element currentChild) {
                if (currentChild == child) {
                  newer.forgetChild(child);
                }
              });
            }
            throw error;
          } else {
            keyToParent[key] = parent;
          }
        });
      });
      _debugGlobalKeyReservations?.clear();
      return true;
    }());
  }

  void _debugVerifyIllFatedPopulation() {
    assert(() {
      Map<GlobalKey, Set<Element>>? duplicates;
      for (final Element element in _debugIllFatedElements ?? const <Element>{}) {
        if (element._lifecycleState != _ElementLifecycle.defunct) {
          assert(element.widget.key != null);
          final GlobalKey key = element.widget.key! as GlobalKey;
          assert(_globalKeyRegistry.containsKey(key));
          duplicates ??= <GlobalKey, Set<Element>>{};
          // Uses ordered set to produce consistent error message.
          final Set<Element> elements = duplicates.putIfAbsent(key, () => <Element>{});
          elements.add(element);
          elements.add(_globalKeyRegistry[key]!);
        }
      }
      _debugIllFatedElements?.clear();
      if (duplicates != null) {
        final List<DiagnosticsNode> information = <DiagnosticsNode>[];
        information.add(ErrorSummary('Multiple widgets used the same GlobalKey.'));
        for (final GlobalKey key in duplicates.keys) {
          final Set<Element> elements = duplicates[key]!;
          // TODO(jacobr): this will omit the '- ' before each widget name and
          // use the more standard whitespace style instead. Please let me know
          // if the '- ' style is a feature we want to maintain and we can add
          // another tree style that supports it. I also see '* ' in some places
          // so it would be nice to unify and normalize.
          information.add(
            Element.describeElements(
              'The key $key was used by ${elements.length} widgets',
              elements,
            ),
          );
        }
        information.add(
          ErrorDescription(
            'A GlobalKey can only be specified on one widget at a time in the widget tree.',
          ),
        );
        throw FlutterError.fromParts(information);
      }
      return true;
    }());
  }

  /// Complete the element build pass by unmounting any elements that are no
  /// longer active.
  ///
  /// This is called by [WidgetsBinding.drawFrame].
  ///
  /// In debug mode, this also runs some sanity checks, for example checking for
  /// duplicate global keys.
  @pragma('vm:notify-debugger-on-exception')
  void finalizeTree() {
    if (!kReleaseMode) {
      FlutterTimeline.startSync('FINALIZE TREE');
    }
    try {
      lockState(_inactiveElements._unmountAll); // this unregisters the GlobalKeys
      assert(() {
        try {
          _debugVerifyGlobalKeyReservation();
          _debugVerifyIllFatedPopulation();
          if (_debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans?.isNotEmpty ?? false) {
            final Set<GlobalKey> keys = HashSet<GlobalKey>();
            for (final Element element
                in _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans!.keys) {
              if (element._lifecycleState != _ElementLifecycle.defunct) {
                keys.addAll(
                  _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans![element]!,
                );
              }
            }
            if (keys.isNotEmpty) {
              final Map<String, int> keyStringCount = HashMap<String, int>();
              for (final String key in keys.map<String>((GlobalKey key) => key.toString())) {
                if (keyStringCount.containsKey(key)) {
                  keyStringCount.update(key, (int value) => value + 1);
                } else {
                  keyStringCount[key] = 1;
                }
              }
              final List<String> keyLabels = <String>[
                for (final MapEntry<String, int>(:String key, value: int count)
                    in keyStringCount.entries)
                  if (count == 1)
                    key
                  else
                    '$key ($count different affected keys had this toString representation)',
              ];
              final Iterable<Element> elements =
                  _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans!.keys;
              final Map<String, int> elementStringCount = HashMap<String, int>();
              for (final String element in elements.map<String>(
                (Element element) => element.toString(),
              )) {
                if (elementStringCount.containsKey(element)) {
                  elementStringCount.update(element, (int value) => value + 1);
                } else {
                  elementStringCount[element] = 1;
                }
              }
              final List<String> elementLabels = <String>[
                for (final MapEntry<String, int>(key: String element, value: int count)
                    in elementStringCount.entries)
                  if (count == 1)
                    element
                  else
                    '$element ($count different affected elements had this toString representation)',
              ];
              assert(keyLabels.isNotEmpty);
              final String the = keys.length == 1 ? ' the' : '';
              final String s = keys.length == 1 ? '' : 's';
              final String were = keys.length == 1 ? 'was' : 'were';
              final String their = keys.length == 1 ? 'its' : 'their';
              final String respective = elementLabels.length == 1 ? '' : ' respective';
              final String those = keys.length == 1 ? 'that' : 'those';
              final String s2 = elementLabels.length == 1 ? '' : 's';
              final String those2 = elementLabels.length == 1 ? 'that' : 'those';
              final String they = elementLabels.length == 1 ? 'it' : 'they';
              final String think = elementLabels.length == 1 ? 'thinks' : 'think';
              final String are = elementLabels.length == 1 ? 'is' : 'are';
              // TODO(jacobr): make this error more structured to better expose which widgets had problems.
              throw FlutterError.fromParts(<DiagnosticsNode>[
                ErrorSummary('Duplicate GlobalKey$s detected in widget tree.'),
                // TODO(jacobr): refactor this code so the elements are clickable
                // in GUI debug tools.
                ErrorDescription(
                  'The following GlobalKey$s $were specified multiple times in the widget tree. This will lead to '
                  'parts of the widget tree being truncated unexpectedly, because the second time a key is seen, '
                  'the previous instance is moved to the new location. The key$s $were:\n'
                  '- ${keyLabels.join("\n  ")}\n'
                  'This was determined by noticing that after$the widget$s with the above global key$s $were moved '
                  'out of $their$respective previous parent$s2, $those2 previous parent$s2 never updated during this frame, meaning '
                  'that $they either did not update at all or updated before the widget$s $were moved, in either case '
                  'implying that $they still $think that $they should have a child with $those global key$s.\n'
                  'The specific parent$s2 that did not update after having one or more children forcibly removed '
                  'due to GlobalKey reparenting $are:\n'
                  '- ${elementLabels.join("\n  ")}'
                  '\nA GlobalKey can only be specified on one widget at a time in the widget tree.',
                ),
              ]);
            }
          }
        } finally {
          _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans?.clear();
        }
        return true;
      }());
    } catch (e, stack) {
      // Catching the exception directly to avoid activating the ErrorWidget.
      // Since the tree is in a broken state, adding the ErrorWidget would
      // cause more exceptions.
      _reportException(ErrorSummary('while finalizing the widget tree'), e, stack);
    } finally {
      if (!kReleaseMode) {
        FlutterTimeline.finishSync();
      }
    }
  }

  /// Cause the entire subtree rooted at the given [Element] to be entirely
  /// rebuilt. This is used by development tools when the application code has
  /// changed and is being hot-reloaded, to cause the widget tree to pick up any
  /// changed implementations.
  ///
  /// This is expensive and should not be called except during development.
  void reassemble(Element root) {
    if (!kReleaseMode) {
      FlutterTimeline.startSync('Preparing Hot Reload (widgets)');
    }
    try {
      assert(root._parent == null);
      assert(root.owner == this);
      root.reassemble();
    } finally {
      if (!kReleaseMode) {
        FlutterTimeline.finishSync();
      }
    }
  }
}

/// Mixin this class to allow receiving [Notification] objects dispatched by
/// child elements.
///
/// See also:
///   * [NotificationListener], for a widget that allows consuming notifications.
mixin NotifiableElementMixin on Element {
  /// Called when a notification of the appropriate type arrives at this
  /// location in the tree.
  ///
  /// Return true to cancel the notification bubbling. Return false to
  /// allow the notification to continue to be dispatched to further ancestors.
  bool onNotification(Notification notification);

  @override
  void attachNotificationTree() {
    _notificationTree = _NotificationNode(_parent?._notificationTree, this);
  }
}

class _NotificationNode {
  _NotificationNode(this.parent, this.current);

  NotifiableElementMixin? current;
  _NotificationNode? parent;

  void dispatchNotification(Notification notification) {
    if (current?.onNotification(notification) ?? true) {
      return;
    }
    parent?.dispatchNotification(notification);
  }
}

bool _isProfileBuildsEnabledFor(Widget widget) {
  return debugProfileBuildsEnabled ||
      (debugProfileBuildsEnabledUserWidgets && debugIsWidgetLocalCreation(widget));
}

/// An instantiation of a [Widget] at a particular location in the tree.
///
/// Widgets describe how to configure a subtree but the same widget can be used
/// to configure multiple subtrees simultaneously because widgets are immutable.
/// An [Element] represents the use of a widget to configure a specific location
/// in the tree. Over time, the widget associated with a given element can
/// change, for example, if the parent widget rebuilds and creates a new widget
/// for this location.
///
/// Elements form a tree. Most elements have a unique child, but some widgets
/// (e.g., subclasses of [RenderObjectElement]) can have multiple children.
///
/// Elements have the following lifecycle:
///
///  * The framework creates an element by calling [Widget.createElement] on the
///    widget that will be used as the element's initial configuration.
///  * The framework calls [mount] to add the newly created element to the tree
///    at a given slot in a given parent. The [mount] method is responsible for
///    inflating any child widgets and calling [attachRenderObject] as
///    necessary to attach any associated render objects to the render tree.
///  * At this point, the element is considered "active" and might appear on
///    screen.
///  * At some point, the parent might decide to change the widget used to
///    configure this element, for example because the parent rebuilt with new
///    state. When this happens, the framework will call [update] with the new
///    widget. The new widget will always have the same [runtimeType] and key as
///    old widget. If the parent wishes to change the [runtimeType] or key of
///    the widget at this location in the tree, it can do so by unmounting this
///    element and inflating the new widget at this location.
///  * At some point, an ancestor might decide to remove this element (or an
///    intermediate ancestor) from the tree, which the ancestor does by calling
///    [deactivateChild] on itself. Deactivating the intermediate ancestor will
///    remove that element's render object from the render tree and add this
///    element to the [owner]'s list of inactive elements, causing the framework
///    to call [deactivate] on this element.
///  * At this point, the element is considered "inactive" and will not appear
///    on screen. An element can remain in the inactive state only until
///    the end of the current animation frame. At the end of the animation
///    frame, any elements that are still inactive will be unmounted.
///  * If the element gets reincorporated into the tree (e.g., because it or one
///    of its ancestors has a global key that is reused), the framework will
///    remove the element from the [owner]'s list of inactive elements, call
///    [activate] on the element, and reattach the element's render object to
///    the render tree. (At this point, the element is again considered "active"
///    and might appear on screen.)
///  * If the element does not get reincorporated into the tree by the end of
///    the current animation frame, the framework will call [unmount] on the
///    element.
///  * At this point, the element is considered "defunct" and will not be
///    incorporated into the tree in the future.
abstract class Element extends DiagnosticableTree implements BuildContext {
  /// Creates an element that uses the given widget as its configuration.
  ///
  /// Typically called by an override of [Widget.createElement].
  Element(Widget widget) : _widget = widget {
    assert(debugMaybeDispatchCreated('widgets', 'Element', this));
  }

  Element? _parent;
  _NotificationNode? _notificationTree;

  /// Compare two widgets for equality.
  ///
  /// When a widget is rebuilt with another that compares equal according
  /// to `operator ==`, it is assumed that the update is redundant and the
  /// work to update that branch of the tree is skipped.
  ///
  /// It is generally discouraged to override `operator ==` on any widget that
  /// has children, since a correct implementation would have to defer to the
  /// children's equality operator also, and that is an O(N²) operation: each
  /// child would need to itself walk all its children, each step of the tree.
  ///
  /// It is sometimes reasonable for a leaf widget (one with no children) to
  /// implement this method, if rebuilding the widget is known to be much more
  /// expensive than checking the widgets' parameters for equality and if the
  /// widget is expected to often be rebuilt with identical parameters.
  ///
  /// In general, however, it is more efficient to cache the widgets used
  /// in a build method if it is known that they will not change.
  @nonVirtual
  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, hash_and_equals
  bool operator ==(Object other) => identical(this, other);

  /// Information set by parent to define where this child fits in its parent's
  /// child list.
  ///
  /// A child widget's slot is determined when the parent's [updateChild] method
  /// is called to inflate the child widget. See [RenderObjectElement] for more
  /// details on slots.
  Object? get slot => _slot;
  Object? _slot;

  /// An integer that is guaranteed to be greater than the parent's, if any.
  /// The element at the root of the tree must have a depth greater than 0.
  int get depth {
    assert(() {
      if (_lifecycleState == _ElementLifecycle.initial) {
        throw FlutterError('Depth is only available when element has been mounted.');
      }
      return true;
    }());
    return _depth;
  }

  late int _depth;

  /// Returns result < 0 when [a] < [b], result == 0 when [a] == [b], result > 0
  /// when [a] > [b].
  static int _sort(Element a, Element b) {
    final int diff = a.depth - b.depth;
    // If depths are not equal, return the difference.
    if (diff != 0) {
      return diff;
    }
    // If the `dirty` values are not equal, sort with non-dirty elements being
    // less than dirty elements.
    final bool isBDirty = b.dirty;
    if (a.dirty != isBDirty) {
      return isBDirty ? -1 : 1;
    }
    // Otherwise, `depth`s and `dirty`s are equal.
    return 0;
  }

  // Return a numeric encoding of the specific `Element` concrete subtype.
  // This is used in `Element.updateChild` to determine if a hot reload modified the
  // superclass of a mounted element's configuration. The encoding of each `Element`
  // must match the corresponding `Widget` encoding in `Widget._debugConcreteSubtype`.
  static int _debugConcreteSubtype(Element element) {
    return element is StatefulElement
        ? 1
        : element is StatelessElement
        ? 2
        : 0;
  }

  /// The configuration for this element.
  ///
  /// Avoid overriding this field on [Element] subtypes to provide a more
  /// specific widget type (i.e. [StatelessElement] and [StatelessWidget]).
  /// Instead, cast at any call sites where the more specific type is required.
  /// This avoids significant cast overhead on the getter which is accessed
  /// throughout the framework internals during the build phase - and for which
  /// the more specific type information is not used.
  @override
  Widget get widget => _widget!;
  Widget? _widget;

  @override
  bool get mounted => _widget != null;

  /// Returns true if the Element is defunct.
  ///
  /// This getter always returns false in profile and release builds.
  /// See the lifecycle documentation for [Element] for additional information.
  bool get debugIsDefunct {
    bool isDefunct = false;
    assert(() {
      isDefunct = _lifecycleState == _ElementLifecycle.defunct;
      return true;
    }());
    return isDefunct;
  }

  /// Returns true if the Element is active.
  ///
  /// This getter always returns false in profile and release builds.
  /// See the lifecycle documentation for [Element] for additional information.
  bool get debugIsActive {
    bool isActive = false;
    assert(() {
      isActive = _lifecycleState == _ElementLifecycle.active;
      return true;
    }());
    return isActive;
  }

  /// The object that manages the lifecycle of this element.
  @override
  BuildOwner? get owner => _owner;
  BuildOwner? _owner;

  /// A [BuildScope] whose dirty [Element]s can only be rebuilt by
  /// [BuildOwner.buildScope] calls whose `context` argument is an [Element]
  /// within this [BuildScope].
  ///
  /// The getter typically is only safe to access when this [Element] is [mounted].
  ///
  /// The default implementation returns the parent [Element]'s [buildScope],
  /// as in most cases an [Element] is ready to rebuild as soon as its ancestors
  /// are no longer dirty. One notable exception is [LayoutBuilder]'s
  /// descendants, which must not rebuild until the incoming constraints become
  /// available. [LayoutBuilder]'s [Element] overrides [buildScope] to make none
  /// of its descendants can rebuild until the incoming constraints are known.
  ///
  /// If you choose to override this getter to establish your own [BuildScope],
  /// to flush the dirty [Element]s in the [BuildScope] you need to manually call
  /// [BuildOwner.buildScope] with the root [Element] of your [BuildScope] when
  /// appropriate, as the Flutter framework does not try to register or manage
  /// custom [BuildScope]s.
  ///
  /// Always return the same [BuildScope] instance if you override this getter.
  /// Changing the value returned by this getter at runtime is not
  /// supported.
  ///
  /// The [updateChild] method ignores [buildScope]: if the parent [Element]
  /// calls [updateChild] on a child with a different [BuildScope], the child may
  /// still rebuild.
  ///
  /// See also:
  ///
  ///  * [LayoutBuilder], a widget that establishes a custom [BuildScope].
  BuildScope get buildScope => _parentBuildScope!;
  // The cached value of the parent Element's build scope. The cache is updated
  // when this Element mounts or reparents.
  BuildScope? _parentBuildScope;

  /// {@template flutter.widgets.Element.reassemble}
  /// Called whenever the application is reassembled during debugging, for
  /// example during hot reload.
  ///
  /// This method should rerun any initialization logic that depends on global
  /// state, for example, image loading from asset bundles (since the asset
  /// bundle may have changed).
  ///
  /// This function will only be called during development. In release builds,
  /// the `ext.flutter.reassemble` hook is not available, and so this code will
  /// never execute.
  ///
  /// Implementers should not rely on any ordering for hot reload source update,
  /// reassemble, and build methods after a hot reload has been initiated. It is
  /// possible that a [Timer] (e.g. an [Animation]) or a debugging session
  /// attached to the isolate could trigger a build with reloaded code _before_
  /// reassemble is called. Code that expects preconditions to be set by
  /// reassemble after a hot reload must be resilient to being called out of
  /// order, e.g. by fizzling instead of throwing. That said, once reassemble is
  /// called, build will be called after it at least once.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [State.reassemble]
  ///  * [BindingBase.reassembleApplication]
  ///  * [Image], which uses this to reload images.
  @mustCallSuper
  @protected
  void reassemble() {
    markNeedsBuild();
    visitChildren((Element child) {
      child.reassemble();
    });
  }

  bool _debugIsDescendantOf(Element target) {
    Element? element = this;
    while (element != null && element.depth > target.depth) {
      element = element._parent;
    }
    return element == target;
  }

  /// The render object at (or below) this location in the tree.
  ///
  /// If this object is a [RenderObjectElement], the render object is the one at
  /// this location in the tree. Otherwise, this getter will walk down the tree
  /// until it finds a [RenderObjectElement].
  ///
  /// Some locations in the tree are not backed by a render object. In those
  /// cases, this getter returns null. This can happen, if the element is
  /// located outside of a [View] since only the element subtree rooted in a
  /// view has a render tree associated with it.
  RenderObject? get renderObject {
    Element? current = this;
    while (current != null) {
      if (current._lifecycleState == _ElementLifecycle.defunct) {
        break;
      } else if (current is RenderObjectElement) {
        return current.renderObject;
      } else {
        current = current.renderObjectAttachingChild;
      }
    }
    return null;
  }

  /// Returns the child of this [Element] that will insert a [RenderObject] into
  /// an ancestor of this Element to construct the render tree.
  ///
  /// Returns null if this Element doesn't have any children who need to attach
  /// a [RenderObject] to an ancestor of this [Element]. A [RenderObjectElement]
  /// will therefore return null because its children insert their
  /// [RenderObject]s into the [RenderObjectElement] itself and not into an
  /// ancestor of the [RenderObjectElement].
  ///
  /// Furthermore, this may return null for [Element]s that hoist their own
  /// independent render tree and do not extend the ancestor render tree.
  @protected
  Element? get renderObjectAttachingChild {
    Element? next;
    visitChildren((Element child) {
      assert(next == null); // This verifies that there's only one child.
      next = child;
    });
    return next;
  }

  @override
  List<DiagnosticsNode> describeMissingAncestor({required Type expectedAncestorType}) {
    final List<DiagnosticsNode> information = <DiagnosticsNode>[];
    final List<Element> ancestors = <Element>[];
    visitAncestorElements((Element element) {
      ancestors.add(element);
      return true;
    });

    information.add(
      DiagnosticsProperty<Element>(
        'The specific widget that could not find a $expectedAncestorType ancestor was',
        this,
        style: DiagnosticsTreeStyle.errorProperty,
      ),
    );

    if (ancestors.isNotEmpty) {
      information.add(describeElements('The ancestors of this widget were', ancestors));
    } else {
      information.add(
        ErrorDescription(
          'This widget is the root of the tree, so it has no '
          'ancestors, let alone a "$expectedAncestorType" ancestor.',
        ),
      );
    }
    return information;
  }

  /// Returns a list of [Element]s from the current build context to the error report.
  static DiagnosticsNode describeElements(String name, Iterable<Element> elements) {
    return DiagnosticsBlock(
      name: name,
      children:
          elements
              .map<DiagnosticsNode>((Element element) => DiagnosticsProperty<Element>('', element))
              .toList(),
      allowTruncate: true,
    );
  }

  @override
  DiagnosticsNode describeElement(
    String name, {
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty,
  }) {
    return DiagnosticsProperty<Element>(name, this, style: style);
  }

  @override
  DiagnosticsNode describeWidget(
    String name, {
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty,
  }) {
    return DiagnosticsProperty<Element>(name, this, style: style);
  }

  @override
  DiagnosticsNode describeOwnershipChain(String name) {
    // TODO(jacobr): make this structured so clients can support clicks on
    // individual entries. For example, is this an iterable with arrows as
    // separators?
    return StringProperty(name, debugGetCreatorChain(10));
  }

  // This is used to verify that Element objects move through life in an
  // orderly fashion.
  _ElementLifecycle _lifecycleState = _ElementLifecycle.initial;

  /// Calls the argument for each child. Must be overridden by subclasses that
  /// support having children.
  ///
  /// There is no guaranteed order in which the children will be visited, though
  /// it should be consistent over time.
  ///
  /// Calling this during build is dangerous: the child list might still be
  /// being updated at that point, so the children might not be constructed yet,
  /// or might be old children that are going to be replaced. This method should
  /// only be called if it is provable that the children are available.
  void visitChildren(ElementVisitor visitor) {}

  /// Calls the argument for each child considered onstage.
  ///
  /// Classes like [Offstage] and [Overlay] override this method to hide their
  /// children.
  ///
  /// Being onstage affects the element's discoverability during testing when
  /// you use Flutter's [Finder] objects. For example, when you instruct the
  /// test framework to tap on a widget, by default the finder will look for
  /// onstage elements and ignore the offstage ones.
  ///
  /// The default implementation defers to [visitChildren] and therefore treats
  /// the element as onstage.
  ///
  /// See also:
  ///
  ///  * [Offstage] widget that hides its children.
  ///  * [Finder] that skips offstage widgets by default.
  ///  * [RenderObject.visitChildrenForSemantics], in contrast to this method,
  ///    designed specifically for excluding parts of the UI from the semantics
  ///    tree.
  void debugVisitOnstageChildren(ElementVisitor visitor) => visitChildren(visitor);

  /// Wrapper around [visitChildren] for [BuildContext].
  @override
  void visitChildElements(ElementVisitor visitor) {
    assert(() {
      if (owner == null || !owner!._debugStateLocked) {
        return true;
      }
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('visitChildElements() called during build.'),
        ErrorDescription(
          "The BuildContext.visitChildElements() method can't be called during "
          'build because the child list is still being updated at that point, '
          'so the children might not be constructed yet, or might be old children '
          'that are going to be replaced.',
        ),
      ]);
    }());
    visitChildren(visitor);
  }

  /// Update the given child with the given new configuration.
  ///
  /// This method is the core of the widgets system. It is called each time we
  /// are to add, update, or remove a child based on an updated configuration.
  ///
  /// The `newSlot` argument specifies the new value for this element's [slot].
  ///
  /// If the `child` is null, and the `newWidget` is not null, then we have a new
  /// child for which we need to create an [Element], configured with `newWidget`.
  ///
  /// If the `newWidget` is null, and the `child` is not null, then we need to
  /// remove it because it no longer has a configuration.
  ///
  /// If neither are null, then we need to update the `child`'s configuration to
  /// be the new configuration given by `newWidget`. If `newWidget` can be given
  /// to the existing child (as determined by [Widget.canUpdate]), then it is so
  /// given. Otherwise, the old child needs to be disposed and a new child
  /// created for the new configuration.
  ///
  /// If both are null, then we don't have a child and won't have a child, so we
  /// do nothing.
  ///
  /// The [updateChild] method returns the new child, if it had to create one,
  /// or the child that was passed in, if it just had to update the child, or
  /// null, if it removed the child and did not replace it.
  ///
  /// The following table summarizes the above:
  ///
  /// |                     | **newWidget == null**  | **newWidget != null**   |
  /// | :-----------------: | :--------------------- | :---------------------- |
  /// |  **child == null**  |  Returns null.         |  Returns new [Element]. |
  /// |  **child != null**  |  Old child is removed, returns null. | Old child updated if possible, returns child or new [Element]. |
  ///
  /// The `newSlot` argument is used only if `newWidget` is not null. If `child`
  /// is null (or if the old child cannot be updated), then the `newSlot` is
  /// given to the new [Element] that is created for the child, via
  /// [inflateWidget]. If `child` is not null (and the old child _can_ be
  /// updated), then the `newSlot` is given to [updateSlotForChild] to update
  /// its slot, in case it has moved around since it was last built.
  ///
  /// See the [RenderObjectElement] documentation for more information on slots.
  @protected
  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  Element? updateChild(Element? child, Widget? newWidget, Object? newSlot) {
    if (newWidget == null) {
      if (child != null) {
        deactivateChild(child);
      }
      return null;
    }

    final Element newChild;
    if (child != null) {
      bool hasSameSuperclass = true;
      // When the type of a widget is changed between Stateful and Stateless via
      // hot reload, the element tree will end up in a partially invalid state.
      // That is, if the widget was a StatefulWidget and is now a StatelessWidget,
      // then the element tree currently contains a StatefulElement that is incorrectly
      // referencing a StatelessWidget (and likewise with StatelessElement).
      //
      // To avoid crashing due to type errors, we need to gently guide the invalid
      // element out of the tree. To do so, we ensure that the `hasSameSuperclass` condition
      // returns false which prevents us from trying to update the existing element
      // incorrectly.
      //
      // For the case where the widget becomes Stateful, we also need to avoid
      // accessing `StatelessElement.widget` as the cast on the getter will
      // cause a type error to be thrown. Here we avoid that by short-circuiting
      // the `Widget.canUpdate` check once `hasSameSuperclass` is false.
      assert(() {
        final int oldElementClass = Element._debugConcreteSubtype(child);
        final int newWidgetClass = Widget._debugConcreteSubtype(newWidget);
        hasSameSuperclass = oldElementClass == newWidgetClass;
        return true;
      }());
      if (hasSameSuperclass && child.widget == newWidget) {
        // We don't insert a timeline event here, because otherwise it's
        // confusing that widgets that "don't update" (because they didn't
        // change) get "charged" on the timeline.
        if (child.slot != newSlot) {
          updateSlotForChild(child, newSlot);
        }
        newChild = child;
      } else if (hasSameSuperclass && Widget.canUpdate(child.widget, newWidget)) {
        if (child.slot != newSlot) {
          updateSlotForChild(child, newSlot);
        }
        final bool isTimelineTracked = !kReleaseMode && _isProfileBuildsEnabledFor(newWidget);
        if (isTimelineTracked) {
          Map<String, String>? debugTimelineArguments;
          assert(() {
            if (kDebugMode && debugEnhanceBuildTimelineArguments) {
              debugTimelineArguments = newWidget.toDiagnosticsNode().toTimelineArguments();
            }
            return true;
          }());
          FlutterTimeline.startSync('${newWidget.runtimeType}', arguments: debugTimelineArguments);
        }
        child.update(newWidget);
        if (isTimelineTracked) {
          FlutterTimeline.finishSync();
        }
        assert(child.widget == newWidget);
        assert(() {
          child.owner!._debugElementWasRebuilt(child);
          return true;
        }());
        newChild = child;
      } else {
        deactivateChild(child);
        assert(child._parent == null);
        // The [debugProfileBuildsEnabled] code for this branch is inside
        // [inflateWidget], since some [Element]s call [inflateWidget] directly
        // instead of going through [updateChild].
        newChild = inflateWidget(newWidget, newSlot);
      }
    } else {
      // The [debugProfileBuildsEnabled] code for this branch is inside
      // [inflateWidget], since some [Element]s call [inflateWidget] directly
      // instead of going through [updateChild].
      newChild = inflateWidget(newWidget, newSlot);
    }

    assert(() {
      if (child != null) {
        _debugRemoveGlobalKeyReservation(child);
      }
      final Key? key = newWidget.key;
      if (key is GlobalKey) {
        assert(owner != null);
        owner!._debugReserveGlobalKeyFor(this, newChild, key);
      }
      return true;
    }());

    return newChild;
  }

  /// Updates the children of this element to use new widgets.
  ///
  /// Attempts to update the given old children list using the given new
  /// widgets, removing obsolete elements and introducing new ones as necessary,
  /// and then returns the new child list.
  ///
  /// During this function the `oldChildren` list must not be modified. If the
  /// caller wishes to remove elements from `oldChildren` reentrantly while
  /// this function is on the stack, the caller can supply a `forgottenChildren`
  /// argument, which can be modified while this function is on the stack.
  /// Whenever this function reads from `oldChildren`, this function first
  /// checks whether the child is in `forgottenChildren`. If it is, the function
  /// acts as if the child was not in `oldChildren`.
  ///
  /// This function is a convenience wrapper around [updateChild], which updates
  /// each individual child. If `slots` is non-null, the value for the `newSlot`
  /// argument of [updateChild] is retrieved from that list using the index that
  /// the currently processed `child` corresponds to in the `newWidgets` list
  /// (`newWidgets` and `slots` must have the same length). If `slots` is null,
  /// an [IndexedSlot<Element>] is used as the value for the `newSlot` argument.
  /// In that case, [IndexedSlot.index] is set to the index that the currently
  /// processed `child` corresponds to in the `newWidgets` list and
  /// [IndexedSlot.value] is set to the [Element] of the previous widget in that
  /// list (or null if it is the first child).
  ///
  /// When the [slot] value of an [Element] changes, its
  /// associated [renderObject] needs to move to a new position in the child
  /// list of its parents. If that [RenderObject] organizes its children in a
  /// linked list (as is done by the [ContainerRenderObjectMixin]) this can
  /// be implemented by re-inserting the child [RenderObject] into the
  /// list after the [RenderObject] associated with the [Element] provided as
  /// [IndexedSlot.value] in the [slot] object.
  ///
  /// Using the previous sibling as a [slot] is not enough, though, because
  /// child [RenderObject]s are only moved around when the [slot] of their
  /// associated [RenderObjectElement]s is updated. When the order of child
  /// [Element]s is changed, some elements in the list may move to a new index
  /// but still have the same previous sibling. For example, when
  /// `[e1, e2, e3, e4]` is changed to `[e1, e3, e4, e2]` the element e4
  /// continues to have e3 as a previous sibling even though its index in the list
  /// has changed and its [RenderObject] needs to move to come before e2's
  /// [RenderObject]. In order to trigger this move, a new [slot] value needs to
  /// be assigned to its [Element] whenever its index in its
  /// parent's child list changes. Using an [IndexedSlot<Element>] achieves
  /// exactly that and also ensures that the underlying parent [RenderObject]
  /// knows where a child needs to move to in a linked list by providing its new
  /// previous sibling.
  @protected
  List<Element> updateChildren(
    List<Element> oldChildren,
    List<Widget> newWidgets, {
    Set<Element>? forgottenChildren,
    List<Object?>? slots,
  }) {
    assert(slots == null || newWidgets.length == slots.length);

    Element? replaceWithNullIfForgotten(Element child) {
      return (forgottenChildren?.contains(child) ?? false) ? null : child;
    }

    Object? slotFor(int newChildIndex, Element? previousChild) {
      return slots != null
          ? slots[newChildIndex]
          : IndexedSlot<Element?>(newChildIndex, previousChild);
    }

    // This attempts to diff the new child list (newWidgets) with
    // the old child list (oldChildren), and produce a new list of elements to
    // be the new list of child elements of this element. The called of this
    // method is expected to update this render object accordingly.

    // The cases it tries to optimize for are:
    //  - the old list is empty
    //  - the lists are identical
    //  - there is an insertion or removal of one or more widgets in
    //    only one place in the list
    // If a widget with a key is in both lists, it will be synced.
    // Widgets without keys might be synced but there is no guarantee.

    // The general approach is to sync the entire new list backwards, as follows:
    // 1. Walk the lists from the top, syncing nodes, until you no longer have
    //    matching nodes.
    // 2. Walk the lists from the bottom, without syncing nodes, until you no
    //    longer have matching nodes. We'll sync these nodes at the end. We
    //    don't sync them now because we want to sync all the nodes in order
    //    from beginning to end.
    // At this point we narrowed the old and new lists to the point
    // where the nodes no longer match.
    // 3. Walk the narrowed part of the old list to get the list of
    //    keys and sync null with non-keyed items.
    // 4. Walk the narrowed part of the new list forwards:
    //     * Sync non-keyed items with null
    //     * Sync keyed items with the source if it exists, else with null.
    // 5. Walk the bottom of the list again, syncing the nodes.
    // 6. Sync null with any items in the list of keys that are still
    //    mounted.

    int newChildrenTop = 0;
    int oldChildrenTop = 0;
    int newChildrenBottom = newWidgets.length - 1;
    int oldChildrenBottom = oldChildren.length - 1;

    final List<Element> newChildren = List<Element>.filled(
      newWidgets.length,
      _NullElement.instance,
    );

    Element? previousChild;

    // Update the top of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      final Element? oldChild = replaceWithNullIfForgotten(oldChildren[oldChildrenTop]);
      final Widget newWidget = newWidgets[newChildrenTop];
      assert(oldChild == null || oldChild._lifecycleState == _ElementLifecycle.active);
      if (oldChild == null || !Widget.canUpdate(oldChild.widget, newWidget)) {
        break;
      }
      final Element newChild =
          updateChild(oldChild, newWidget, slotFor(newChildrenTop, previousChild))!;
      assert(newChild._lifecycleState == _ElementLifecycle.active);
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    // Scan the bottom of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      final Element? oldChild = replaceWithNullIfForgotten(oldChildren[oldChildrenBottom]);
      final Widget newWidget = newWidgets[newChildrenBottom];
      assert(oldChild == null || oldChild._lifecycleState == _ElementLifecycle.active);
      if (oldChild == null || !Widget.canUpdate(oldChild.widget, newWidget)) {
        break;
      }
      oldChildrenBottom -= 1;
      newChildrenBottom -= 1;
    }

    // Scan the old children in the middle of the list.
    final bool haveOldChildren = oldChildrenTop <= oldChildrenBottom;
    Map<Key, Element>? oldKeyedChildren;
    if (haveOldChildren) {
      oldKeyedChildren = <Key, Element>{};
      while (oldChildrenTop <= oldChildrenBottom) {
        final Element? oldChild = replaceWithNullIfForgotten(oldChildren[oldChildrenTop]);
        assert(oldChild == null || oldChild._lifecycleState == _ElementLifecycle.active);
        if (oldChild != null) {
          if (oldChild.widget.key != null) {
            oldKeyedChildren[oldChild.widget.key!] = oldChild;
          } else {
            deactivateChild(oldChild);
          }
        }
        oldChildrenTop += 1;
      }
    }

    // Update the middle of the list.
    while (newChildrenTop <= newChildrenBottom) {
      Element? oldChild;
      final Widget newWidget = newWidgets[newChildrenTop];
      if (haveOldChildren) {
        final Key? key = newWidget.key;
        if (key != null) {
          oldChild = oldKeyedChildren![key];
          if (oldChild != null) {
            if (Widget.canUpdate(oldChild.widget, newWidget)) {
              // we found a match!
              // remove it from oldKeyedChildren so we don't unsync it later
              oldKeyedChildren.remove(key);
            } else {
              // Not a match, let's pretend we didn't see it for now.
              oldChild = null;
            }
          }
        }
      }
      assert(oldChild == null || Widget.canUpdate(oldChild.widget, newWidget));
      final Element newChild =
          updateChild(oldChild, newWidget, slotFor(newChildrenTop, previousChild))!;
      assert(newChild._lifecycleState == _ElementLifecycle.active);
      assert(
        oldChild == newChild ||
            oldChild == null ||
            oldChild._lifecycleState != _ElementLifecycle.active,
      );
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
    }

    // We've scanned the whole list.
    assert(oldChildrenTop == oldChildrenBottom + 1);
    assert(newChildrenTop == newChildrenBottom + 1);
    assert(newWidgets.length - newChildrenTop == oldChildren.length - oldChildrenTop);
    newChildrenBottom = newWidgets.length - 1;
    oldChildrenBottom = oldChildren.length - 1;

    // Update the bottom of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      final Element oldChild = oldChildren[oldChildrenTop];
      assert(replaceWithNullIfForgotten(oldChild) != null);
      assert(oldChild._lifecycleState == _ElementLifecycle.active);
      final Widget newWidget = newWidgets[newChildrenTop];
      assert(Widget.canUpdate(oldChild.widget, newWidget));
      final Element newChild =
          updateChild(oldChild, newWidget, slotFor(newChildrenTop, previousChild))!;
      assert(newChild._lifecycleState == _ElementLifecycle.active);
      assert(oldChild == newChild || oldChild._lifecycleState != _ElementLifecycle.active);
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    // Clean up any of the remaining middle nodes from the old list.
    if (haveOldChildren && oldKeyedChildren!.isNotEmpty) {
      for (final Element oldChild in oldKeyedChildren.values) {
        if (forgottenChildren == null || !forgottenChildren.contains(oldChild)) {
          deactivateChild(oldChild);
        }
      }
    }
    assert(newChildren.every((Element element) => element is! _NullElement));
    return newChildren;
  }

  /// Add this element to the tree in the given slot of the given parent.
  ///
  /// The framework calls this function when a newly created element is added to
  /// the tree for the first time. Use this method to initialize state that
  /// depends on having a parent. State that is independent of the parent can
  /// more easily be initialized in the constructor.
  ///
  /// This method transitions the element from the "initial" lifecycle state to
  /// the "active" lifecycle state.
  ///
  /// Subclasses that override this method are likely to want to also override
  /// [update], [visitChildren], [RenderObjectElement.insertRenderObjectChild],
  /// [RenderObjectElement.moveRenderObjectChild], and
  /// [RenderObjectElement.removeRenderObjectChild].
  ///
  /// Implementations of this method should start with a call to the inherited
  /// method, as in `super.mount(parent, newSlot)`.
  @mustCallSuper
  void mount(Element? parent, Object? newSlot) {
    assert(
      _lifecycleState == _ElementLifecycle.initial,
      'This element is no longer in its initial state (${_lifecycleState.name})',
    );
    assert(
      _parent == null,
      "This element already has a parent ($_parent) and it shouldn't have one yet.",
    );
    assert(
      parent == null || parent._lifecycleState == _ElementLifecycle.active,
      'Parent ($parent) should be null or in the active state (${parent._lifecycleState.name})',
    );
    assert(slot == null, "This element already has a slot ($slot) and it shouldn't");
    _parent = parent;
    _slot = newSlot;
    _lifecycleState = _ElementLifecycle.active;
    _depth = 1 + (_parent?.depth ?? 0);
    if (parent != null) {
      // Only assign ownership if the parent is non-null. If parent is null
      // (the root node), the owner should have already been assigned.
      // See RootRenderObjectElement.assignOwner().
      _owner = parent.owner;
      _parentBuildScope = parent.buildScope;
    }
    assert(owner != null);
    final Key? key = widget.key;
    if (key is GlobalKey) {
      owner!._registerGlobalKey(key, this);
    }
    _updateInheritance();
    attachNotificationTree();
  }

  void _debugRemoveGlobalKeyReservation(Element child) {
    assert(owner != null);
    owner!._debugRemoveGlobalKeyReservationFor(this, child);
  }

  /// Change the widget used to configure this element.
  ///
  /// The framework calls this function when the parent wishes to use a
  /// different widget to configure this element. The new widget is guaranteed
  /// to have the same [runtimeType] as the old widget.
  ///
  /// This function is called only during the "active" lifecycle state.
  @mustCallSuper
  void update(covariant Widget newWidget) {
    // This code is hot when hot reloading, so we try to
    // only call _AssertionError._evaluateAssertion once.
    assert(
      _lifecycleState == _ElementLifecycle.active &&
          newWidget != widget &&
          Widget.canUpdate(widget, newWidget),
    );
    // This Element was told to update and we can now release all the global key
    // reservations of forgotten children. We cannot do this earlier because the
    // forgotten children still represent global key duplications if the element
    // never updates (the forgotten children are not removed from the tree
    // until the call to update happens)
    assert(() {
      _debugForgottenChildrenWithGlobalKey?.forEach(_debugRemoveGlobalKeyReservation);
      _debugForgottenChildrenWithGlobalKey?.clear();
      return true;
    }());
    _widget = newWidget;
  }

  /// Change the slot that the given child occupies in its parent.
  ///
  /// Called by [MultiChildRenderObjectElement], and other [RenderObjectElement]
  /// subclasses that have multiple children, when child moves from one position
  /// to another in this element's child list.
  @protected
  void updateSlotForChild(Element child, Object? newSlot) {
    assert(_lifecycleState == _ElementLifecycle.active);
    assert(child._parent == this);
    void visit(Element element) {
      element.updateSlot(newSlot);
      final Element? descendant = element.renderObjectAttachingChild;
      if (descendant != null) {
        visit(descendant);
      }
    }

    visit(child);
  }

  /// Called by [updateSlotForChild] when the framework needs to change the slot
  /// that this [Element] occupies in its ancestor.
  @protected
  @mustCallSuper
  void updateSlot(Object? newSlot) {
    assert(_lifecycleState == _ElementLifecycle.active);
    assert(_parent != null);
    assert(_parent!._lifecycleState == _ElementLifecycle.active);
    _slot = newSlot;
  }

  void _updateDepth(int parentDepth) {
    final int expectedDepth = parentDepth + 1;
    if (_depth < expectedDepth) {
      _depth = expectedDepth;
      visitChildren((Element child) {
        child._updateDepth(expectedDepth);
      });
    }
  }

  void _updateBuildScopeRecursively() {
    if (identical(buildScope, _parent?.buildScope)) {
      return;
    }
    // Unset the _inDirtyList flag so this Element can be added to the dirty list
    // of the new build scope if it's dirty.
    _inDirtyList = false;
    _parentBuildScope = _parent?.buildScope;
    visitChildren((Element child) {
      child._updateBuildScopeRecursively();
    });
  }

  /// Remove [renderObject] from the render tree.
  ///
  /// The default implementation of this function calls
  /// [detachRenderObject] recursively on each child. The
  /// [RenderObjectElement.detachRenderObject] override does the actual work of
  /// removing [renderObject] from the render tree.
  ///
  /// This is called by [deactivateChild].
  void detachRenderObject() {
    visitChildren((Element child) {
      child.detachRenderObject();
    });
    _slot = null;
  }

  /// Add [renderObject] to the render tree at the location specified by `newSlot`.
  ///
  /// The default implementation of this function calls
  /// [attachRenderObject] recursively on each child. The
  /// [RenderObjectElement.attachRenderObject] override does the actual work of
  /// adding [renderObject] to the render tree.
  ///
  /// The `newSlot` argument specifies the new value for this element's [slot].
  void attachRenderObject(Object? newSlot) {
    assert(slot == null);
    visitChildren((Element child) {
      child.attachRenderObject(newSlot);
    });
    _slot = newSlot;
  }

  Element? _retakeInactiveElement(GlobalKey key, Widget newWidget) {
    // The "inactivity" of the element being retaken here may be forward-looking: if
    // we are taking an element with a GlobalKey from an element that currently has
    // it as a child, then we know that element will soon no longer have that
    // element as a child. The only way that assumption could be false is if the
    // global key is being duplicated, and we'll try to track that using the
    // _debugTrackElementThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans call below.
    final Element? element = key._currentElement;
    if (element == null) {
      return null;
    }
    if (!Widget.canUpdate(element.widget, newWidget)) {
      return null;
    }
    assert(() {
      if (debugPrintGlobalKeyedWidgetLifecycle) {
        debugPrint(
          'Attempting to take $element from ${element._parent ?? "inactive elements list"} to put in $this.',
        );
      }
      return true;
    }());
    final Element? parent = element._parent;
    if (parent != null) {
      assert(() {
        if (parent == this) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary("A GlobalKey was used multiple times inside one widget's child list."),
            DiagnosticsProperty<GlobalKey>('The offending GlobalKey was', key),
            parent.describeElement('The parent of the widgets with that key was'),
            element.describeElement('The first child to get instantiated with that key became'),
            DiagnosticsProperty<Widget>(
              'The second child that was to be instantiated with that key was',
              widget,
              style: DiagnosticsTreeStyle.errorProperty,
            ),
            ErrorDescription(
              'A GlobalKey can only be specified on one widget at a time in the widget tree.',
            ),
          ]);
        }
        parent.owner!._debugTrackElementThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans(
          parent,
          key,
        );
        return true;
      }());
      parent.forgetChild(element);
      parent.deactivateChild(element);
    }
    assert(element._parent == null);
    owner!._inactiveElements.remove(element);
    return element;
  }

  /// Create an element for the given widget and add it as a child of this
  /// element in the given slot.
  ///
  /// This method is typically called by [updateChild] but can be called
  /// directly by subclasses that need finer-grained control over creating
  /// elements.
  ///
  /// If the given widget has a global key and an element already exists that
  /// has a widget with that global key, this function will reuse that element
  /// (potentially grafting it from another location in the tree or reactivating
  /// it from the list of inactive elements) rather than creating a new element.
  ///
  /// The `newSlot` argument specifies the new value for this element's [slot].
  ///
  /// The element returned by this function will already have been mounted and
  /// will be in the "active" lifecycle state.
  @protected
  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  Element inflateWidget(Widget newWidget, Object? newSlot) {
    final bool isTimelineTracked = !kReleaseMode && _isProfileBuildsEnabledFor(newWidget);
    if (isTimelineTracked) {
      Map<String, String>? debugTimelineArguments;
      assert(() {
        if (kDebugMode && debugEnhanceBuildTimelineArguments) {
          debugTimelineArguments = newWidget.toDiagnosticsNode().toTimelineArguments();
        }
        return true;
      }());
      FlutterTimeline.startSync('${newWidget.runtimeType}', arguments: debugTimelineArguments);
    }

    try {
      final Key? key = newWidget.key;
      if (key is GlobalKey) {
        final Element? newChild = _retakeInactiveElement(key, newWidget);
        if (newChild != null) {
          assert(newChild._parent == null);
          assert(() {
            _debugCheckForCycles(newChild);
            return true;
          }());
          try {
            newChild._activateWithParent(this, newSlot);
          } catch (_) {
            // Attempt to do some clean-up if activation fails to leave tree in a reasonable state.
            try {
              deactivateChild(newChild);
            } catch (_) {
              // Clean-up failed. Only surface original exception.
            }
            rethrow;
          }
          final Element? updatedChild = updateChild(newChild, newWidget, newSlot);
          assert(newChild == updatedChild);
          return updatedChild!;
        }
      }
      final Element newChild = newWidget.createElement();
      assert(() {
        _debugCheckForCycles(newChild);
        return true;
      }());
      newChild.mount(this, newSlot);
      assert(newChild._lifecycleState == _ElementLifecycle.active);

      return newChild;
    } finally {
      if (isTimelineTracked) {
        FlutterTimeline.finishSync();
      }
    }
  }

  void _debugCheckForCycles(Element newChild) {
    assert(newChild._parent == null);
    assert(() {
      Element node = this;
      while (node._parent != null) {
        node = node._parent!;
      }
      assert(node != newChild); // indicates we are about to create a cycle
      return true;
    }());
  }

  /// Move the given element to the list of inactive elements and detach its
  /// render object from the render tree.
  ///
  /// This method stops the given element from being a child of this element by
  /// detaching its render object from the render tree and moving the element to
  /// the list of inactive elements.
  ///
  /// This method (indirectly) calls [deactivate] on the child.
  ///
  /// The caller is responsible for removing the child from its child model.
  /// Typically [deactivateChild] is called by the element itself while it is
  /// updating its child model; however, during [GlobalKey] reparenting, the new
  /// parent proactively calls the old parent's [deactivateChild], first using
  /// [forgetChild] to cause the old parent to update its child model.
  @protected
  void deactivateChild(Element child) {
    assert(child._parent == this);
    child._parent = null;
    child.detachRenderObject();
    owner!._inactiveElements.add(child); // this eventually calls child.deactivate()
    assert(() {
      if (debugPrintGlobalKeyedWidgetLifecycle) {
        if (child.widget.key is GlobalKey) {
          debugPrint('Deactivated $child (keyed child of $this)');
        }
      }
      return true;
    }());
  }

  // The children that have been forgotten by forgetChild. This will be used in
  // [update] to remove the global key reservations of forgotten children.
  //
  // In Profile/Release mode this field is initialized to `null`. The Dart compiler can
  // eliminate unused fields, but not their initializers.
  @_debugOnly
  final Set<Element>? _debugForgottenChildrenWithGlobalKey = kDebugMode ? HashSet<Element>() : null;

  /// Remove the given child from the element's child list, in preparation for
  /// the child being reused elsewhere in the element tree.
  ///
  /// This updates the child model such that, e.g., [visitChildren] does not
  /// walk that child anymore.
  ///
  /// The element will still have a valid parent when this is called, and the
  /// child's [Element.slot] value will be valid in the context of that parent.
  /// After this is called, [deactivateChild] is called to sever the link to
  /// this object.
  ///
  /// The [update] is responsible for updating or creating the new child that
  /// will replace this [child].
  @protected
  @mustCallSuper
  void forgetChild(Element child) {
    // This method is called on the old parent when the given child (with a
    // global key) is given a new parent. We cannot remove the global key
    // reservation directly in this method because the forgotten child is not
    // removed from the tree until this Element is updated in [update]. If
    // [update] is never called, the forgotten child still represents a global
    // key duplication that we need to catch.
    assert(() {
      if (child.widget.key is GlobalKey) {
        _debugForgottenChildrenWithGlobalKey?.add(child);
      }
      return true;
    }());
  }

  void _activateWithParent(Element parent, Object? newSlot) {
    assert(_lifecycleState == _ElementLifecycle.inactive);
    _parent = parent;
    _owner = parent.owner;
    assert(() {
      if (debugPrintGlobalKeyedWidgetLifecycle) {
        debugPrint('Reactivating $this (now child of $_parent).');
      }
      return true;
    }());
    _updateDepth(_parent!.depth);
    _updateBuildScopeRecursively();
    _activateRecursively(this);
    attachRenderObject(newSlot);
    assert(_lifecycleState == _ElementLifecycle.active);
  }

  static void _activateRecursively(Element element) {
    assert(element._lifecycleState == _ElementLifecycle.inactive);
    element.activate();
    assert(element._lifecycleState == _ElementLifecycle.active);
    element.visitChildren(_activateRecursively);
  }

  /// Transition from the "inactive" to the "active" lifecycle state.
  ///
  /// The framework calls this method when a previously deactivated element has
  /// been reincorporated into the tree. The framework does not call this method
  /// the first time an element becomes active (i.e., from the "initial"
  /// lifecycle state). Instead, the framework calls [mount] in that situation.
  ///
  /// See the lifecycle documentation for [Element] for additional information.
  ///
  /// Implementations of this method should start with a call to the inherited
  /// method, as in `super.activate()`.
  @mustCallSuper
  void activate() {
    assert(_lifecycleState == _ElementLifecycle.inactive);
    assert(owner != null);
    final bool hadDependencies =
        (_dependencies?.isNotEmpty ?? false) || _hadUnsatisfiedDependencies;
    _lifecycleState = _ElementLifecycle.active;
    // We unregistered our dependencies in deactivate, but never cleared the list.
    // Since we're going to be reused, let's clear our list now.
    _dependencies?.clear();
    _hadUnsatisfiedDependencies = false;
    _updateInheritance();
    attachNotificationTree();
    if (_dirty) {
      owner!.scheduleBuildFor(this);
    }
    if (hadDependencies) {
      didChangeDependencies();
    }
  }

  /// Transition from the "active" to the "inactive" lifecycle state.
  ///
  /// The framework calls this method when a previously active element is moved
  /// to the list of inactive elements. While in the inactive state, the element
  /// will not appear on screen. The element can remain in the inactive state
  /// only until the end of the current animation frame. At the end of the
  /// animation frame, if the element has not be reactivated, the framework will
  /// unmount the element.
  ///
  /// This is (indirectly) called by [deactivateChild].
  ///
  /// See the lifecycle documentation for [Element] for additional information.
  ///
  /// Implementations of this method should end with a call to the inherited
  /// method, as in `super.deactivate()`.
  @mustCallSuper
  void deactivate() {
    assert(_lifecycleState == _ElementLifecycle.active);
    assert(_widget != null); // Use the private property to avoid a CastError during hot reload.
    if (_dependencies?.isNotEmpty ?? false) {
      for (final InheritedElement dependency in _dependencies!) {
        dependency.removeDependent(this);
      }
      // For expediency, we don't actually clear the list here, even though it's
      // no longer representative of what we are registered with. If we never
      // get re-used, it doesn't matter. If we do, then we'll clear the list in
      // activate(). The benefit of this is that it allows Element's activate()
      // implementation to decide whether to rebuild based on whether we had
      // dependencies here.
    }
    _inheritedElements = null;
    _lifecycleState = _ElementLifecycle.inactive;
  }

  /// Called, in debug mode, after children have been deactivated (see [deactivate]).
  ///
  /// This method is not called in release builds.
  @mustCallSuper
  void debugDeactivated() {
    assert(_lifecycleState == _ElementLifecycle.inactive);
  }

  /// Transition from the "inactive" to the "defunct" lifecycle state.
  ///
  /// Called when the framework determines that an inactive element will never
  /// be reactivated. At the end of each animation frame, the framework calls
  /// [unmount] on any remaining inactive elements, preventing inactive elements
  /// from remaining inactive for longer than a single animation frame.
  ///
  /// After this function is called, the element will not be incorporated into
  /// the tree again.
  ///
  /// Any resources this element holds should be released at this point. For
  /// example, [RenderObjectElement.unmount] calls [RenderObject.dispose] and
  /// nulls out its reference to the render object.
  ///
  /// See the lifecycle documentation for [Element] for additional information.
  ///
  /// Implementations of this method should end with a call to the inherited
  /// method, as in `super.unmount()`.
  @mustCallSuper
  void unmount() {
    assert(_lifecycleState == _ElementLifecycle.inactive);
    assert(_widget != null); // Use the private property to avoid a CastError during hot reload.
    assert(owner != null);
    assert(debugMaybeDispatchDisposed(this));
    // Use the private property to avoid a CastError during hot reload.
    final Key? key = _widget?.key;
    if (key is GlobalKey) {
      owner!._unregisterGlobalKey(key, this);
    }
    // Release resources to reduce the severity of memory leaks caused by
    // defunct, but accidentally retained Elements.
    _widget = null;
    _dependencies = null;
    _lifecycleState = _ElementLifecycle.defunct;
  }

  /// Whether the child in the provided `slot` (or one of its descendants) must
  /// insert a [RenderObject] into its ancestor [RenderObjectElement] by calling
  /// [RenderObjectElement.insertRenderObjectChild] on it.
  ///
  /// This method is used to define non-rendering zones in the element tree (see
  /// [WidgetsBinding] for an explanation of rendering and non-rendering zones):
  ///
  /// Most branches of the [Element] tree are expected to eventually insert a
  /// [RenderObject] into their [RenderObjectElement] ancestor to construct the
  /// render tree. However, there is a notable exception: an [Element] may
  /// expect that the occupant of a certain child slot creates a new independent
  /// render tree and therefore is not allowed to insert a render object into
  /// the existing render tree. Those elements must return false from this
  /// method for the slot in question to signal to the child in that slot that
  /// it must not call [RenderObjectElement.insertRenderObjectChild] on its
  /// ancestor.
  ///
  /// As an example, the element backing the [ViewAnchor] returns false from
  /// this method for the [ViewAnchor.view] slot to enforce that it is occupied
  /// by e.g. a [View] widget, which will ultimately bootstrap a separate
  /// render tree for that view. Another example is the [ViewCollection] widget,
  /// which returns false for all its slots for the same reason.
  ///
  /// Overriding this method is not common, as elements behaving in the way
  /// described above are rare.
  bool debugExpectsRenderObjectForSlot(Object? slot) => true;

  @override
  RenderObject? findRenderObject() {
    assert(() {
      if (_lifecycleState != _ElementLifecycle.active) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Cannot get renderObject of inactive element.'),
          ErrorDescription(
            'In order for an element to have a valid renderObject, it must be '
            'active, which means it is part of the tree.\n'
            'Instead, this element is in the $_lifecycleState state.\n'
            'If you called this method from a State object, consider guarding '
            'it with State.mounted.',
          ),
          describeElement('The findRenderObject() method was called for the following element'),
        ]);
      }
      return true;
    }());
    return renderObject;
  }

  @override
  Size? get size {
    assert(() {
      if (_lifecycleState != _ElementLifecycle.active) {
        // TODO(jacobr): is this a good separation into contract and violation?
        // I have added a line of white space.
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Cannot get size of inactive element.'),
          ErrorDescription(
            'In order for an element to have a valid size, the element must be '
            'active, which means it is part of the tree.\n'
            'Instead, this element is in the $_lifecycleState state.',
          ),
          describeElement('The size getter was called for the following element'),
        ]);
      }
      if (owner!._debugBuilding) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Cannot get size during build.'),
          ErrorDescription(
            'The size of this render object has not yet been determined because '
            'the framework is still in the process of building widgets, which '
            'means the render tree for this frame has not yet been determined. '
            'The size getter should only be called from paint callbacks or '
            'interaction event handlers (e.g. gesture callbacks).',
          ),
          ErrorSpacer(),
          ErrorHint(
            'If you need some sizing information during build to decide which '
            'widgets to build, consider using a LayoutBuilder widget, which can '
            'tell you the layout constraints at a given location in the tree. See '
            '<https://api.flutter.dev/flutter/widgets/LayoutBuilder-class.html> '
            'for more details.',
          ),
          ErrorSpacer(),
          describeElement('The size getter was called for the following element'),
        ]);
      }
      return true;
    }());
    final RenderObject? renderObject = findRenderObject();
    assert(() {
      if (renderObject == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Cannot get size without a render object.'),
          ErrorHint(
            'In order for an element to have a valid size, the element must have '
            'an associated render object. This element does not have an associated '
            'render object, which typically means that the size getter was called '
            'too early in the pipeline (e.g., during the build phase) before the '
            'framework has created the render tree.',
          ),
          describeElement('The size getter was called for the following element'),
        ]);
      }
      if (renderObject is RenderSliver) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Cannot get size from a RenderSliver.'),
          ErrorHint(
            'The render object associated with this element is a '
            '${renderObject.runtimeType}, which is a subtype of RenderSliver. '
            'Slivers do not have a size per se. They have a more elaborate '
            'geometry description, which can be accessed by calling '
            'findRenderObject and then using the "geometry" getter on the '
            'resulting object.',
          ),
          describeElement('The size getter was called for the following element'),
          renderObject.describeForError('The associated render sliver was'),
        ]);
      }
      if (renderObject is! RenderBox) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Cannot get size from a render object that is not a RenderBox.'),
          ErrorHint(
            'Instead of being a subtype of RenderBox, the render object associated '
            'with this element is a ${renderObject.runtimeType}. If this type of '
            'render object does have a size, consider calling findRenderObject '
            'and extracting its size manually.',
          ),
          describeElement('The size getter was called for the following element'),
          renderObject.describeForError('The associated render object was'),
        ]);
      }
      final RenderBox box = renderObject;
      if (!box.hasSize) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Cannot get size from a render object that has not been through layout.'),
          ErrorHint(
            'The size of this render object has not yet been determined because '
            'this render object has not yet been through layout, which typically '
            'means that the size getter was called too early in the pipeline '
            '(e.g., during the build phase) before the framework has determined '
            'the size and position of the render objects during layout.',
          ),
          describeElement('The size getter was called for the following element'),
          box.describeForError('The render object from which the size was to be obtained was'),
        ]);
      }
      if (box.debugNeedsLayout) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'Cannot get size from a render object that has been marked dirty for layout.',
          ),
          ErrorHint(
            'The size of this render object is ambiguous because this render object has '
            'been modified since it was last laid out, which typically means that the size '
            'getter was called too early in the pipeline (e.g., during the build phase) '
            'before the framework has determined the size and position of the render '
            'objects during layout.',
          ),
          describeElement('The size getter was called for the following element'),
          box.describeForError('The render object from which the size was to be obtained was'),
          ErrorHint(
            'Consider using debugPrintMarkNeedsLayoutStacks to determine why the render '
            'object in question is dirty, if you did not expect this.',
          ),
        ]);
      }
      return true;
    }());
    if (renderObject is RenderBox) {
      return renderObject.size;
    }
    return null;
  }

  PersistentHashMap<Type, InheritedElement>? _inheritedElements;
  Set<InheritedElement>? _dependencies;
  bool _hadUnsatisfiedDependencies = false;

  bool _debugCheckStateIsActiveForAncestorLookup() {
    assert(() {
      if (_lifecycleState != _ElementLifecycle.active) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary("Looking up a deactivated widget's ancestor is unsafe."),
          ErrorDescription(
            "At this point the state of the widget's element tree is no longer "
            'stable.',
          ),
          ErrorHint(
            "To safely refer to a widget's ancestor in its dispose() method, "
            'save a reference to the ancestor by calling dependOnInheritedWidgetOfExactType() '
            "in the widget's didChangeDependencies() method.",
          ),
        ]);
      }
      return true;
    }());
    return true;
  }

  /// Returns `true` if [dependOnInheritedElement] was previously called with [ancestor].
  @protected
  bool doesDependOnInheritedElement(InheritedElement ancestor) {
    return _dependencies?.contains(ancestor) ?? false;
  }

  @override
  InheritedWidget dependOnInheritedElement(InheritedElement ancestor, {Object? aspect}) {
    _dependencies ??= HashSet<InheritedElement>();
    _dependencies!.add(ancestor);
    ancestor.updateDependencies(this, aspect);
    return ancestor.widget as InheritedWidget;
  }

  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({Object? aspect}) {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    final InheritedElement? ancestor = _inheritedElements?[T];
    if (ancestor != null) {
      return dependOnInheritedElement(ancestor, aspect: aspect) as T;
    }
    _hadUnsatisfiedDependencies = true;
    return null;
  }

  @override
  T? getInheritedWidgetOfExactType<T extends InheritedWidget>() {
    return getElementForInheritedWidgetOfExactType<T>()?.widget as T?;
  }

  @override
  InheritedElement? getElementForInheritedWidgetOfExactType<T extends InheritedWidget>() {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    return _inheritedElements?[T];
  }

  /// Called in [Element.mount] and [Element.activate] to register this element in
  /// the notification tree.
  ///
  /// This method is only exposed so that [NotifiableElementMixin] can be implemented.
  /// Subclasses of [Element] that wish to respond to notifications should mix that
  /// in instead.
  ///
  /// See also:
  ///   * [NotificationListener], a widget that allows listening to notifications.
  @protected
  void attachNotificationTree() {
    _notificationTree = _parent?._notificationTree;
  }

  void _updateInheritance() {
    assert(_lifecycleState == _ElementLifecycle.active);
    _inheritedElements = _parent?._inheritedElements;
  }

  @override
  T? findAncestorWidgetOfExactType<T extends Widget>() {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    Element? ancestor = _parent;
    while (ancestor != null && ancestor.widget.runtimeType != T) {
      ancestor = ancestor._parent;
    }
    return ancestor?.widget as T?;
  }

  @override
  T? findAncestorStateOfType<T extends State<StatefulWidget>>() {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    Element? ancestor = _parent;
    while (ancestor != null) {
      if (ancestor is StatefulElement && ancestor.state is T) {
        break;
      }
      ancestor = ancestor._parent;
    }
    final StatefulElement? statefulAncestor = ancestor as StatefulElement?;
    return statefulAncestor?.state as T?;
  }

  @override
  T? findRootAncestorStateOfType<T extends State<StatefulWidget>>() {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    Element? ancestor = _parent;
    StatefulElement? statefulAncestor;
    while (ancestor != null) {
      if (ancestor is StatefulElement && ancestor.state is T) {
        statefulAncestor = ancestor;
      }
      ancestor = ancestor._parent;
    }
    return statefulAncestor?.state as T?;
  }

  @override
  T? findAncestorRenderObjectOfType<T extends RenderObject>() {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    Element? ancestor = _parent;
    while (ancestor != null) {
      if (ancestor is RenderObjectElement && ancestor.renderObject is T) {
        return ancestor.renderObject as T;
      }
      ancestor = ancestor._parent;
    }
    return null;
  }

  @override
  void visitAncestorElements(ConditionalElementVisitor visitor) {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    Element? ancestor = _parent;
    while (ancestor != null && visitor(ancestor)) {
      ancestor = ancestor._parent;
    }
  }

  /// Called when a dependency of this element changes.
  ///
  /// The [dependOnInheritedWidgetOfExactType] registers this element as depending on
  /// inherited information of the given type. When the information of that type
  /// changes at this location in the tree (e.g., because the [InheritedElement]
  /// updated to a new [InheritedWidget] and
  /// [InheritedWidget.updateShouldNotify] returned true), the framework calls
  /// this function to notify this element of the change.
  @mustCallSuper
  void didChangeDependencies() {
    assert(_lifecycleState == _ElementLifecycle.active); // otherwise markNeedsBuild is a no-op
    assert(_debugCheckOwnerBuildTargetExists('didChangeDependencies'));
    markNeedsBuild();
  }

  bool _debugCheckOwnerBuildTargetExists(String methodName) {
    assert(() {
      if (owner!._debugCurrentBuildTarget == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            '$methodName for ${widget.runtimeType} was called at an '
            'inappropriate time.',
          ),
          ErrorDescription('It may only be called while the widgets are being built.'),
          ErrorHint(
            'A possible cause of this error is when $methodName is called during '
            'one of:\n'
            ' * network I/O event\n'
            ' * file I/O event\n'
            ' * timer\n'
            ' * microtask (caused by Future.then, async/await, scheduleMicrotask)',
          ),
        ]);
      }
      return true;
    }());
    return true;
  }

  /// Returns a description of what caused this element to be created.
  ///
  /// Useful for debugging the source of an element.
  String debugGetCreatorChain(int limit) {
    final List<String> chain = <String>[];
    Element? node = this;
    while (chain.length < limit && node != null) {
      chain.add(node.toStringShort());
      node = node._parent;
    }
    if (node != null) {
      chain.add('\u22EF');
    }
    return chain.join(' \u2190 ');
  }

  /// Returns the parent chain from this element back to the root of the tree.
  ///
  /// Useful for debug display of a tree of Elements with only nodes in the path
  /// from the root to this Element expanded.
  List<Element> debugGetDiagnosticChain() {
    final List<Element> chain = <Element>[this];
    Element? node = _parent;
    while (node != null) {
      chain.add(node);
      node = node._parent;
    }
    return chain;
  }

  @override
  void dispatchNotification(Notification notification) {
    _notificationTree?.dispatchNotification(notification);
  }

  /// A short, textual description of this element.
  @override
  String toStringShort() => _widget?.toStringShort() ?? '${describeIdentity(this)}(DEFUNCT)';

  @override
  DiagnosticsNode toDiagnosticsNode({String? name, DiagnosticsTreeStyle? style}) {
    return _ElementDiagnosticableTreeNode(name: name, value: this, style: style);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.defaultDiagnosticsTreeStyle = DiagnosticsTreeStyle.dense;
    if (_lifecycleState != _ElementLifecycle.initial) {
      properties.add(ObjectFlagProperty<int>('depth', depth, ifNull: 'no depth'));
    }
    properties.add(ObjectFlagProperty<Widget>('widget', _widget, ifNull: 'no widget'));
    properties.add(
      DiagnosticsProperty<Key>(
        'key',
        _widget?.key,
        showName: false,
        defaultValue: null,
        level: DiagnosticLevel.hidden,
      ),
    );
    _widget?.debugFillProperties(properties);
    properties.add(FlagProperty('dirty', value: dirty, ifTrue: 'dirty'));
    final Set<InheritedElement>? deps = _dependencies;
    if (deps != null && deps.isNotEmpty) {
      final List<InheritedElement> sortedDependencies =
          deps.toList()..sort(
            (InheritedElement a, InheritedElement b) =>
                a.toStringShort().compareTo(b.toStringShort()),
          );
      final List<DiagnosticsNode> diagnosticsDependencies =
          sortedDependencies
              .map(
                (InheritedElement element) =>
                    element.widget.toDiagnosticsNode(style: DiagnosticsTreeStyle.sparse),
              )
              .toList();
      properties.add(
        DiagnosticsProperty<Set<InheritedElement>>(
          'dependencies',
          deps,
          description: diagnosticsDependencies.toString(),
        ),
      );
    }
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    visitChildren((Element child) {
      children.add(child.toDiagnosticsNode());
    });
    return children;
  }

  /// Returns true if the element has been marked as needing rebuilding.
  ///
  /// The flag is true when the element is first created and after
  /// [markNeedsBuild] has been called. The flag is typically reset to false in
  /// the [performRebuild] implementation, but certain elements (that of the
  /// [LayoutBuilder] widget, for example) may choose to override [markNeedsBuild]
  /// such that it does not set the [dirty] flag to `true` when called.
  bool get dirty => _dirty;
  bool _dirty = true;

  // Whether this is in _buildScope._dirtyElements. This is used to know whether
  // we should be adding the element back into the list when it's reactivated.
  bool _inDirtyList = false;

  // Whether we've already built or not. Set in [rebuild].
  bool _debugBuiltOnce = false;

  /// Marks the element as dirty and adds it to the global list of widgets to
  /// rebuild in the next frame.
  ///
  /// Since it is inefficient to build an element twice in one frame,
  /// applications and widgets should be structured so as to only mark
  /// widgets dirty during event handlers before the frame begins, not during
  /// the build itself.
  void markNeedsBuild() {
    assert(_lifecycleState != _ElementLifecycle.defunct);
    if (_lifecycleState != _ElementLifecycle.active) {
      return;
    }
    assert(owner != null);
    assert(_lifecycleState == _ElementLifecycle.active);
    assert(() {
      if (owner!._debugBuilding) {
        assert(owner!._debugCurrentBuildTarget != null);
        assert(owner!._debugStateLocked);
        if (_debugIsDescendantOf(owner!._debugCurrentBuildTarget!)) {
          return true;
        }
        final List<DiagnosticsNode> information = <DiagnosticsNode>[
          ErrorSummary('setState() or markNeedsBuild() called during build.'),
          ErrorDescription(
            'This ${widget.runtimeType} widget cannot be marked as needing to build because the framework '
            'is already in the process of building widgets. A widget can be marked as '
            'needing to be built during the build phase only if one of its ancestors '
            'is currently building. This exception is allowed because the framework '
            'builds parent widgets before children, which means a dirty descendant '
            'will always be built. Otherwise, the framework might not visit this '
            'widget during this build phase.',
          ),
          describeElement('The widget on which setState() or markNeedsBuild() was called was'),
        ];
        if (owner!._debugCurrentBuildTarget != null) {
          information.add(
            owner!._debugCurrentBuildTarget!.describeWidget(
              'The widget which was currently being built when the offending call was made was',
            ),
          );
        }
        throw FlutterError.fromParts(information);
      } else if (owner!._debugStateLocked) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('setState() or markNeedsBuild() called when widget tree was locked.'),
          ErrorDescription(
            'This ${widget.runtimeType} widget cannot be marked as needing to build '
            'because the framework is locked.',
          ),
          describeElement('The widget on which setState() or markNeedsBuild() was called was'),
        ]);
      }
      return true;
    }());
    if (dirty) {
      return;
    }
    _dirty = true;
    owner!.scheduleBuildFor(this);
  }

  /// Cause the widget to update itself. In debug builds, also verify various
  /// invariants.
  ///
  /// Called by the [BuildOwner] when [BuildOwner.scheduleBuildFor] has been
  /// called to mark this element dirty, by [mount] when the element is first
  /// built, and by [update] when the widget has changed.
  ///
  /// The method will only rebuild if [dirty] is true. To rebuild regardless
  /// of the [dirty] flag, set `force` to true. Forcing a rebuild is convenient
  /// from [update], during which [dirty] is false.
  ///
  /// ## When rebuilds happen
  ///
  /// ### Terminology
  ///
  /// [Widget]s represent the configuration of [Element]s. Each [Element] has a
  /// widget, specified in [Element.widget]. The term "widget" is often used
  /// when strictly speaking "element" would be more correct.
  ///
  /// While an [Element] has a current [Widget], over time, that widget may be
  /// replaced by others. For example, the element backing a [ColoredBox] may
  /// first have as its widget a [ColoredBox] whose [ColoredBox.color] is blue,
  /// then later be given a new [ColoredBox] whose color is green.
  ///
  /// At any particular time, multiple [Element]s in the same tree may have the
  /// same [Widget]. For example, the same [ColoredBox] with the green color may
  /// be used in multiple places in the widget tree at the same time, each being
  /// backed by a different [Element].
  ///
  /// ### Marking an element dirty
  ///
  /// An [Element] can be marked dirty between frames. This can happen for various
  /// reasons, including the following:
  ///
  /// * The [State] of a [StatefulWidget] can cause its [Element] to be marked
  ///   dirty by calling the [State.setState] method.
  ///
  /// * When an [InheritedWidget] changes, descendants that have previously
  ///   subscribed to it will be marked dirty.
  ///
  /// * During a hot reload, every element is marked dirty (using [Element.reassemble]).
  ///
  /// ### Rebuilding
  ///
  /// Dirty elements are rebuilt during the next frame. Precisely how this is
  /// done depends on the kind of element. A [StatelessElement] rebuilds by
  /// using its widget's [StatelessWidget.build] method. A [StatefulElement]
  /// rebuilds by using its widget's state's [State.build] method. A
  /// [RenderObjectElement] rebuilds by updating its [RenderObject].
  ///
  /// In many cases, the end result of rebuilding is a single child widget
  /// or (for [MultiChildRenderObjectElement]s) a list of children widgets.
  ///
  /// These child widgets are used to update the [widget] property of the
  /// element's child (or children) elements. The new [Widget] is considered to
  /// correspond to an existing [Element] if it has the same [Type] and [Key].
  /// (In the case of [MultiChildRenderObjectElement]s, some effort is put into
  /// tracking widgets even when they change order; see
  /// [RenderObjectElement.updateChildren].)
  ///
  /// If there was no corresponding previous child, this results in a new
  /// [Element] being created (using [Widget.createElement]); that element is
  /// then itself built, recursively.
  ///
  /// If there was a child previously but the build did not provide a
  /// corresponding child to update it, then the old child is discarded (or, in
  /// cases involving [GlobalKey] reparenting, reused elsewhere in the element
  /// tree).
  ///
  /// The most common case, however, is that there was a corresponding previous
  /// child. This is handled by asking the child [Element] to update itself
  /// using the new child [Widget]. In the case of [StatefulElement]s, this
  /// is what triggers [State.didUpdateWidget].
  ///
  /// ### Not rebuilding
  ///
  /// Before an [Element] is told to update itself with a new [Widget], the old
  /// and new objects are compared using `operator ==`.
  ///
  /// In general, this is equivalent to doing a comparison using [identical] to
  /// see if the two objects are in fact the exact same instance. If they are,
  /// and if the element is not already marked dirty for other reasons, then the
  /// element skips updating itself as it can determine with certainty that
  /// there would be no value in updating itself or its descendants.
  ///
  /// It is strongly advised to avoid overriding `operator ==` on [Widget]
  /// objects. While doing so seems like it could improve performance, in
  /// practice, for non-leaf widgets, it results in O(N²) behavior. This is
  /// because by necessity the comparison would have to include comparing child
  /// widgets, and if those child widgets also implement `operator ==`, it
  /// ultimately results in a complete walk of the widget tree... which is then
  /// repeated at each level of the tree. In practice, just rebuilding is
  /// cheaper. (Additionally, if _any_ subclass of [Widget] used in an
  /// application implements `operator ==`, then the compiler cannot inline the
  /// comparison anywhere, because it has to treat the call as virtual just in
  /// case the instance happens to be one that has an overridden operator.)
  ///
  /// Instead, the best way to avoid unnecessary rebuilds is to cache the
  /// widgets that are returned from [State.build], so that each frame the same
  /// widgets are used until such time as they change. Several mechanisms exist
  /// to encourage this: `const` widgets, for example, are a form of automatic
  /// caching (if a widget is constructed using the `const` keyword, the same
  /// instance is returned each time it is constructed with the same arguments).
  ///
  /// Another example is the [AnimatedBuilder.child] property, which allows the
  /// non-animating parts of a subtree to remain static even as the
  /// [AnimatedBuilder.builder] callback recreates the other components.
  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  void rebuild({bool force = false}) {
    assert(_lifecycleState != _ElementLifecycle.initial);
    if (_lifecycleState != _ElementLifecycle.active || (!_dirty && !force)) {
      return;
    }
    assert(() {
      debugOnRebuildDirtyWidget?.call(this, _debugBuiltOnce);
      if (debugPrintRebuildDirtyWidgets) {
        if (!_debugBuiltOnce) {
          debugPrint('Building $this');
          _debugBuiltOnce = true;
        } else {
          debugPrint('Rebuilding $this');
        }
      }
      return true;
    }());
    assert(_lifecycleState == _ElementLifecycle.active);
    assert(owner!._debugStateLocked);
    Element? debugPreviousBuildTarget;
    assert(() {
      debugPreviousBuildTarget = owner!._debugCurrentBuildTarget;
      owner!._debugCurrentBuildTarget = this;
      return true;
    }());
    try {
      performRebuild();
    } finally {
      assert(() {
        owner!._debugElementWasRebuilt(this);
        assert(owner!._debugCurrentBuildTarget == this);
        owner!._debugCurrentBuildTarget = debugPreviousBuildTarget;
        return true;
      }());
    }
    assert(!_dirty);
  }

  /// Cause the widget to update itself.
  ///
  /// Called by [rebuild] after the appropriate checks have been made.
  ///
  /// The base implementation only clears the [dirty] flag.
  @protected
  @mustCallSuper
  void performRebuild() {
    _dirty = false;
  }
}

class _ElementDiagnosticableTreeNode extends DiagnosticableTreeNode {
  _ElementDiagnosticableTreeNode({
    super.name,
    required Element super.value,
    required super.style,
    this.stateful = false,
  });

  final bool stateful;

  @override
  Map<String, Object?> toJsonMap(DiagnosticsSerializationDelegate delegate) {
    final Map<String, Object?> json = super.toJsonMap(delegate);
    final Element element = value as Element;
    if (!element.debugIsDefunct) {
      json['widgetRuntimeType'] = element.widget.runtimeType.toString();
    }
    json['stateful'] = stateful;
    return json;
  }
}

/// Signature for the constructor that is called when an error occurs while
/// building a widget.
///
/// The argument provides information regarding the cause of the error.
///
/// See also:
///
///  * [ErrorWidget.builder], which can be set to override the default
///    [ErrorWidget] builder.
///  * [FlutterError.reportError], which is typically called with the same
///    [FlutterErrorDetails] object immediately prior to [ErrorWidget.builder]
///    being called.
typedef ErrorWidgetBuilder = Widget Function(FlutterErrorDetails details);

/// A widget that renders an exception's message.
///
/// This widget is used when a build method fails, to help with determining
/// where the problem lies. Exceptions are also logged to the console, which you
/// can read using `flutter logs`. The console will also include additional
/// information such as the stack trace for the exception.
///
/// It is possible to override this widget.
///
/// {@tool dartpad}
/// This example shows how to override the standard error widget builder in release
/// mode, but use the standard one in debug mode.
///
/// The error occurs when you click the "Error Prone" button.
///
/// ** See code in examples/api/lib/widgets/framework/error_widget.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [FlutterError.onError], which can be set to a method that exits the
///    application if that is preferable to showing an error message.
///  * <https://docs.flutter.dev/testing/errors>, more information about error
///    handling in Flutter.
class ErrorWidget extends LeafRenderObjectWidget {
  /// Creates a widget that displays the given exception.
  ///
  /// The message will be the stringification of the given exception, unless
  /// computing that value itself throws an exception, in which case it will
  /// be the string "Error".
  ///
  /// If this object is inspected from an IDE or the devtools, and the original
  /// exception is a [FlutterError] object, the original exception itself will
  /// be shown in the inspection output.
  ErrorWidget(Object exception)
    : message = _stringify(exception),
      _flutterError = exception is FlutterError ? exception : null,
      super(key: UniqueKey());

  /// Creates a widget that displays the given error message.
  ///
  /// An explicit [FlutterError] can be provided to be reported to inspection
  /// tools. It need not match the message.
  ErrorWidget.withDetails({this.message = '', FlutterError? error})
    : _flutterError = error,
      super(key: UniqueKey());

  /// The configurable factory for [ErrorWidget].
  ///
  /// When an error occurs while building a widget, the broken widget is
  /// replaced by the widget returned by this function. By default, an
  /// [ErrorWidget] is returned.
  ///
  /// The system is typically in an unstable state when this function is called.
  /// An exception has just been thrown in the middle of build (and possibly
  /// layout), so surrounding widgets and render objects may be in a rather
  /// fragile state. The framework itself (especially the [BuildOwner]) may also
  /// be confused, and additional exceptions are quite likely to be thrown.
  ///
  /// Because of this, it is highly recommended that the widget returned from
  /// this function perform the least amount of work possible. A
  /// [LeafRenderObjectWidget] is the best choice, especially one that
  /// corresponds to a [RenderBox] that can handle the most absurd of incoming
  /// constraints. The default constructor maps to a [RenderErrorBox].
  ///
  /// The default behavior is to show the exception's message in debug mode,
  /// and to show nothing but a gray background in release builds.
  ///
  /// See also:
  ///
  ///  * [FlutterError.onError], which is typically called with the same
  ///    [FlutterErrorDetails] object immediately prior to this callback being
  ///    invoked, and which can also be configured to control how errors are
  ///    reported.
  ///  * <https://docs.flutter.dev/testing/errors>, more information about error
  ///    handling in Flutter.
  static ErrorWidgetBuilder builder = _defaultErrorWidgetBuilder;

  static Widget _defaultErrorWidgetBuilder(FlutterErrorDetails details) {
    String message = '';
    assert(() {
      message =
          '${_stringify(details.exception)}\nSee also: https://docs.flutter.dev/testing/errors';
      return true;
    }());
    final Object exception = details.exception;
    return ErrorWidget.withDetails(
      message: message,
      error: exception is FlutterError ? exception : null,
    );
  }

  static String _stringify(Object? exception) {
    try {
      return exception.toString();
    } catch (error) {
      // If we get here, it means things have really gone off the rails, and we're better
      // off just returning a simple string and letting the developer find out what the
      // root cause of all their problems are by looking at the console logs.
    }
    return 'Error';
  }

  /// The message to display.
  final String message;
  final FlutterError? _flutterError;

  @override
  RenderBox createRenderObject(BuildContext context) => RenderErrorBox(message);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (_flutterError == null) {
      properties.add(StringProperty('message', message, quoted: false));
    } else {
      properties.add(_flutterError.toDiagnosticsNode(style: DiagnosticsTreeStyle.whitespace));
    }
  }
}

/// Signature for a function that creates a widget, e.g. [StatelessWidget.build]
/// or [State.build].
///
/// Used by [Builder.builder], [OverlayEntry.builder], etc.
///
/// See also:
///
///  * [IndexedWidgetBuilder], which is similar but also takes an index.
///  * [TransitionBuilder], which is similar but also takes a child.
///  * [ValueWidgetBuilder], which is similar but takes a value and a child.
typedef WidgetBuilder = Widget Function(BuildContext context);

/// Signature for a function that creates a widget for a given index, e.g., in a
/// list.
///
/// Used by [ListView.builder] and other APIs that use lazily-generated widgets.
///
/// See also:
///
///  * [WidgetBuilder], which is similar but only takes a [BuildContext].
///  * [TransitionBuilder], which is similar but also takes a child.
///  * [NullableIndexedWidgetBuilder], which is similar but may return null.
typedef IndexedWidgetBuilder = Widget Function(BuildContext context, int index);

/// Signature for a function that creates a widget for a given index, e.g., in a
/// list, but may return null.
///
/// Used by [SliverChildBuilderDelegate.builder] and other APIs that
/// use lazily-generated widgets where the child count is not known
/// ahead of time.
///
/// Unlike most builders, this callback can return null, indicating the index
/// is out of range. Whether and when this is valid depends on the semantics
/// of the builder. For example, [SliverChildBuilderDelegate.builder] returns
/// null when the index is out of range, where the range is defined by the
/// [SliverChildBuilderDelegate.childCount]; so in that case the `index`
/// parameter's value may determine whether returning null is valid or not.
///
/// See also:
///
///  * [WidgetBuilder], which is similar but only takes a [BuildContext].
///  * [TransitionBuilder], which is similar but also takes a child.
///  * [IndexedWidgetBuilder], which is similar but not nullable.
typedef NullableIndexedWidgetBuilder = Widget? Function(BuildContext context, int index);

/// A builder that builds a widget given a child.
///
/// The child should typically be part of the returned widget tree.
///
/// Used by [AnimatedBuilder.builder], [ListenableBuilder.builder],
/// [WidgetsApp.builder], and [MaterialApp.builder].
///
/// See also:
///
/// * [WidgetBuilder], which is similar but only takes a [BuildContext].
/// * [IndexedWidgetBuilder], which is similar but also takes an index.
/// * [ValueWidgetBuilder], which is similar but takes a value and a child.
typedef TransitionBuilder = Widget Function(BuildContext context, Widget? child);

/// An [Element] that composes other [Element]s.
///
/// Rather than creating a [RenderObject] directly, a [ComponentElement] creates
/// [RenderObject]s indirectly by creating other [Element]s.
///
/// Contrast with [RenderObjectElement].
abstract class ComponentElement extends Element {
  /// Creates an element that uses the given widget as its configuration.
  ComponentElement(super.widget);

  Element? _child;

  bool _debugDoingBuild = false;
  @override
  bool get debugDoingBuild => _debugDoingBuild;

  @override
  Element? get renderObjectAttachingChild => _child;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    assert(_child == null);
    assert(_lifecycleState == _ElementLifecycle.active);
    _firstBuild();
    assert(_child != null);
  }

  void _firstBuild() {
    // StatefulElement overrides this to also call state.didChangeDependencies.
    rebuild(); // This eventually calls performRebuild.
  }

  /// Calls the [StatelessWidget.build] method of the [StatelessWidget] object
  /// (for stateless widgets) or the [State.build] method of the [State] object
  /// (for stateful widgets) and then updates the widget tree.
  ///
  /// Called automatically during [mount] to generate the first build, and by
  /// [rebuild] when the element needs updating.
  @override
  @pragma('vm:notify-debugger-on-exception')
  void performRebuild() {
    Widget? built;
    try {
      assert(() {
        _debugDoingBuild = true;
        return true;
      }());
      built = build();
      assert(() {
        _debugDoingBuild = false;
        return true;
      }());
      debugWidgetBuilderValue(widget, built);
    } catch (e, stack) {
      _debugDoingBuild = false;
      built = ErrorWidget.builder(
        _reportException(
          ErrorDescription('building $this'),
          e,
          stack,
          informationCollector:
              () => <DiagnosticsNode>[if (kDebugMode) DiagnosticsDebugCreator(DebugCreator(this))],
        ),
      );
    } finally {
      // We delay marking the element as clean until after calling build() so
      // that attempts to markNeedsBuild() during build() will be ignored.
      super.performRebuild(); // clears the "dirty" flag
    }
    try {
      _child = updateChild(_child, built, slot);
      assert(_child != null);
    } catch (e, stack) {
      built = ErrorWidget.builder(
        _reportException(
          ErrorDescription('building $this'),
          e,
          stack,
          informationCollector:
              () => <DiagnosticsNode>[if (kDebugMode) DiagnosticsDebugCreator(DebugCreator(this))],
        ),
      );
      _child = updateChild(null, built, slot);
    }
  }

  /// Subclasses should override this function to actually call the appropriate
  /// `build` function (e.g., [StatelessWidget.build] or [State.build]) for
  /// their widget.
  @protected
  Widget build();

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null) {
      visitor(_child!);
    }
  }

  @override
  void forgetChild(Element child) {
    assert(child == _child);
    _child = null;
    super.forgetChild(child);
  }
}

/// An [Element] that uses a [StatelessWidget] as its configuration.
class StatelessElement extends ComponentElement {
  /// Creates an element that uses the given widget as its configuration.
  StatelessElement(StatelessWidget super.widget);

  @override
  Widget build() => (widget as StatelessWidget).build(this);

  @override
  void update(StatelessWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    rebuild(force: true);
  }
}

/// An [Element] that uses a [StatefulWidget] as its configuration.
class StatefulElement extends ComponentElement {
  /// Creates an element that uses the given widget as its configuration.
  StatefulElement(StatefulWidget widget) : _state = widget.createState(), super(widget) {
    assert(() {
      if (!state._debugTypesAreRight(widget)) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'StatefulWidget.createState must return a subtype of State<${widget.runtimeType}>',
          ),
          ErrorDescription(
            'The createState function for ${widget.runtimeType} returned a state '
            'of type ${state.runtimeType}, which is not a subtype of '
            'State<${widget.runtimeType}>, violating the contract for createState.',
          ),
        ]);
      }
      return true;
    }());
    assert(state._element == null);
    state._element = this;
    assert(
      state._widget == null,
      'The createState function for $widget returned an old or invalid state '
      'instance: ${state._widget}, which is not null, violating the contract '
      'for createState.',
    );
    state._widget = widget;
    assert(state._debugLifecycleState == _StateLifecycle.created);
  }

  @override
  Widget build() => state.build(this);

  /// The [State] instance associated with this location in the tree.
  ///
  /// There is a one-to-one relationship between [State] objects and the
  /// [StatefulElement] objects that hold them. The [State] objects are created
  /// by [StatefulElement] in [mount].
  State<StatefulWidget> get state => _state!;
  State<StatefulWidget>? _state;

  @override
  void reassemble() {
    state.reassemble();
    super.reassemble();
  }

  @override
  void _firstBuild() {
    assert(state._debugLifecycleState == _StateLifecycle.created);
    final Object? debugCheckForReturnedFuture = state.initState() as dynamic;
    assert(() {
      if (debugCheckForReturnedFuture is Future) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('${state.runtimeType}.initState() returned a Future.'),
          ErrorDescription('State.initState() must be a void method without an `async` keyword.'),
          ErrorHint(
            'Rather than awaiting on asynchronous work directly inside of initState, '
            'call a separate method to do this work without awaiting it.',
          ),
        ]);
      }
      return true;
    }());
    assert(() {
      state._debugLifecycleState = _StateLifecycle.initialized;
      return true;
    }());
    state.didChangeDependencies();
    assert(() {
      state._debugLifecycleState = _StateLifecycle.ready;
      return true;
    }());
    super._firstBuild();
  }

  @override
  void performRebuild() {
    if (_didChangeDependencies) {
      state.didChangeDependencies();
      _didChangeDependencies = false;
    }
    super.performRebuild();
  }

  @override
  void update(StatefulWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    final StatefulWidget oldWidget = state._widget!;
    state._widget = widget as StatefulWidget;
    final Object? debugCheckForReturnedFuture = state.didUpdateWidget(oldWidget) as dynamic;
    assert(() {
      if (debugCheckForReturnedFuture is Future) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('${state.runtimeType}.didUpdateWidget() returned a Future.'),
          ErrorDescription(
            'State.didUpdateWidget() must be a void method without an `async` keyword.',
          ),
          ErrorHint(
            'Rather than awaiting on asynchronous work directly inside of didUpdateWidget, '
            'call a separate method to do this work without awaiting it.',
          ),
        ]);
      }
      return true;
    }());
    rebuild(force: true);
  }

  @override
  void activate() {
    super.activate();
    state.activate();
    // Since the State could have observed the deactivate() and thus disposed of
    // resources allocated in the build method, we have to rebuild the widget
    // so that its State can reallocate its resources.
    assert(_lifecycleState == _ElementLifecycle.active); // otherwise markNeedsBuild is a no-op
    markNeedsBuild();
  }

  @override
  void deactivate() {
    state.deactivate();
    super.deactivate();
  }

  @override
  void unmount() {
    super.unmount();
    state.dispose();
    assert(() {
      if (state._debugLifecycleState == _StateLifecycle.defunct) {
        return true;
      }
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('${state.runtimeType}.dispose failed to call super.dispose.'),
        ErrorDescription(
          'dispose() implementations must always call their superclass dispose() method, to ensure '
          'that all the resources used by the widget are fully released.',
        ),
      ]);
    }());
    state._element = null;
    // Release resources to reduce the severity of memory leaks caused by
    // defunct, but accidentally retained Elements.
    _state = null;
  }

  @override
  InheritedWidget dependOnInheritedElement(Element ancestor, {Object? aspect}) {
    assert(() {
      final Type targetType = ancestor.widget.runtimeType;
      if (state._debugLifecycleState == _StateLifecycle.created) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'dependOnInheritedWidgetOfExactType<$targetType>() or dependOnInheritedElement() was called before ${state.runtimeType}.initState() completed.',
          ),
          ErrorDescription(
            'When an inherited widget changes, for example if the value of Theme.of() changes, '
            "its dependent widgets are rebuilt. If the dependent widget's reference to "
            'the inherited widget is in a constructor or an initState() method, '
            'then the rebuilt dependent widget will not reflect the changes in the '
            'inherited widget.',
          ),
          ErrorHint(
            'Typically references to inherited widgets should occur in widget build() methods. Alternatively, '
            'initialization based on inherited widgets can be placed in the didChangeDependencies method, which '
            'is called after initState and whenever the dependencies change thereafter.',
          ),
        ]);
      }
      if (state._debugLifecycleState == _StateLifecycle.defunct) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'dependOnInheritedWidgetOfExactType<$targetType>() or dependOnInheritedElement() was called after dispose(): $this',
          ),
          ErrorDescription(
            'This error happens if you call dependOnInheritedWidgetOfExactType() on the '
            'BuildContext for a widget that no longer appears in the widget tree '
            '(e.g., whose parent widget no longer includes the widget in its '
            'build). This error can occur when code calls '
            'dependOnInheritedWidgetOfExactType() from a timer or an animation callback.',
          ),
          ErrorHint(
            'The preferred solution is to cancel the timer or stop listening to the '
            'animation in the dispose() callback. Another solution is to check the '
            '"mounted" property of this object before calling '
            'dependOnInheritedWidgetOfExactType() to ensure the object is still in the '
            'tree.',
          ),
          ErrorHint(
            'This error might indicate a memory leak if '
            'dependOnInheritedWidgetOfExactType() is being called because another object '
            'is retaining a reference to this State object after it has been '
            'removed from the tree. To avoid memory leaks, consider breaking the '
            'reference to this object during dispose().',
          ),
        ]);
      }
      return true;
    }());
    return super.dependOnInheritedElement(ancestor as InheritedElement, aspect: aspect);
  }

  /// This controls whether we should call [State.didChangeDependencies] from
  /// the start of [build], to avoid calls when the [State] will not get built.
  /// This can happen when the widget has dropped out of the tree, but depends
  /// on an [InheritedWidget] that is still in the tree.
  ///
  /// It is set initially to false, since [_firstBuild] makes the initial call
  /// on the [state]. When it is true, [build] will call
  /// `state.didChangeDependencies` and then sets it to false. Subsequent calls
  /// to [didChangeDependencies] set it to true.
  bool _didChangeDependencies = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _didChangeDependencies = true;
  }

  @override
  DiagnosticsNode toDiagnosticsNode({String? name, DiagnosticsTreeStyle? style}) {
    return _ElementDiagnosticableTreeNode(name: name, value: this, style: style, stateful: true);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<State<StatefulWidget>>('state', _state, defaultValue: null));
  }
}

/// An [Element] that uses a [ProxyWidget] as its configuration.
abstract class ProxyElement extends ComponentElement {
  /// Initializes fields for subclasses.
  ProxyElement(ProxyWidget super.widget);

  @override
  Widget build() => (widget as ProxyWidget).child;

  @override
  void update(ProxyWidget newWidget) {
    final ProxyWidget oldWidget = widget as ProxyWidget;
    assert(widget != newWidget);
    super.update(newWidget);
    assert(widget == newWidget);
    updated(oldWidget);
    rebuild(force: true);
  }

  /// Called during build when the [widget] has changed.
  ///
  /// By default, calls [notifyClients]. Subclasses may override this method to
  /// avoid calling [notifyClients] unnecessarily (e.g. if the old and new
  /// widgets are equivalent).
  @protected
  void updated(covariant ProxyWidget oldWidget) {
    notifyClients(oldWidget);
  }

  /// Notify other objects that the widget associated with this element has
  /// changed.
  ///
  /// Called during [update] (via [updated]) after changing the widget
  /// associated with this element but before rebuilding this element.
  @protected
  void notifyClients(covariant ProxyWidget oldWidget);
}

/// An [Element] that uses a [ParentDataWidget] as its configuration.
class ParentDataElement<T extends ParentData> extends ProxyElement {
  /// Creates an element that uses the given widget as its configuration.
  ParentDataElement(ParentDataWidget<T> super.widget);

  /// Returns the [Type] of [ParentData] that this element has been configured
  /// for.
  ///
  /// This is only available in debug mode. It will throw in profile and
  /// release modes.
  Type get debugParentDataType {
    Type? type;
    assert(() {
      type = T;
      return true;
    }());
    if (type != null) {
      return type!;
    }
    throw UnsupportedError('debugParentDataType is only supported in debug builds');
  }

  void _applyParentData(ParentDataWidget<T> widget) {
    void applyParentDataToChild(Element child) {
      if (child is RenderObjectElement) {
        child._updateParentData(widget);
      } else if (child.renderObjectAttachingChild != null) {
        applyParentDataToChild(child.renderObjectAttachingChild!);
      }
    }

    if (renderObjectAttachingChild != null) {
      applyParentDataToChild(renderObjectAttachingChild!);
    }
  }

  /// Calls [ParentDataWidget.applyParentData] on the given widget, passing it
  /// the [RenderObject] whose parent data this element is ultimately
  /// responsible for.
  ///
  /// This allows a render object's [RenderObject.parentData] to be modified
  /// without triggering a build. This is generally ill-advised, but makes sense
  /// in situations such as the following:
  ///
  ///  * Build and layout are currently under way, but the [ParentData] in question
  ///    does not affect layout, and the value to be applied could not be
  ///    determined before build and layout (e.g. it depends on the layout of a
  ///    descendant).
  ///
  ///  * Paint is currently under way, but the [ParentData] in question does not
  ///    affect layout or paint, and the value to be applied could not be
  ///    determined before paint (e.g. it depends on the compositing phase).
  ///
  /// In either case, the next build is expected to cause this element to be
  /// configured with the given new widget (or a widget with equivalent data).
  ///
  /// Only [ParentDataWidget]s that return true for
  /// [ParentDataWidget.debugCanApplyOutOfTurn] can be applied this way.
  ///
  /// The new widget must have the same child as the current widget.
  ///
  /// An example of when this is used is the [AutomaticKeepAlive] widget. If it
  /// receives a notification during the build of one of its descendants saying
  /// that its child must be kept alive, it will apply a [KeepAlive] widget out
  /// of turn. This is safe, because by definition the child is already alive,
  /// and therefore this will not change the behavior of the parent this frame.
  /// It is more efficient than requesting an additional frame just for the
  /// purpose of updating the [KeepAlive] widget.
  void applyWidgetOutOfTurn(ParentDataWidget<T> newWidget) {
    assert(newWidget.debugCanApplyOutOfTurn());
    assert(newWidget.child == (widget as ParentDataWidget<T>).child);
    _applyParentData(newWidget);
  }

  @override
  void notifyClients(ParentDataWidget<T> oldWidget) {
    _applyParentData(widget as ParentDataWidget<T>);
  }
}

/// An [Element] that uses an [InheritedWidget] as its configuration.
class InheritedElement extends ProxyElement {
  /// Creates an element that uses the given widget as its configuration.
  InheritedElement(InheritedWidget super.widget);

  final Map<Element, Object?> _dependents = HashMap<Element, Object?>();

  @override
  void _updateInheritance() {
    assert(_lifecycleState == _ElementLifecycle.active);
    final PersistentHashMap<Type, InheritedElement> incomingWidgets =
        _parent?._inheritedElements ?? const PersistentHashMap<Type, InheritedElement>.empty();
    _inheritedElements = incomingWidgets.put(widget.runtimeType, this);
  }

  @override
  void debugDeactivated() {
    assert(() {
      assert(_dependents.isEmpty);
      return true;
    }());
    super.debugDeactivated();
  }

  /// Returns the dependencies value recorded for [dependent]
  /// with [setDependencies].
  ///
  /// Each dependent element is mapped to a single object value
  /// which represents how the element depends on this
  /// [InheritedElement]. This value is null by default and by default
  /// dependent elements are rebuilt unconditionally.
  ///
  /// Subclasses can manage these values with [updateDependencies]
  /// so that they can selectively rebuild dependents in
  /// [notifyDependent].
  ///
  /// This method is typically only called in overrides of [updateDependencies].
  ///
  /// See also:
  ///
  ///  * [updateDependencies], which is called each time a dependency is
  ///    created with [dependOnInheritedWidgetOfExactType].
  ///  * [setDependencies], which sets dependencies value for a dependent
  ///    element.
  ///  * [notifyDependent], which can be overridden to use a dependent's
  ///    dependencies value to decide if the dependent needs to be rebuilt.
  ///  * [InheritedModel], which is an example of a class that uses this method
  ///    to manage dependency values.
  @protected
  Object? getDependencies(Element dependent) {
    return _dependents[dependent];
  }

  /// Sets the value returned by [getDependencies] value for [dependent].
  ///
  /// Each dependent element is mapped to a single object value
  /// which represents how the element depends on this
  /// [InheritedElement]. The [updateDependencies] method sets this value to
  /// null by default so that dependent elements are rebuilt unconditionally.
  ///
  /// Subclasses can manage these values with [updateDependencies]
  /// so that they can selectively rebuild dependents in [notifyDependent].
  ///
  /// This method is typically only called in overrides of [updateDependencies].
  ///
  /// See also:
  ///
  ///  * [updateDependencies], which is called each time a dependency is
  ///    created with [dependOnInheritedWidgetOfExactType].
  ///  * [getDependencies], which returns the current value for a dependent
  ///    element.
  ///  * [notifyDependent], which can be overridden to use a dependent's
  ///    [getDependencies] value to decide if the dependent needs to be rebuilt.
  ///  * [InheritedModel], which is an example of a class that uses this method
  ///    to manage dependency values.
  @protected
  void setDependencies(Element dependent, Object? value) {
    _dependents[dependent] = value;
  }

  /// Called by [dependOnInheritedWidgetOfExactType] when a new [dependent] is added.
  ///
  /// Each dependent element can be mapped to a single object value with
  /// [setDependencies]. This method can lookup the existing dependencies with
  /// [getDependencies].
  ///
  /// By default this method sets the inherited dependencies for [dependent]
  /// to null. This only serves to record an unconditional dependency on
  /// [dependent].
  ///
  /// Subclasses can manage their own dependencies values so that they
  /// can selectively rebuild dependents in [notifyDependent].
  ///
  /// See also:
  ///
  ///  * [getDependencies], which returns the current value for a dependent
  ///    element.
  ///  * [setDependencies], which sets the value for a dependent element.
  ///  * [notifyDependent], which can be overridden to use a dependent's
  ///    dependencies value to decide if the dependent needs to be rebuilt.
  ///  * [InheritedModel], which is an example of a class that uses this method
  ///    to manage dependency values.
  @protected
  void updateDependencies(Element dependent, Object? aspect) {
    setDependencies(dependent, null);
  }

  /// Called by [notifyClients] for each dependent.
  ///
  /// Calls `dependent.didChangeDependencies()` by default.
  ///
  /// Subclasses can override this method to selectively call
  /// [didChangeDependencies] based on the value of [getDependencies].
  ///
  /// See also:
  ///
  ///  * [updateDependencies], which is called each time a dependency is
  ///    created with [dependOnInheritedWidgetOfExactType].
  ///  * [getDependencies], which returns the current value for a dependent
  ///    element.
  ///  * [setDependencies], which sets the value for a dependent element.
  ///  * [InheritedModel], which is an example of a class that uses this method
  ///    to manage dependency values.
  @protected
  void notifyDependent(covariant InheritedWidget oldWidget, Element dependent) {
    dependent.didChangeDependencies();
  }

  /// Called by [Element.deactivate] to remove the provided `dependent` [Element] from this [InheritedElement].
  ///
  /// After the dependent is removed, [Element.didChangeDependencies] will no
  /// longer be called on it when this [InheritedElement] notifies its dependents.
  ///
  /// Subclasses can override this method to release any resources retained for
  /// a given [dependent].
  @protected
  @mustCallSuper
  void removeDependent(Element dependent) {
    _dependents.remove(dependent);
  }

  /// Calls [Element.didChangeDependencies] of all dependent elements, if
  /// [InheritedWidget.updateShouldNotify] returns true.
  ///
  /// Called by [update], immediately prior to [build].
  ///
  /// Calls [notifyClients] to actually trigger the notifications.
  @override
  void updated(InheritedWidget oldWidget) {
    if ((widget as InheritedWidget).updateShouldNotify(oldWidget)) {
      super.updated(oldWidget);
    }
  }

  /// Notifies all dependent elements that this inherited widget has changed, by
  /// calling [Element.didChangeDependencies].
  ///
  /// This method must only be called during the build phase. Usually this
  /// method is called automatically when an inherited widget is rebuilt, e.g.
  /// as a result of calling [State.setState] above the inherited widget.
  ///
  /// See also:
  ///
  ///  * [InheritedNotifier], a subclass of [InheritedWidget] that also calls
  ///    this method when its [Listenable] sends a notification.
  @override
  void notifyClients(InheritedWidget oldWidget) {
    assert(_debugCheckOwnerBuildTargetExists('notifyClients'));
    for (final Element dependent in _dependents.keys) {
      assert(() {
        // check that it really is our descendant
        Element? ancestor = dependent._parent;
        while (ancestor != this && ancestor != null) {
          ancestor = ancestor._parent;
        }
        return ancestor == this;
      }());
      // check that it really depends on us
      assert(dependent._dependencies!.contains(this));
      notifyDependent(oldWidget, dependent);
    }
  }
}

/// An [Element] that uses a [RenderObjectWidget] as its configuration.
///
/// [RenderObjectElement] objects have an associated [RenderObject] widget in
/// the render tree, which handles concrete operations like laying out,
/// painting, and hit testing.
///
/// Contrast with [ComponentElement].
///
/// For details on the lifecycle of an element, see the discussion at [Element].
///
/// ## Writing a RenderObjectElement subclass
///
/// There are three common child models used by most [RenderObject]s:
///
/// * Leaf render objects, with no children: The [LeafRenderObjectElement] class
///   handles this case.
///
/// * A single child: The [SingleChildRenderObjectElement] class handles this
///   case.
///
/// * A linked list of children: The [MultiChildRenderObjectElement] class
///   handles this case.
///
/// Sometimes, however, a render object's child model is more complicated. Maybe
/// it has a two-dimensional array of children. Maybe it constructs children on
/// demand. Maybe it features multiple lists. In such situations, the
/// corresponding [Element] for the [Widget] that configures that [RenderObject]
/// will be a new subclass of [RenderObjectElement].
///
/// Such a subclass is responsible for managing children, specifically the
/// [Element] children of this object, and the [RenderObject] children of its
/// corresponding [RenderObject].
///
/// ### Specializing the getters
///
/// [RenderObjectElement] objects spend much of their time acting as
/// intermediaries between their [widget] and their [renderObject]. It is
/// generally recommended against specializing the [widget] getter and
/// instead casting at the various call sites to avoid adding overhead
/// outside of this particular implementation.
///
/// ```dart
/// class FooElement extends RenderObjectElement {
///   FooElement(super.widget);
///
///   // Specializing the renderObject getter is fine because
///   // it is not performance sensitive.
///   @override
///   RenderFoo get renderObject => super.renderObject as RenderFoo;
///
///   void _foo() {
///     // For the widget getter, though, we prefer to cast locally
///     // since that results in better overall performance where the
///     // casting isn't needed:
///     final Foo foo = widget as Foo;
///     // ...
///   }
///
///   // ...
/// }
/// ```
///
/// ### Slots
///
/// Each child [Element] corresponds to a [RenderObject] which should be
/// attached to this element's render object as a child.
///
/// However, the immediate children of the element may not be the ones that
/// eventually produce the actual [RenderObject] that they correspond to. For
/// example, a [StatelessElement] (the element of a [StatelessWidget])
/// corresponds to whatever [RenderObject] its child (the element returned by
/// its [StatelessWidget.build] method) corresponds to.
///
/// Each child is therefore assigned a _[slot]_ token. This is an identifier whose
/// meaning is private to this [RenderObjectElement] node. When the descendant
/// that finally produces the [RenderObject] is ready to attach it to this
/// node's render object, it passes that slot token back to this node, and that
/// allows this node to cheaply identify where to put the child render object
/// relative to the others in the parent render object.
///
/// A child's [slot] is determined when the parent calls [updateChild] to
/// inflate the child (see the next section). It can be updated by calling
/// [updateSlotForChild].
///
/// ### Updating children
///
/// Early in the lifecycle of an element, the framework calls the [mount]
/// method. This method should call [updateChild] for each child, passing in
/// the widget for that child, and the slot for that child, thus obtaining a
/// list of child [Element]s.
///
/// Subsequently, the framework will call the [update] method. In this method,
/// the [RenderObjectElement] should call [updateChild] for each child, passing
/// in the [Element] that was obtained during [mount] or the last time [update]
/// was run (whichever happened most recently), the new [Widget], and the slot.
/// This provides the object with a new list of [Element] objects.
///
/// Where possible, the [update] method should attempt to map the elements from
/// the last pass to the widgets in the new pass. For example, if one of the
/// elements from the last pass was configured with a particular [Key], and one
/// of the widgets in this new pass has that same key, they should be paired up,
/// and the old element should be updated with the widget (and the slot
/// corresponding to the new widget's new position, also). The [updateChildren]
/// method may be useful in this regard.
///
/// [updateChild] should be called for children in their logical order. The
/// order can matter; for example, if two of the children use [PageStorage]'s
/// `writeState` feature in their build method (and neither has a [Widget.key]),
/// then the state written by the first will be overwritten by the second.
///
/// #### Dynamically determining the children during the build phase
///
/// The child widgets need not necessarily come from this element's widget
/// verbatim. They could be generated dynamically from a callback, or generated
/// in other more creative ways.
///
/// #### Dynamically determining the children during layout
///
/// If the widgets are to be generated at layout time, then generating them in
/// the [mount] and [update] methods won't work: layout of this element's render
/// object hasn't started yet at that point. Instead, the [update] method can
/// mark the render object as needing layout (see
/// [RenderObject.markNeedsLayout]), and then the render object's
/// [RenderObject.performLayout] method can call back to the element to have it
/// generate the widgets and call [updateChild] accordingly.
///
/// For a render object to call an element during layout, it must use
/// [RenderObject.invokeLayoutCallback]. For an element to call [updateChild]
/// outside of its [update] method, it must use [BuildOwner.buildScope].
///
/// The framework provides many more checks in normal operation than it does
/// when doing a build during layout. For this reason, creating widgets with
/// layout-time build semantics should be done with great care.
///
/// #### Handling errors when building
///
/// If an element calls a builder function to obtain widgets for its children,
/// it may find that the build throws an exception. Such exceptions should be
/// caught and reported using [FlutterError.reportError]. If a child is needed
/// but a builder has failed in this way, an instance of [ErrorWidget] can be
/// used instead.
///
/// ### Detaching children
///
/// It is possible, when using [GlobalKey]s, for a child to be proactively
/// removed by another element before this element has been updated.
/// (Specifically, this happens when the subtree rooted at a widget with a
/// particular [GlobalKey] is being moved from this element to an element
/// processed earlier in the build phase.) When this happens, this element's
/// [forgetChild] method will be called with a reference to the affected child
/// element.
///
/// The [forgetChild] method of a [RenderObjectElement] subclass must remove the
/// child element from its child list, so that when it next [update]s its
/// children, the removed child is not considered.
///
/// For performance reasons, if there are many elements, it may be quicker to
/// track which elements were forgotten by storing them in a [Set], rather than
/// proactively mutating the local record of the child list and the identities
/// of all the slots. For example, see the implementation of
/// [MultiChildRenderObjectElement].
///
/// ### Maintaining the render object tree
///
/// Once a descendant produces a render object, it will call
/// [insertRenderObjectChild]. If the descendant's slot changes identity, it
/// will call [moveRenderObjectChild]. If a descendant goes away, it will call
/// [removeRenderObjectChild].
///
/// These three methods should update the render tree accordingly, attaching,
/// moving, and detaching the given child render object from this element's own
/// render object respectively.
///
/// ### Walking the children
///
/// If a [RenderObjectElement] object has any children [Element]s, it must
/// expose them in its implementation of the [visitChildren] method. This method
/// is used by many of the framework's internal mechanisms, and so should be
/// fast. It is also used by the test framework and [debugDumpApp].
abstract class RenderObjectElement extends Element {
  /// Creates an element that uses the given widget as its configuration.
  RenderObjectElement(RenderObjectWidget super.widget);

  /// The underlying [RenderObject] for this element.
  ///
  /// If this element has been [unmount]ed, this getter will throw.
  @override
  RenderObject get renderObject {
    assert(_renderObject != null, '$runtimeType unmounted');
    return _renderObject!;
  }

  RenderObject? _renderObject;

  @override
  Element? get renderObjectAttachingChild => null;

  bool _debugDoingBuild = false;
  @override
  bool get debugDoingBuild => _debugDoingBuild;

  RenderObjectElement? _ancestorRenderObjectElement;

  RenderObjectElement? _findAncestorRenderObjectElement() {
    Element? ancestor = _parent;
    while (ancestor != null && ancestor is! RenderObjectElement) {
      // In debug mode we check whether the ancestor accepts RenderObjects to
      // produce a better error message in attachRenderObject. In release mode,
      // we assume only correct trees are built (i.e.
      // debugExpectsRenderObjectForSlot always returns true) and don't check
      // explicitly.
      assert(() {
        if (!ancestor!.debugExpectsRenderObjectForSlot(slot)) {
          ancestor = null;
        }
        return true;
      }());
      ancestor = ancestor?._parent;
    }
    assert(() {
      if (ancestor?.debugExpectsRenderObjectForSlot(slot) == false) {
        ancestor = null;
      }
      return true;
    }());
    return ancestor as RenderObjectElement?;
  }

  void _debugCheckCompetingAncestors(
    List<ParentDataElement<ParentData>> result,
    Set<Type> debugAncestorTypes,
    Set<Type> debugParentDataTypes,
    List<Type> debugAncestorCulprits,
  ) {
    assert(() {
      // Check that no other ParentDataWidgets of the same
      // type want to provide parent data.
      if (debugAncestorTypes.length != result.length ||
          debugParentDataTypes.length != result.length) {
        // This can only occur if the Sets of ancestors and parent data types was
        // provided a dupe and did not add it.
        assert(
          debugAncestorTypes.length < result.length || debugParentDataTypes.length < result.length,
        );
        try {
          // We explicitly throw here (even though we immediately redirect the
          // exception elsewhere) so that debuggers will notice it when they
          // have "break on exception" enabled.
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('Incorrect use of ParentDataWidget.'),
            ErrorDescription(
              'Competing ParentDataWidgets are providing parent data to the '
              'same RenderObject:',
            ),
            for (final ParentDataElement<ParentData> ancestor in result.where((
              ParentDataElement<ParentData> ancestor,
            ) {
              return debugAncestorCulprits.contains(ancestor.runtimeType);
            }))
              ErrorDescription(
                '- ${ancestor.widget}, which writes ParentData of type '
                '${ancestor.debugParentDataType}, (typically placed directly '
                'inside a '
                '${(ancestor.widget as ParentDataWidget<ParentData>).debugTypicalAncestorWidgetClass} '
                'widget)',
              ),
            ErrorDescription(
              'A RenderObject can receive parent data from multiple '
              'ParentDataWidgets, but the Type of ParentData must be unique to '
              'prevent one overwriting another.',
            ),
            ErrorHint(
              'Usually, this indicates that one or more of the offending '
              "ParentDataWidgets listed above isn't placed inside a dedicated "
              "compatible ancestor widget that it isn't sharing with another "
              'ParentDataWidget of the same type.',
            ),
            ErrorHint(
              'Otherwise, separating aspects of ParentData to prevent '
              'conflicts can be done using mixins, mixing them all in on the '
              'full ParentData Object, such as KeepAlive does with '
              'KeepAliveParentDataMixin.',
            ),
            ErrorDescription(
              'The ownership chain for the RenderObject that received the '
              'parent data was:\n  ${debugGetCreatorChain(10)}',
            ),
          ]);
        } on FlutterError catch (error) {
          _reportException(ErrorSummary('while looking for parent data.'), error, error.stackTrace);
        }
      }
      return true;
    }());
  }

  List<ParentDataElement<ParentData>> _findAncestorParentDataElements() {
    Element? ancestor = _parent;
    final List<ParentDataElement<ParentData>> result = <ParentDataElement<ParentData>>[];
    final Set<Type> debugAncestorTypes = <Type>{};
    final Set<Type> debugParentDataTypes = <Type>{};
    final List<Type> debugAncestorCulprits = <Type>[];

    // More than one ParentDataWidget can contribute ParentData, but there are
    // some constraints.
    // 1. ParentData can only be written by unique ParentDataWidget types.
    //    For example, two KeepAlive ParentDataWidgets trying to write to the
    //    same child is not allowed.
    // 2. Each contributing ParentDataWidget must contribute to a unique
    //    ParentData type, less ParentData be overwritten.
    //    For example, there cannot be two ParentDataWidgets that both write
    //    ParentData of type KeepAliveParentDataMixin, if the first check was
    //    subverted by a subclassing of the KeepAlive ParentDataWidget.
    // 3. The ParentData itself must be compatible with all ParentDataWidgets
    //    writing to it.
    //    For example, TwoDimensionalViewportParentData uses the
    //    KeepAliveParentDataMixin, so it could be compatible with both
    //    KeepAlive, and another ParentDataWidget with ParentData type
    //    TwoDimensionalViewportParentData or a subclass thereof.
    // The first and second cases are verified here. The third is verified in
    // debugIsValidRenderObject.

    while (ancestor != null && ancestor is! RenderObjectElement) {
      if (ancestor is ParentDataElement<ParentData>) {
        assert((ParentDataElement<ParentData> ancestor) {
          if (!debugAncestorTypes.add(ancestor.runtimeType) ||
              !debugParentDataTypes.add(ancestor.debugParentDataType)) {
            debugAncestorCulprits.add(ancestor.runtimeType);
          }
          return true;
        }(ancestor));
        result.add(ancestor);
      }
      ancestor = ancestor._parent;
    }
    assert(() {
      if (result.isEmpty || ancestor == null) {
        return true;
      }
      // Validate points 1 and 2 from above.
      _debugCheckCompetingAncestors(
        result,
        debugAncestorTypes,
        debugParentDataTypes,
        debugAncestorCulprits,
      );
      return true;
    }());
    return result;
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    assert(() {
      _debugDoingBuild = true;
      return true;
    }());
    _renderObject = (widget as RenderObjectWidget).createRenderObject(this);
    assert(!_renderObject!.debugDisposed!);
    assert(() {
      _debugDoingBuild = false;
      return true;
    }());
    assert(() {
      _debugUpdateRenderObjectOwner();
      return true;
    }());
    assert(slot == newSlot);
    attachRenderObject(newSlot);
    super.performRebuild(); // clears the "dirty" flag
  }

  @override
  void update(covariant RenderObjectWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    assert(() {
      _debugUpdateRenderObjectOwner();
      return true;
    }());
    _performRebuild(); // calls widget.updateRenderObject()
  }

  void _debugUpdateRenderObjectOwner() {
    assert(() {
      renderObject.debugCreator = DebugCreator(this);
      return true;
    }());
  }

  @override
  // ignore: must_call_super, _performRebuild calls super.
  void performRebuild() {
    _performRebuild(); // calls widget.updateRenderObject()
  }

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  void _performRebuild() {
    assert(() {
      _debugDoingBuild = true;
      return true;
    }());
    (widget as RenderObjectWidget).updateRenderObject(this, renderObject);
    assert(() {
      _debugDoingBuild = false;
      return true;
    }());
    super.performRebuild(); // clears the "dirty" flag
  }

  @override
  void deactivate() {
    super.deactivate();
    assert(
      !renderObject.attached,
      'A RenderObject was still attached when attempting to deactivate its '
      'RenderObjectElement: $renderObject',
    );
  }

  @override
  void unmount() {
    assert(
      !renderObject.debugDisposed!,
      'A RenderObject was disposed prior to its owning element being unmounted: '
      '$renderObject',
    );
    final RenderObjectWidget oldWidget = widget as RenderObjectWidget;
    super.unmount();
    assert(
      !renderObject.attached,
      'A RenderObject was still attached when attempting to unmount its '
      'RenderObjectElement: $renderObject',
    );
    oldWidget.didUnmountRenderObject(renderObject);
    _renderObject!.dispose();
    _renderObject = null;
  }

  void _updateParentData(ParentDataWidget<ParentData> parentDataWidget) {
    bool applyParentData = true;
    assert(() {
      try {
        if (!parentDataWidget.debugIsValidRenderObject(renderObject)) {
          applyParentData = false;
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('Incorrect use of ParentDataWidget.'),
            ...parentDataWidget._debugDescribeIncorrectParentDataType(
              parentData: renderObject.parentData,
              parentDataCreator: _ancestorRenderObjectElement?.widget as RenderObjectWidget?,
              ownershipChain: ErrorDescription(debugGetCreatorChain(10)),
            ),
          ]);
        }
      } on FlutterError catch (e) {
        // We catch the exception directly to avoid activating the ErrorWidget,
        // while still allowing debuggers to break on exception. Since the tree
        // is in a broken state, adding the ErrorWidget would likely cause more
        // exceptions, which is not good for the debugging experience.
        _reportException(ErrorSummary('while applying parent data.'), e, e.stackTrace);
      }
      return true;
    }());
    if (applyParentData) {
      parentDataWidget.applyParentData(renderObject);
    }
  }

  @override
  void updateSlot(Object? newSlot) {
    final Object? oldSlot = slot;
    assert(oldSlot != newSlot);
    super.updateSlot(newSlot);
    assert(slot == newSlot);
    assert(_ancestorRenderObjectElement == _findAncestorRenderObjectElement());
    _ancestorRenderObjectElement?.moveRenderObjectChild(renderObject, oldSlot, slot);
  }

  @override
  void attachRenderObject(Object? newSlot) {
    assert(_ancestorRenderObjectElement == null);
    _slot = newSlot;
    _ancestorRenderObjectElement = _findAncestorRenderObjectElement();
    assert(() {
      if (_ancestorRenderObjectElement == null) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary(
                'The render object for ${toStringShort()} cannot find ancestor render object to attach to.',
              ),
              ErrorDescription(
                'The ownership chain for the RenderObject in question was:\n  ${debugGetCreatorChain(10)}',
              ),
              ErrorHint(
                'Try wrapping your widget in a View widget or any other widget that is backed by '
                'a $RenderTreeRootElement to serve as the root of the render tree.',
              ),
            ]),
          ),
        );
      }
      return true;
    }());
    _ancestorRenderObjectElement?.insertRenderObjectChild(renderObject, newSlot);
    final List<ParentDataElement<ParentData>> parentDataElements =
        _findAncestorParentDataElements();
    for (final ParentDataElement<ParentData> parentDataElement in parentDataElements) {
      _updateParentData(parentDataElement.widget as ParentDataWidget<ParentData>);
    }
  }

  @override
  void detachRenderObject() {
    if (_ancestorRenderObjectElement != null) {
      _ancestorRenderObjectElement!.removeRenderObjectChild(renderObject, slot);
      _ancestorRenderObjectElement = null;
    }
    _slot = null;
  }

  /// Insert the given child into [renderObject] at the given slot.
  ///
  /// {@template flutter.widgets.RenderObjectElement.insertRenderObjectChild}
  /// The semantics of `slot` are determined by this element. For example, if
  /// this element has a single child, the slot should always be null. If this
  /// element has a list of children, the previous sibling element wrapped in an
  /// [IndexedSlot] is a convenient value for the slot.
  /// {@endtemplate}
  @protected
  void insertRenderObjectChild(covariant RenderObject child, covariant Object? slot);

  /// Move the given child from the given old slot to the given new slot.
  ///
  /// The given child is guaranteed to have [renderObject] as its parent.
  ///
  /// {@macro flutter.widgets.RenderObjectElement.insertRenderObjectChild}
  ///
  /// This method is only ever called if [updateChild] can end up being called
  /// with an existing [Element] child and a `slot` that differs from the slot
  /// that element was previously given. [MultiChildRenderObjectElement] does this,
  /// for example. [SingleChildRenderObjectElement] does not (since the `slot` is
  /// always null). An [Element] that has a specific set of slots with each child
  /// always having the same slot (and where children in different slots are never
  /// compared against each other for the purposes of updating one slot with the
  /// element from another slot) would never call this.
  @protected
  void moveRenderObjectChild(
    covariant RenderObject child,
    covariant Object? oldSlot,
    covariant Object? newSlot,
  );

  /// Remove the given child from [renderObject].
  ///
  /// The given child is guaranteed to have been inserted at the given `slot`
  /// and have [renderObject] as its parent.
  @protected
  void removeRenderObjectChild(covariant RenderObject child, covariant Object? slot);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<RenderObject>('renderObject', _renderObject, defaultValue: null),
    );
  }
}

/// Deprecated. Unused in the framework and will be removed in a future version
/// of Flutter.
///
/// Classes that extend this class can extend [RenderObjectElement] and mixin
/// [RootElementMixin] instead.
@Deprecated(
  'Use RootElementMixin instead. '
  'This feature was deprecated after v3.9.0-16.0.pre.',
)
abstract class RootRenderObjectElement extends RenderObjectElement with RootElementMixin {
  /// Initializes fields for subclasses.
  @Deprecated(
    'Use RootElementMixin instead. '
    'This feature was deprecated after v3.9.0-16.0.pre.',
  )
  RootRenderObjectElement(super.widget);
}

/// Mixin for the element at the root of the tree.
///
/// Only root elements may have their owner set explicitly. All other
/// elements inherit their owner from their parent.
mixin RootElementMixin on Element {
  /// Set the owner of the element. The owner will be propagated to all the
  /// descendants of this element.
  ///
  /// The owner manages the dirty elements list.
  ///
  /// The [WidgetsBinding] introduces the primary owner,
  /// [WidgetsBinding.buildOwner], and assigns it to the widget tree in the call
  /// to [runApp]. The binding is responsible for driving the build pipeline by
  /// calling the build owner's [BuildOwner.buildScope] method. See
  /// [WidgetsBinding.drawFrame].
  void assignOwner(BuildOwner owner) {
    _owner = owner;
    _parentBuildScope = BuildScope();
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    // Root elements should never have parents.
    assert(parent == null);
    assert(newSlot == null);
    super.mount(parent, newSlot);
  }
}

/// An [Element] that uses a [LeafRenderObjectWidget] as its configuration.
class LeafRenderObjectElement extends RenderObjectElement {
  /// Creates an element that uses the given widget as its configuration.
  LeafRenderObjectElement(LeafRenderObjectWidget super.widget);

  @override
  void forgetChild(Element child) {
    assert(false);
    super.forgetChild(child);
  }

  @override
  void insertRenderObjectChild(RenderObject child, Object? slot) {
    assert(false);
  }

  @override
  void moveRenderObjectChild(RenderObject child, Object? oldSlot, Object? newSlot) {
    assert(false);
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object? slot) {
    assert(false);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return widget.debugDescribeChildren();
  }
}

/// An [Element] that uses a [SingleChildRenderObjectWidget] as its configuration.
///
/// The child is optional.
///
/// This element subclass can be used for [RenderObjectWidget]s whose
/// [RenderObject]s use the [RenderObjectWithChildMixin] mixin. Such widgets are
/// expected to inherit from [SingleChildRenderObjectWidget].
class SingleChildRenderObjectElement extends RenderObjectElement {
  /// Creates an element that uses the given widget as its configuration.
  SingleChildRenderObjectElement(SingleChildRenderObjectWidget super.widget);

  Element? _child;

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null) {
      visitor(_child!);
    }
  }

  @override
  void forgetChild(Element child) {
    assert(child == _child);
    _child = null;
    super.forgetChild(child);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _child = updateChild(_child, (widget as SingleChildRenderObjectWidget).child, null);
  }

  @override
  void update(SingleChildRenderObjectWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _child = updateChild(_child, (widget as SingleChildRenderObjectWidget).child, null);
  }

  @override
  void insertRenderObjectChild(RenderObject child, Object? slot) {
    final RenderObjectWithChildMixin<RenderObject> renderObject =
        this.renderObject as RenderObjectWithChildMixin<RenderObject>;
    assert(slot == null);
    assert(renderObject.debugValidateChild(child));
    renderObject.child = child;
    assert(renderObject == this.renderObject);
  }

  @override
  void moveRenderObjectChild(RenderObject child, Object? oldSlot, Object? newSlot) {
    assert(false);
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object? slot) {
    final RenderObjectWithChildMixin<RenderObject> renderObject =
        this.renderObject as RenderObjectWithChildMixin<RenderObject>;
    assert(slot == null);
    assert(renderObject.child == child);
    renderObject.child = null;
    assert(renderObject == this.renderObject);
  }
}

/// An [Element] that uses a [MultiChildRenderObjectWidget] as its configuration.
///
/// This element subclass can be used for [RenderObjectWidget]s whose
/// [RenderObject]s use the [ContainerRenderObjectMixin] mixin with a parent data
/// type that implements [ContainerParentDataMixin<RenderObject>]. Such widgets
/// are expected to inherit from [MultiChildRenderObjectWidget].
///
/// See also:
///
/// * [IndexedSlot], which is used as [Element.slot]s for the children of a
///   [MultiChildRenderObjectElement].
/// * [RenderObjectElement.updateChildren], which discusses why [IndexedSlot]
///   is used for the slots of the children.
class MultiChildRenderObjectElement extends RenderObjectElement {
  /// Creates an element that uses the given widget as its configuration.
  MultiChildRenderObjectElement(MultiChildRenderObjectWidget super.widget)
    : assert(!debugChildrenHaveDuplicateKeys(widget, widget.children));

  @override
  ContainerRenderObjectMixin<RenderObject, ContainerParentDataMixin<RenderObject>>
  get renderObject {
    return super.renderObject
        as ContainerRenderObjectMixin<RenderObject, ContainerParentDataMixin<RenderObject>>;
  }

  /// The current list of children of this element.
  ///
  /// This list is filtered to hide elements that have been forgotten (using
  /// [forgetChild]).
  @protected
  @visibleForTesting
  Iterable<Element> get children =>
      _children.where((Element child) => !_forgottenChildren.contains(child));

  late List<Element> _children;
  // We keep a set of forgotten children to avoid O(n^2) work walking _children
  // repeatedly to remove children.
  final Set<Element> _forgottenChildren = HashSet<Element>();

  @override
  void insertRenderObjectChild(RenderObject child, IndexedSlot<Element?> slot) {
    final ContainerRenderObjectMixin<RenderObject, ContainerParentDataMixin<RenderObject>>
    renderObject = this.renderObject;
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child, after: slot.value?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void moveRenderObjectChild(
    RenderObject child,
    IndexedSlot<Element?> oldSlot,
    IndexedSlot<Element?> newSlot,
  ) {
    final ContainerRenderObjectMixin<RenderObject, ContainerParentDataMixin<RenderObject>>
    renderObject = this.renderObject;
    assert(child.parent == renderObject);
    renderObject.move(child, after: newSlot.value?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object? slot) {
    final ContainerRenderObjectMixin<RenderObject, ContainerParentDataMixin<RenderObject>>
    renderObject = this.renderObject;
    assert(child.parent == renderObject);
    renderObject.remove(child);
    assert(renderObject == this.renderObject);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (final Element child in _children) {
      if (!_forgottenChildren.contains(child)) {
        visitor(child);
      }
    }
  }

  @override
  void forgetChild(Element child) {
    assert(_children.contains(child));
    assert(!_forgottenChildren.contains(child));
    _forgottenChildren.add(child);
    super.forgetChild(child);
  }

  bool _debugCheckHasAssociatedRenderObject(Element newChild) {
    assert(() {
      if (newChild.renderObject == null) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary(
                'The children of `MultiChildRenderObjectElement` must each has an associated render object.',
              ),
              ErrorHint(
                'This typically means that the `${newChild.widget}` or its children\n'
                'are not a subtype of `RenderObjectWidget`.',
              ),
              newChild.describeElement(
                'The following element does not have an associated render object',
              ),
              DiagnosticsDebugCreator(DebugCreator(newChild)),
            ]),
          ),
        );
      }
      return true;
    }());
    return true;
  }

  @override
  Element inflateWidget(Widget newWidget, Object? newSlot) {
    final Element newChild = super.inflateWidget(newWidget, newSlot);
    assert(_debugCheckHasAssociatedRenderObject(newChild));
    return newChild;
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    final MultiChildRenderObjectWidget multiChildRenderObjectWidget =
        widget as MultiChildRenderObjectWidget;
    final List<Element> children = List<Element>.filled(
      multiChildRenderObjectWidget.children.length,
      _NullElement.instance,
    );
    Element? previousChild;
    for (int i = 0; i < children.length; i += 1) {
      final Element newChild = inflateWidget(
        multiChildRenderObjectWidget.children[i],
        IndexedSlot<Element?>(i, previousChild),
      );
      children[i] = newChild;
      previousChild = newChild;
    }
    _children = children;
  }

  @override
  void update(MultiChildRenderObjectWidget newWidget) {
    super.update(newWidget);
    final MultiChildRenderObjectWidget multiChildRenderObjectWidget =
        widget as MultiChildRenderObjectWidget;
    assert(widget == newWidget);
    assert(!debugChildrenHaveDuplicateKeys(widget, multiChildRenderObjectWidget.children));
    _children = updateChildren(
      _children,
      multiChildRenderObjectWidget.children,
      forgottenChildren: _forgottenChildren,
    );
    _forgottenChildren.clear();
  }
}

/// A [RenderObjectElement] used to manage the root of a render tree.
///
/// Unlike any other render object element this element does not attempt to
/// attach its [renderObject] to the closest ancestor [RenderObjectElement].
/// Instead, subclasses must override [attachRenderObject] and
/// [detachRenderObject] to attach/detach the [renderObject] to whatever
/// instance manages the render tree (e.g. by assigning it to
/// [PipelineOwner.rootNode]).
abstract class RenderTreeRootElement extends RenderObjectElement {
  /// Creates an element that uses the given widget as its configuration.
  RenderTreeRootElement(super.widget);

  @override
  @mustCallSuper
  void attachRenderObject(Object? newSlot) {
    _slot = newSlot;
    assert(_debugCheckMustNotAttachRenderObjectToAncestor());
  }

  @override
  @mustCallSuper
  void detachRenderObject() {
    _slot = null;
  }

  @override
  void updateSlot(Object? newSlot) {
    super.updateSlot(newSlot);
    assert(_debugCheckMustNotAttachRenderObjectToAncestor());
  }

  bool _debugCheckMustNotAttachRenderObjectToAncestor() {
    if (!kDebugMode) {
      return true;
    }
    if (_findAncestorRenderObjectElement() != null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
          'The RenderObject for ${toStringShort()} cannot maintain an independent render tree at its current location.',
        ),
        ErrorDescription(
          'The ownership chain for the RenderObject in question was:\n  ${debugGetCreatorChain(10)}',
        ),
        ErrorDescription(
          'This RenderObject is the root of an independent render tree and it cannot '
          'attach itself to an ancestor in an existing tree. The ancestor RenderObject, '
          'however, expects that a child will be attached.',
        ),
        ErrorHint(
          'Try moving the subtree that contains the ${toStringShort()} widget '
          'to a location where it is not expected to attach its RenderObject '
          'to a parent. This could mean moving the subtree into the view '
          'property of a "ViewAnchor" widget or - if the subtree is the root of '
          'your widget tree - passing it to "runWidget" instead of "runApp".',
        ),
        ErrorHint(
          'If you are seeing this error in a test and the subtree containing '
          'the ${toStringShort()} widget is passed to "WidgetTester.pumpWidget", '
          'consider setting the "wrapWithView" parameter of that method to false.',
        ),
      ]);
    }
    return true;
  }
}

/// A wrapper class for the [Element] that is the creator of a [RenderObject].
///
/// Setting a [DebugCreator] as [RenderObject.debugCreator] will lead to better
/// error messages.
class DebugCreator {
  /// Create a [DebugCreator] instance with input [Element].
  DebugCreator(this.element);

  /// The creator of the [RenderObject].
  final Element element;

  @override
  String toString() => element.debugGetCreatorChain(12);
}

FlutterErrorDetails _reportException(
  DiagnosticsNode context,
  Object exception,
  StackTrace? stack, {
  InformationCollector? informationCollector,
}) {
  final FlutterErrorDetails details = FlutterErrorDetails(
    exception: exception,
    stack: stack,
    library: 'widgets library',
    context: context,
    informationCollector: informationCollector,
  );
  FlutterError.reportError(details);
  return details;
}

/// A value for [Element.slot] used for children of
/// [MultiChildRenderObjectElement]s.
///
/// A slot for a [MultiChildRenderObjectElement] consists of an [index]
/// identifying where the child occupying this slot is located in the
/// [MultiChildRenderObjectElement]'s child list and an arbitrary [value] that
/// can further define where the child occupying this slot fits in its
/// parent's child list.
///
/// See also:
///
///  * [RenderObjectElement.updateChildren], which discusses why this class is
///    used as slot values for the children of a [MultiChildRenderObjectElement].
@immutable
class IndexedSlot<T extends Element?> {
  /// Creates an [IndexedSlot] with the provided [index] and slot [value].
  const IndexedSlot(this.index, this.value);

  /// Information to define where the child occupying this slot fits in its
  /// parent's child list.
  final T value;

  /// The index of this slot in the parent's child list.
  final int index;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is IndexedSlot && index == other.index && value == other.value;
  }

  @override
  int get hashCode => Object.hash(index, value);
}

/// Used as a placeholder in [List<Element>] objects when the actual
/// elements are not yet determined.
class _NullElement extends Element {
  _NullElement() : super(const _NullWidget());

  static _NullElement instance = _NullElement();

  @override
  bool get debugDoingBuild => throw UnimplementedError();
}

class _NullWidget extends Widget {
  const _NullWidget();

  @override
  Element createElement() => throw UnimplementedError();
}
