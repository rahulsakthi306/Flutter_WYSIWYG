import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/html.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:wysiwyg/provider/global.dart';
import 'package:wysiwyg/widgets/avatar.dart';
import 'package:wysiwyg/widgets/button.dart';
import 'package:wysiwyg/widgets/checkbox.dart';
import 'package:wysiwyg/widgets/chip.dart';
import 'package:wysiwyg/widgets/datepicker.dart';
import 'package:wysiwyg/widgets/dropdown.dart';
import 'package:wysiwyg/widgets/icon.dart';
import 'package:wysiwyg/widgets/image.dart';
import 'package:wysiwyg/widgets/progressbar.dart';
import 'package:wysiwyg/widgets/radio.dart';
import 'package:wysiwyg/widgets/slider.dart';
import 'package:wysiwyg/widgets/switch.dart';
import 'package:wysiwyg/widgets/text.dart';
import 'package:wysiwyg/widgets/textarea.dart';
import 'package:wysiwyg/widgets/textinput.dart';
import 'package:wysiwyg/widgets/timepicker.dart';

class CanvasWidget extends StatefulWidget {
  const CanvasWidget({super.key});

  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends State<CanvasWidget> {
  List<Map<String, dynamic>> widgets = [];
  late HtmlWebSocketChannel channel;
  double gridSize = 8.0;
  OverlayEntry? _contextMenuOverlay;
  double rowHeight = 100.0;
  final int columnCount = 12;
  double columnWidth = 1440 / 12;

  String sessionId =  '1';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
  final screenSize = MediaQuery.of(context).size;
  setState(() {
    columnWidth = screenSize.width / columnCount;
    gridSize = 8.0; 
    rowHeight = screenSize.height / 100; 
  });
});

    html.window.onContextMenu.listen((event) {
      event.preventDefault();
    });

    channel = HtmlWebSocketChannel.connect('ws://192.168.2.95:8080');

    channel.sink.add(jsonEncode({'action': 'CONNECT', 'sessionId': sessionId}));

    channel.stream.listen(
      (message) {
        String msgString;
        if (message is Uint8List) {
          msgString = utf8.decode(message);
        } else if (message is String) {
          msgString = message;
        } else {
          return;
        }

        try {
          final data = jsonDecode(msgString) as Map<String, dynamic>?;
          if (data == null || data['action'] == null) {
            return;
          }
          final action = data['action'] as String;
          print(action);
          setState(() {
            if (action == 'INIT_WIDGETS') {
              widgets = [];
              final jsonData = data['data'] as Map<String, dynamic>?;
              if (jsonData == null || !jsonData.containsKey('root')) {
                return;
              }

              for (var key in jsonData.keys.where((k) => k != 'root')) {
                final w = jsonData[key] as Map<String, dynamic>?;
                if (w == null) {
                  continue;
                }
                final propsMeta = w['property'] is Map
                    ? (w['property']['props']?['meta']
                            as Map<String, dynamic>?) ??
                        {}
                    : {};
                final row =
                    int.tryParse(propsMeta['row']?.toString() ?? '1') ?? 1;
                final col =
                    int.tryParse(propsMeta['col']?.toString() ?? '1') ?? 1;
                final rowSpan =
                    int.tryParse(propsMeta['rowSpan']?.toString() ?? '1') ?? 1;
                final colSpan =
                    int.tryParse(propsMeta['colSpan']?.toString() ?? '1') ?? 1;

                final x = (col - 1) * columnWidth;
                final y = (row - 1) * rowHeight;
                final width = colSpan * columnWidth;
                final height = rowSpan * rowHeight;

                widgets.add({
                  'id': w['id']?.toString() ?? key,
                  'type': w['type']?.toString().toLowerCase() ?? 'unknown',
                  'pos': Offset(
                    snap(x).toDouble(),
                    snap(y).toDouble(),
                  ),
                  'size': Size(
                    snap(width).toDouble(),
                    snap(height).toDouble(),
                  ),
                  'parentId': w['parent']?.toString() ??
                      w['T_parentId']?.toString() ??
                      'root',
                  'name': w['property'] is Map
                      ? (w['property']['name']?.toString() ??
                          w['type']?.toString().toLowerCase() ??
                          'unknown')
                      : 'unknown',
                  'label': w['data'] is Map
                      ? (w['data']['label']?.toString() ??
                          w['type']?.toString().toLowerCase() ??
                          'unknown')
                      : 'unknown',
                  'row': row,
                  'col': col,
                  'rowSpan': rowSpan,
                  'colSpan': colSpan,
                  'nodeProperty': w['data']['nodeProperty'],
                });
              }
              print('Flutter: Initialized widgets from JSON object: $widgets');

              emitJson();
            } else if (action == 'DROP') {
              final type = data['type']?.toString().toLowerCase();
              if (type == null) {
                return;
              }
              if (type == 'appbar' &&
                  widgets.any((w) => w['type'] == 'appbar')) {
                return;
              }
              if (type == 'floatingactionbutton' &&
                  widgets.any((w) => w['type'] == 'floatingactionbutton')) {
                return;
              }
              if (!widgets.any((w) => w['id'] == data['id']?.toString())) {
                final defaultSize = type == 'group'
                    ? const Size(200.0, 100.0)
                    : Size(
                        (data['width'] as num?)?.toDouble() ?? 120.0,
                        (data['height'] as num?)?.toDouble() ?? 50.0,
                      );
                final snappedSize = snapSize(defaultSize);
                final snappedPos = snapToGrid(Offset(
                  (data['x'] as num?)?.toDouble() ?? 0.0,
                  (data['y'] as num?)?.toDouble() ?? 0.0,
                ));

                Offset finalPos = snappedPos;
                int offsetCount = 0;
                final id = data['id']?.toString() ??
                    DateTime.now().millisecondsSinceEpoch.toString();
                while (
                    widgets.any((w) => w['pos'] == finalPos && w['id'] != id)) {
                  offsetCount++;
                  finalPos = Offset(
                    snappedPos.dx + offsetCount * gridSize,
                    snappedPos.dy + offsetCount * gridSize,
                  );
                }

                final row = (finalPos.dy / rowHeight).floor() + 1;
                final col = (finalPos.dx / columnWidth).floor() + 1;
                final rowSpan = (snappedSize.height / rowHeight).ceil();
                final colSpan = (snappedSize.width / columnWidth).ceil();

                final parentId = data['parentId']?.toString() ?? findGroupAtPosition(finalPos, id) ?? 'root';

                widgets.add({
                  'id': id,
                  'type': type,
                  'pos': finalPos,
                  'size': snappedSize,
                  'parentId': parentId,
                  'name': data['name']?.toString() ?? type.toLowerCase(),
                  'label': data['label']?.toString() ?? type.toLowerCase(),
                  'row': data['row'] as int? ?? row,
                  'col': data['col'] as int? ?? col,
                  'rowSpan': data['rowSpan'] as int? ?? rowSpan,
                  'colSpan': data['colSpan'] as int? ?? colSpan,
                  'nodeProperty': data['data']['nodeProperty'],
                });
              }
              emitJson();
            } else if (action == 'RESIZE') {
              final id = data['id']?.toString();
              if (id == null) {
                return;
              }
              final idx = widgets.indexWhere((w) => w['id'] == id);
              if (idx != -1) {
                final newSize = snapSize(Size(
                  (data['width'] as num?)?.toDouble() ??
                      widgets[idx]['size'].width,
                  (data['height'] as num?)?.toDouble() ??
                      widgets[idx]['size'].height,
                ));
                final rowSpan = (newSize.height / rowHeight).ceil();
                final colSpan = (newSize.width / columnWidth).ceil();
                widgets[idx]['size'] = newSize;
                widgets[idx]['rowSpan'] = rowSpan;
                widgets[idx]['colSpan'] = colSpan;
              }
              emitJson();
            } else if (action == 'MOVE') {
              final id = data['id']?.toString();
              if (id == null) {
                return;
              }
              final idx = widgets.indexWhere((w) => w['id'] == id);
              if (idx != -1) {
                final newPos = snapToGrid(Offset(
                  (data['x'] as num?)?.toDouble() ?? widgets[idx]['pos'].dx,
                  (data['y'] as num?)?.toDouble() ?? widgets[idx]['pos'].dy,
                ));
                final row = (newPos.dy / rowHeight).floor() + 1;
                final col = (newPos.dx / columnWidth).floor() + 1;
                widgets[idx]['pos'] = newPos;
                widgets[idx]['parentId'] =
                    data['parentId']?.toString() ?? widgets[idx]['parentId'];
                widgets[idx]['row'] = row;
                widgets[idx]['col'] = col;
              }
              emitJson();
            } else if (action == 'DELETE') {
              final id = data['id']?.toString();
              if (id == null) {
                return;
              }
              widgets.removeWhere((w) => w['id'] == id);
              emitJson();
            } else if (action == 'UPDATE_CURRENT_NODE') {
              final id = data['id']?.toString();
              if (id == null) {
                return;
              }
              final path = data['path']?.toString();
              final value = data['value'];
              if (path == null) {
                return;
              }
              final pathParts = path.split('.');
              try {
                Provider.of<GlobalProvider>(context, listen: false).currentNode['nodeProperty']['elementInfo']
                        [pathParts[0]][int.tryParse(pathParts[1])]
                    [pathParts[2]] = value;
              } catch (e) {
                print(
                    'Flutter: Error updating node property at path $path: $e');
              }
              emitJson();
            }
          });
        } catch (err) {
          print('Flutter: Error parsing WebSocket message: $err');
        }
      },
      onError: (error) {
        print('Flutter: WebSocket error: $error');
      },
      onDone: () {
        print('Flutter: WebSocket closed, attempting to reconnect...');
        Future.delayed(Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() {
            channel = HtmlWebSocketChannel.connect('ws://192.168.2.95:8080');
            channel.sink
                .add(jsonEncode({'action': 'CONNECT', 'sessionId': sessionId}));
          });
        });
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    emitJson();
  }

  double snap(double val) {
    return (val / gridSize).round() * gridSize;
  }

  Offset snapToGrid(Offset pos) {
    return Offset(
      snap(pos.dx),
/// The grid has a spacing of [gridSize] in both the x and y directions.
///
/// This function is used to align widgets with the grid when they are moved or resized.
///
      snap(pos.dy),
    );
  }

  Size snapSize(Size size) {
    return Size(
      snap(size.width),
      snap(size.height),
    );
  }

  void emitJson() {
    final jsonOutput = {
      'root': {
        'id': 'root',
        'Parent': 'root',
        'type': 'Canvas',
        'T_parentId': 'root',
        'children': widgets
            .where((w) => w['parentId'] == 'root')
            .map((w) => w['id']?.toString())
            .where((id) => id != null)
            .toList(),
        'data': {
          'label': 'Root',
          'nodeProperty': {
            'nodeId': 'root',
            'nodeName': 'Root',
            'nodeType': 'Canvas',
            'nodeVersion': 'v1',
            'elementInfo': {},
          },
        },
        'grid': {
          'style': {},
        },
        'property': {
          'name': '',
          'nodeType': 'Canvas',
          'description': '',
          'backgroundColor': '#ffffff',
          'rowHeight': '100px',
          'rowGap': '10px',
          'columnGap': '10px',
          'props': {
            'meta': {
              'row': 1,
              'col': 1,
              'rowSpan': 12,
              'colSpan': 12,
            },
          },
          'rowCount': 100,
          'columnCount': 12,
          'width': 1440,
          'height': 900,
        },
        'groupType': 'group',
      },
    };

    for (var widget in widgets) {
      final widgetType = widget['type']?.toString().toLowerCase() ?? 'unknown';
      String category = 'Defaults';

      if ([
        'button',
        'textinput',
        'checkbox',
        'radio',
        'toggle',
        'switch',
        'counterbutton'
      ].contains(widgetType)) {
        category = 'Inputs';
      } else if (['image', 'card', 'chip', 'icon', 'avatar', 'qrcode']
          .contains(widgetType)) {
        category = 'DataDisplay';
      } else if (widgetType == 'tabs') {
        category = 'Navigation';
      }

      final isGroup = widgetType == 'group';
      final widgetId = widget['id']?.toString();
      if (widgetId == null) {
        continue;
      }
      jsonOutput[widgetId] = {
        'id': widgetId,
        'parent': widget['parentId']?.toString() ?? 'root',
        'type': widgetType,
        'T_parentId': widget['parentId']?.toString() ?? 'root',
        'children': widgets
            .where((w) => w['parentId'] == widgetId)
            .map((w) => w['id']?.toString())
            .where((id) => id != null)
            .toList(),
        'property': {
          'props': {
            'meta': {
              'row': widget['row'] as int? ?? 1,
              'col': widget['col'] as int? ?? 1,
              'rowSpan': widget['rowSpan'] as int? ?? 1,
              'colSpan': widget['colSpan'] as int? ?? 1,
            },
          },
          'name': widget['name']?.toString() ?? widgetType,
          'nodeType': widgetType,
          'description': '',
          if (isGroup) ...{
            'columnCount': 12,
            'rowCount': 4,
          } else ...{
            'rowCount': widget['rowSpan'] as int? ?? 1,
          },
        },
        'grid': {
          'style': {
            'styles': '',
          },
        },
        'groupType': 'group',
        't_parentId': widget['parentId']?.toString() ?? 'root',
        'data': {
          'label': widget['label']?.toString() ?? widgetType,
          'nodeAppearance': {
            'icon':
                'https://varnishdev.gsstvl.com/files/torus/9.1/resources/nodeicons/UF-UFM/$widgetType.svg',
            'label': widgetType,
            'color': '#0736C4',
            'shape': 'square',
            if (widgetType == 'button') 'size': 45,
          },
          'nodeProperty': {
            'nodeId': widgetId,
            'nodeName': widget['name']?.toString() ?? widgetType,
            'nodeType': widgetType,
            'nodeVersion': widget['nodeProperty']['nodeVersion'] ?? 'v1',
            ...widget['nodeProperty']
          },
        },
        'version': 'TRL:AFR:UF-UFM:Flutter:$category:$widgetType:v1',
      };
    }

    channel.sink.add(jsonEncode({
      'action': 'JSON',
      'json': jsonOutput,
      'sessionId': sessionId,
    }));
    print('Flutter: Emitted JSON to REACT ');
  }

  bool isPointInWidget(Offset point, Map<String, dynamic> group) {
    final groupPos = group['pos'] as Offset?;
    final groupSize = group['size'] as Size?;
    if (groupPos == null || groupSize == null) {
      return false;
    }
    return point.dx >= groupPos.dx &&
        point.dx < groupPos.dx + groupSize.width &&
        point.dy >= groupPos.dy &&
        point.dy < groupPos.dy + groupSize.height;
  }

bool isGridInGroup(int dropRow, int dropCol, Map<String, dynamic> group) {
  final gRow = group['row'] as int? ?? 1;
  final gCol = group['col'] as int? ?? 1;
  final gRowSpan = group['rowSpan'] as int? ?? 1;
  final gColSpan = group['colSpan'] as int? ?? 1;
  return dropRow >= gRow &&
         dropRow < gRow + gRowSpan &&
         dropCol >= gCol &&
         dropCol < gCol + gColSpan;
}

String? findGroupAtPosition(Offset pos, String? excludeId) {
  final dropRow = (pos.dy / rowHeight).floor() + 1;
  final dropCol = (pos.dx / columnWidth).floor() + 1;
  final candidates = widgets
      .where((w) => w['type'] == 'group' && w['id'] != excludeId)
      .where((group) => isGridInGroup(dropRow, dropCol, group))
      .toList();
  if (candidates.isEmpty) {
    return null;
  }
  candidates.sort((a, b) {
    final areaA = (a['rowSpan'] as int) * (a['colSpan'] as int);
    final areaB = (b['rowSpan'] as int) * (b['colSpan'] as int);
    return areaA.compareTo(areaB);  // Smallest span first (innermost)
  });
  return candidates.first['id']?.toString();
}

  List<String> _getDescendantIds(String? parentId) {
    if (parentId == null) return [];
    final descendantIds = <String>[];
    final children = widgets.where((w) => w['parentId'] == parentId).toList();
    for (var child in children) {
      final childId = child['id']?.toString();
      if (childId != null) {
        descendantIds.add(childId);
        if (child['type'] == 'group') {
          descendantIds.addAll(_getDescendantIds(childId));
        }
      }
    }
    return descendantIds;
  }

  void _showContextMenu(Offset position, Map<String, dynamic> widget) {
    final widgetId = widget['id']?.toString();
    if (widgetId == null) {
      return;
    }
    _hideContextMenu();

    final adjustedPosition = Offset(
      position.dx.clamp(0, 320 - 150),
      position.dy.clamp(0, 651 - 120),
    );

    _contextMenuOverlay = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _hideContextMenu,
        child: Stack(
          children: [
            Positioned(
              left: adjustedPosition.dx,
              top: adjustedPosition.dy,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Edit Node'),
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        onTap: () {
                          _hideContextMenu();
                          setState(() {
                            _editNode(widget);
                          });
                        },
                      ),
                      if (widget['type']?.toString().toLowerCase() != 'appbar')
                        ListTile(
                          title: const Text('Duplicate'),
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 0),
                          onTap: () {
                            _hideContextMenu();
                            _duplicateWidget(widget);
                          },
                        ),
                      ListTile(
                        title: const Text('Delete'),
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        onTap: () {
                          _hideContextMenu();
                          setState(() {
                            final deleteIds = [widgetId];
                            if (widget['type'] == 'group') {
                              final descendantIds = _getDescendantIds(widgetId);
                              deleteIds.addAll(descendantIds);
                            }
                            widgets.removeWhere(
                                (w) => deleteIds.contains(w['id']));
                            for (var id in deleteIds) {
                              channel.sink.add(jsonEncode({
                                'action': 'DELETE',
                                'id': id,
                                'sessionId': sessionId,
                              }));
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_contextMenuOverlay!);
  }

  void _hideContextMenu() {
    if (_contextMenuOverlay != null) {
      _contextMenuOverlay?.remove();
      _contextMenuOverlay = null;
    }
  }

  void _editNode(Map<String, dynamic> widget) {
    final widgetId = widget['id']?.toString();
    // if (widgetId == null) {
    //   return;
    // }

    final nodeData = Map<String, dynamic>.from(widget);
    Provider.of<GlobalProvider>(context, listen: false).setCurrentNode(nodeData);
    print('Flutter: Updated currentNode: ${Provider.of<GlobalProvider>(context, listen: false).currentNode}');

    channel.sink.add(jsonEncode({
      'action': 'SET_NODE_PROPERTY',
      'id': widgetId,
      'data': {
        'label': widget['label'],
        'nodeProperty': {
          'nodeId': widgetId,
          'nodeName': widget['name'],
          'nodeType': widget['type']?.toString() ?? 'unknown',
          'nodeVersion': widget['nodeProperty']?['nodeVersion'] ?? 'v1',
          ...widget['nodeProperty'],
        },
      },
      'sessionId': sessionId,
    }));

    emitJson();
  }

// Updated _duplicateWidget method (full method for context)
void _duplicateWidget(Map<String, dynamic> widget) {
  final widgetType = widget['type']?.toString().toLowerCase() ?? 'unknown';
  if (widgetType == 'appbar') {
    return;
  }
  final newId = DateTime.now().millisecondsSinceEpoch.toString();
  final pos = widget['pos'] as Offset? ?? const Offset(0, 0);
  Offset newPos = pos + const Offset(20, 20);
  int offsetCount = 0;
  while (widgets.any((w) => w['pos'] == newPos && w['id'] != newId)) {
    offsetCount++;
    newPos = pos + Offset(offsetCount * gridSize, offsetCount * gridSize);
  }
  final snappedPos = snapToGrid(newPos);
  final newParentId = findGroupAtPosition(snappedPos, newId) ?? 'root';
  final row = (snappedPos.dy / rowHeight).floor() + 1;
  final col = (snappedPos.dx / columnWidth).floor() + 1;
  final rowSpan = (widget['rowSpan'] as int?) ?? ((widget['size'] as Size?)?.height ?? rowHeight / rowHeight).ceil();
  final colSpan = (widget['colSpan'] as int?) ?? ((widget['size'] as Size?)?.width ?? columnWidth / columnWidth).ceil();

  // NEW: Recursive duplicate for groups (base case: add the widget itself)
  List<String> newChildIds = [];
  Map<String, dynamic> newWidget = {
    'id': newId,
    'type': widgetType,
    'pos': snappedPos,
    'size': widget['size'] as Size? ?? const Size(120, 50),
    'parentId': newParentId,
    'name': '${widget['name']?.toString() ?? widgetType}_copy',
    'label': '${widget['label']?.toString() ?? widgetType}_copy',
    'row': row,
    'col': col,
    'rowSpan': rowSpan,
    'colSpan': colSpan,
    'nodeProperty': widget['nodeProperty'],  // Copy properties
  };
  setState(() {
    widgets.add(newWidget);
  });

  // NEW: If group, recursively duplicate direct children (offset pos, new IDs)
  if (widgetType == 'group') {
    final originalChildren = widgets.where((w) => w['parentId'] == widget['id']).toList();
    for (var child in originalChildren) {
      final childNewId = DateTime.now().millisecondsSinceEpoch.toString() + '_' + child['id'].toString();
      final childPos = child['pos'] as Offset? ?? const Offset(0, 0);
      final childDelta = snappedPos - pos;  // Offset relative to group move
      final childNewPos = snapToGrid(childPos + childDelta);
      // Recurse for this child (but stop at groups? No, full recurse via helper)
      _duplicateChildRecursively(child, childNewId, childNewPos, newId, pos, snappedPos);  // Helper below
      newChildIds.add(childNewId);
    }
  }

  // Send DROP for the new widget (children sent in recursion)
  channel.sink.add(jsonEncode({
    'action': 'DROP',
    'id': newId,
    'type': widgetType,
    'x': snappedPos.dx,
    'y': snappedPos.dy,
    'width': (widget['size'] as Size?)?.width ?? 120.0,
    'height': (widget['size'] as Size?)?.height ?? 50.0,
    'parentId': newParentId,
    'name': newWidget['name'],
    'label': newWidget['label'],
    'row': row,
    'col': col,
    'rowSpan': rowSpan,
    'colSpan': colSpan,
    'sessionId': sessionId,
  }));
  emitJson();  // Sync full tree
}

// NEW: Helper for recursive child duplication
void _duplicateChildRecursively(Map<String, dynamic> original, String newId, Offset newPos, String newParentId, Offset originalGroupPos, Offset newGroupPos) {
  final childType = original['type']?.toString().toLowerCase() ?? 'unknown';
  final delta = newGroupPos - originalGroupPos;
  final snappedNewPos = snapToGrid((original['pos'] as Offset?)! + delta);
  final row = (snappedNewPos.dy / rowHeight).floor() + 1;
  final col = (snappedNewPos.dx / columnWidth).floor() + 1;
  final rowSpan = (original['rowSpan'] as int?) ?? 1;
  final colSpan = (original['colSpan'] as int?) ?? 1;

  final newChild = {
    'id': newId,
    'type': childType,
    'pos': snappedNewPos,
    'size': original['size'] as Size? ?? const Size(120, 50),
    'parentId': newParentId,
    'name': '${original['name']?.toString() ?? childType}_copy',
    'label': '${original['label']?.toString() ?? childType}_copy',
    'row': row,
    'col': col,
    'rowSpan': rowSpan,
    'colSpan': colSpan,
    'nodeProperty': original['nodeProperty'],
  };

  setState(() {
    widgets.add(newChild);
  });

  // Recurse for this child's children
  final grandChildren = widgets.where((w) => w['parentId'] == original['id']).toList();
  for (var grand in grandChildren) {
    final grandNewId = DateTime.now().millisecondsSinceEpoch.toString() + '_' + grand['id'].toString();
    final grandDelta = newPos - (original['pos'] as Offset? ?? Offset.zero);  // Relative to parent
    _duplicateChildRecursively(grand, grandNewId, (grand['pos'] as Offset?)! + grandDelta, newId, Offset.zero, Offset.zero);
  }

  // Send DROP for this child
  channel.sink.add(jsonEncode({
    'action': 'DROP',
    'id': newId,
    'type': childType,
    'x': snappedNewPos.dx,
    'y': snappedNewPos.dy,
    'width': newChild['size'].width,
    'height': newChild['size'].height,
    'parentId': newParentId,
    'name': newChild['name'],
    'label': newChild['label'],
    'row': row,
    'col': col,
    'rowSpan': rowSpan,
    'colSpan': colSpan,
    'sessionId': sessionId,
  }));
}

  Widget interactiveWrapper(Map<String, dynamic> w, Widget child) {
    final id = w['id']?.toString();
    if (id == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: (w['pos'] as Offset?)?.dx ?? 0.0,
      top: (w['pos'] as Offset?)?.dy ?? 0.0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (details) {
          _showContextMenu(details.globalPosition, w);
        },
        child: ResizableWidget(
          size: w['size'] as Size? ?? const Size(120, 50),
          pos: w['pos'] as Offset? ?? const Offset(0, 0),
          onResize: (newSize) {
            final snapped = snapSize(newSize);
            final rowSpan = (snapped.height / rowHeight).ceil();
            final colSpan = (snapped.width / columnWidth).ceil();
            setState(() {
              w['size'] = snapped;
              w['rowSpan'] = rowSpan;
              w['colSpan'] = colSpan;
            });

            channel.sink.add(jsonEncode({
              'action': 'RESIZE',
              'id': id,
              'width': snapped.width,
              'height': snapped.height,
              'rowSpan': rowSpan,
              'colSpan': colSpan,
              'sessionId': sessionId,
            }));
          },
          onMove: (newPos) {
            final delta = newPos - (w['pos'] as Offset? ?? const Offset(0, 0));
            final snapped = snapToGrid(newPos);
            final row = (snapped.dy / rowHeight).floor() + 1;
            final col = (snapped.dx / columnWidth).floor() + 1;
            setState(() {
              w['pos'] = snapped;
              w['row'] = row;
              w['col'] = col;

              final newParentId = findGroupAtPosition(snapped, id) ?? 'root';
              if (w['parentId'] != newParentId) {
                w['parentId'] = newParentId;
              }

              if (w['type'] == 'group') {
                final children =
                    widgets.where((child) => child['parentId'] == id).toList();
                for (var child in children) {
                  final childPos =
                      child['pos'] as Offset? ?? const Offset(0, 0);
                  final newChildPos = childPos + delta;
                  final snappedChildPos = snapToGrid(newChildPos);
                  final childRow = (snappedChildPos.dy / rowHeight).floor() + 1;
                  final childCol =
                      (snappedChildPos.dx / columnWidth).floor() + 1;
                  child['pos'] = snappedChildPos;
                  child['row'] = childRow;
                  child['col'] = childCol;
                }
              }
            });

            channel.sink.add(jsonEncode({
              'action': 'MOVE',
              'id': id,
              'x': snapped.dx,
              'y': snapped.dy,
              'row': row,
              'col': col,
              'parentId': w['parentId']?.toString() ?? 'root',
              'sessionId': sessionId,
            }));

            if (w['type'] == 'group') {
              final children =
                  widgets.where((child) => child['parentId'] == id).toList();
              for (var child in children) {
                final childId = child['id']?.toString();
                if (childId == null) continue;
                final snappedChildPos =
                    snapToGrid(child['pos'] as Offset? ?? const Offset(0, 0));
                final childRow = (snappedChildPos.dy / rowHeight).floor() + 1;
                final childCol = (snappedChildPos.dx / columnWidth).floor() + 1;
                channel.sink.add(jsonEncode({
                  'action': 'MOVE',
                  'id': childId,
                  'x': snappedChildPos.dx,
                  'y': snappedChildPos.dy,
                  'row': childRow,
                  'col': childCol,
                  'parentId': child['parentId']?.toString() ?? 'root',
                  'sessionId': sessionId,
                }));
              }
            }
          },
          child: child,
        ),
      ),
    );
  }

  PreferredSizeWidget? buildAppBarWidget(Map<String, dynamic> w) {
    final type = w['type']?.toString().toLowerCase() ?? 'unknown';
    final size = w['size'] as Size? ?? const Size(120, 50);
    if (type != 'appbar') {
      return null; // Return null instead of SizedBox.shrink() for Scaffold's appBar
    }
    return PreferredSize(
      preferredSize: Size(size.width, size.height),
      child: AppBar(
        title: Text(w['label']?.toString() ?? 'AppBar'),
        automaticallyImplyLeading: false,
      ),
    );
  }

  Widget buildWidget(Map<String, dynamic> w, bool isEdit) {
    final size = w['size'] as Size? ?? const Size(120, 50);
    final type = w['type']?.toString().toLowerCase() ?? 'unknown';
    Widget base;

 switch (type) {
      case 'appbar':
        base = PreferredSize(
          preferredSize: Size(size.width, size.height),
          child: AppBar(
            title: Text(w['label']?.toString() ?? 'AppBar'),
            automaticallyImplyLeading: false,
          ),
        );
        break;
      case 'floatingactionbutton':
        base = SizedBox(
          width: size.width,
          height: size.height,
          child: FloatingActionButton(
            onPressed: () {},
            tooltip: 'Save',
            child: const Icon(Icons.save),
          ),
        );
        break;
      case 'button':
        base = SizedBox(
            width: size.width,
            height: size.height,
          child: TorusButton(
            text: w['label']?.toString() ?? 'Click Me',
            varient: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'secondary';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'variant',
                orElse: () => null,
              );
              return variantProp?['value']?.toString() ?? 'secondary';
            }(),
          ),
        );
        break;
      case 'textinput':
        base = SizedBox(
          width: size.width,
          height: size.height,
          child: TTextField(
              type : () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'outlined-circle';
              }
              final typeProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'type',
                orElse: () => null,
              );
              return typeProp?['value'] ?? 'outlined-circle';
            }(),
              hintText :  w['label'] ?? 'Enter here' ,
              isDisabled : () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'false';
              }
              final isDisabledProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'isDisabled',
                orElse: () => null,
              );
              return isDisabledProp?['value'] ?? 'false';
            }() ,
              keyboardType: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return TextInputType.name; 
  }

  final keyboardTypeProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'keyboardType',
    orElse: () => null,
  );
  final keyboardTypeValue = keyboardTypeProp?['value']?.toString();
  switch (keyboardTypeValue) {
    case 'text':
      return TextInputType.text;
    case 'number':
      return TextInputType.number;
    case 'email':
      return TextInputType.emailAddress;
    case 'phone':
      return TextInputType.phone;
    case 'url':
      return TextInputType.url;
    case 'multiline':
      return TextInputType.multiline;
    default:
      return TextInputType.name;
  }
}(),
              textAlign: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return TextAlign.start; // Default textAlign
  }

  final textAlignProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'textAlign',
    orElse: () => null,
  );

  final textAlignValue = textAlignProp?['value']?.toString();
  switch (textAlignValue) {
    case 'start':
      return TextAlign.start;
    case 'end':
      return TextAlign.end;
    case 'left':
      return TextAlign.left;
    case 'right':
      return TextAlign.right;
    case 'center':
      return TextAlign.center;
    case 'justify':
      return TextAlign.justify;
    default:
      return TextAlign.start; // Default textAlign
  }
}(),
              textAlignVertical: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return TextAlignVertical.center; // Default textAlignVertical
  }

  final textAlignVerticalProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'textAlignVertical',
    orElse: () => null,
  );

  final textAlignVerticalValue = textAlignVerticalProp?['value']?.toString();
  switch (textAlignVerticalValue) {
    case 'top':
      return TextAlignVertical.top;
    case 'center':
      return TextAlignVertical.center;
    case 'bottom':
      return TextAlignVertical.bottom;
    default:
      return TextAlignVertical.center; // Default textAlignVertical
  }
}(),
              showCursor: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'false';
              }
              final showCursorProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'showCursor',
                orElse: () => null,
              );
              return showCursorProp?['value'] ?? 'false';
            }() ,
              helperText: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return '';
              }
              final helperTextProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'helperText',
                orElse: () => null,
              );
              return helperTextProp?['value'] ?? '';
            }() ,
              prefix: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  if (props == null || props.isEmpty) {
    return null; // Default to null for Widget?
  }
  final prefixProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'prefix',
    orElse: () => null,
  );
  final prefixValue = prefixProp?['value']?.toString();
  if (prefixValue != null && prefixValue.isNotEmpty) {
    return Text(prefixValue); // Convert string to Text widget
  }
  return null; 
}(),
              suffix: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  if (props == null || props.isEmpty) {
    return null; // Default to null for Widget?
  }
  final suffixProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'suffix',
    orElse: () => null,
  );
  final suffixValue = suffixProp?['value']?.toString();
  if (suffixValue != null && suffixValue.isNotEmpty) {
    return Text(suffixValue); 
  }
  return null; 
}(),
              needClear: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'false';
              }
              final needClearProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'needClear',
                orElse: () => null,
              );
              return needClearProp?['value'] ?? 'false';
            }()  ,
              label: w['label'] ?? 'Enter here' ,
              isFloatLabel: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'true';
              }
              final isFloatLabelProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'isFloatLabel',
                orElse: () => null,
              );
              return isFloatLabelProp?['value'] ?? 'true';
            }() ,
              fillColor: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return 'greyShade'; // Default fillColor
  }

  final fillColorProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'fillColor',
    orElse: () => null,
  );

  final fillColorValue = fillColorProp?['value']?.toString();
  return fillColorValue ?? 'greyShade';
}(),
              animationConfig: [],
              floatingLabelPosition: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return MainAxisAlignment.start; // Default floatingLabelPosition
  }

  final floatingLabelProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'floatingLabelPosition',
    orElse: () => null,
  );

  final floatingLabelValue = floatingLabelProp?['value']?.toString();
  switch (floatingLabelValue) {
    case 'start':
      return MainAxisAlignment.start;
    case 'end':
      return MainAxisAlignment.end;
    case 'center':
      return MainAxisAlignment.center;
    case 'spaceBetween':
      return MainAxisAlignment.spaceBetween;
    case 'spaceAround':
      return MainAxisAlignment.spaceAround;
    case 'spaceEvenly':
      return MainAxisAlignment.spaceEvenly;
    default:
      return MainAxisAlignment.start; // Default floatingLabelPosition
  }
}(),
          ),
        );
        break;
      case 'group':
        base = SizedBox(
          width: size.width,
          height: size.height,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 2.0),
              color: Colors.grey.withOpacity(0.1),
            ),
            child: Center(
                child: Text(w['label']?.toString() ?? 'group',
                    style: const TextStyle(fontSize: 16))),
          ),
        );
        break;
      case 'dropdown':
        base = SizedBox(
          width: size.width,
          height: size.height,
          child: TDropdown(
            type: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'outlined-circle';
              }
              final typeProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'type',
                orElse: () => null,
              );
              return typeProp?['value'] ?? 'outlined-circle';
            }(),
            hintText : w['label'] ?? 'Select here' ,  
            isDisabled : () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'false';
              }
              final isDisabledProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'isDisabled',
                orElse: () => null,
              );
              return isDisabledProp?['value'] ?? 'false';
            }() ,  
            label: w['label'] ?? 'Enter here' ,
            items: [],
            selectedItem:   () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return '';
              }
              final selectedItemProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'selectedItem',
                orElse: () => null,
              );
              return selectedItemProp?['value'] ?? '';
            }() ,
            helperText: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return '';
              }
              final helperTextProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'helperText',
                orElse: () => null,
              );
              return helperTextProp?['value'] ?? '';
            }() ,
            category: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return '';
              }
              final categoryProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'category',
                orElse: () => null,
              );
              return categoryProp?['value'] ?? '';
            }() ,
            fillColor: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return 'greyShade'; // Default fillColor
  }

  final fillColorProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'fillColor',
    orElse: () => null,
  );

  final fillColorValue = fillColorProp?['value']?.toString();
  return fillColorValue ?? 'greyShade';
}(),
            isFloatLabel:() {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'true';
              }
              final isFloatLabelProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'isFloatLabel',
                orElse: () => null,
              );
              return isFloatLabelProp?['value'] ?? 'true';
            }()  ,
            prefix: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  if (props == null || props.isEmpty) {
    return null; // Default to null for Widget?
  }
  final prefixProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'prefix',
    orElse: () => null,
  );
  final prefixValue = prefixProp?['value']?.toString();
  if (prefixValue != null && prefixValue.isNotEmpty) {
    return Text(prefixValue); // Convert string to Text widget
  }
  return null; 
}(),
            suffix: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  if (props == null || props.isEmpty) {
    return null; // Default to null for Widget?
  }
  final prefixProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'suffix',
    orElse: () => null,
  );
  final prefixValue = prefixProp?['value']?.toString();
  if (prefixValue != null && prefixValue.isNotEmpty) {
    return Text(prefixValue); 
  }
  return null; 
}(),
            floatingLabelPosition: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return MainAxisAlignment.start; // Default floatingLabelPosition
  }

  final floatingLabelProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'floatingLabelPosition',
    orElse: () => null,
  );

  final floatingLabelValue = floatingLabelProp?['value']?.toString();
  switch (floatingLabelValue) {
    case 'start':
      return MainAxisAlignment.start;
    case 'end':
      return MainAxisAlignment.end;
    case 'center':
      return MainAxisAlignment.center;
    case 'spaceBetween':
      return MainAxisAlignment.spaceBetween;
    case 'spaceAround':
      return MainAxisAlignment.spaceAround;
    case 'spaceEvenly':
      return MainAxisAlignment.spaceEvenly;
    default:
      return MainAxisAlignment.start; // Default floatingLabelPosition
  }
}(),
            animationConfig: [],

          ),
        );
        break;
      case 'textarea':
        base = SizedBox(
          width: size.width,
          height: size.height,
          child: TTextArea(
              type :  () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'outlined-circle';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'type',
                orElse: () => null,
              );
              return variantProp?['value'] ?? 'outlined-circle';
            }(),
              hintText :  w['label']?.toString() ?? 'Enter here...' ,
              isDisabled : () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'false';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'isDisabled',
                orElse: () => null,
              );
              return variantProp?['value'] ?? 'false';
            }() ,
              textAlign: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return TextAlign.start; // Default textAlign
  }

  final textAlignProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'textAlign',
    orElse: () => null,
  );

  final textAlignValue = textAlignProp?['value']?.toString();
  switch (textAlignValue) {
    case 'start':
      return TextAlign.start;
    case 'end':
      return TextAlign.end;
    case 'left':
      return TextAlign.left;
    case 'right':
      return TextAlign.right;
    case 'center':
      return TextAlign.center;
    case 'justify':
      return TextAlign.justify;
    default:
      return TextAlign.start; // Default textAlign
  }
}(),
              textAlignVertical: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return TextAlignVertical.center; // Default textAlignVertical
  }

  final textAlignVerticalProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'textAlignVertical',
    orElse: () => null,
  );

  final textAlignVerticalValue = textAlignVerticalProp?['value']?.toString();
  switch (textAlignVerticalValue) {
    case 'top':
      return TextAlignVertical.top;
    case 'center':
      return TextAlignVertical.center;
    case 'bottom':
      return TextAlignVertical.bottom;
    default:
      return TextAlignVertical.center; // Default textAlignVertical
  }
}(),
              showCursor: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'false';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'showCursor',
                orElse: () => null,
              );
              return variantProp?['value'] ?? 'false';
            }() ,       
              helperText: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return '';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'helperText',
                orElse: () => null,
              );
              return variantProp?['value'] ?? '';
            }() ,
              prefix: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  if (props == null || props.isEmpty) {
    return null; // Default to null for Widget?
  }
  final prefixProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'prefix',
    orElse: () => null,
  );
  final prefixValue = prefixProp?['value']?.toString();
  if (prefixValue != null && prefixValue.isNotEmpty) {
    return Text(prefixValue); 
  }
  return null; 
}(),
              suffix: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  if (props == null || props.isEmpty) {
    return null; // Default to null for Widget?
  }
  final prefixProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'suffix',
    orElse: () => null,
  );
  final prefixValue = prefixProp?['value']?.toString();
  if (prefixValue != null && prefixValue.isNotEmpty) {
    return Text(prefixValue); 
  }
  return null; 
}(),
              needClear: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'false';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'needClear',
                orElse: () => null,
              );
              return variantProp?['value'] ?? 'false';
            }()  ,
              label: w['label'] ?? 'Enter here' ,
              maxlines: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 3;
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'maxlines',
                orElse: () => null,
              );
              return variantProp?['value'] ?? 5;
            }() , 
              keyboardType: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return TextInputType.name; 
  }

  final keyboardTypeProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'keyboardType',
    orElse: () => null,
  );
  final keyboardTypeValue = keyboardTypeProp?['value']?.toString();
  switch (keyboardTypeValue) {
    case 'text':
      return TextInputType.text;
    case 'number':
      return TextInputType.number;
    case 'email':
      return TextInputType.emailAddress;
    case 'phone':
      return TextInputType.phone;
    case 'url':
      return TextInputType.url;
    case 'multiline':
      return TextInputType.multiline;
    default:
      return TextInputType.name;
  }
}(),
              fillColor: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return 'greyShade'; // Default fillColor
  }

  final fillColorProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'fillColor',
    orElse: () => null,
  );

  final fillColorValue = fillColorProp?['value']?.toString();
  return fillColorValue ?? 'greyShade';
}(),
              isFloatLabel:() {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'true';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'isFloatLabel',
                orElse: () => null,
              );
              return variantProp?['value'] ?? 'true';
            }()  ,
              floatingLabelPosition: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return MainAxisAlignment.start; // Default floatingLabelPosition
  }

  final floatingLabelProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'floatingLabelPosition',
    orElse: () => null,
  );

  final floatingLabelValue = floatingLabelProp?['value']?.toString();
  switch (floatingLabelValue) {
    case 'start':
      return MainAxisAlignment.start;
    case 'end':
      return MainAxisAlignment.end;
    case 'center':
      return MainAxisAlignment.center;
    case 'spaceBetween':
      return MainAxisAlignment.spaceBetween;
    case 'spaceAround':
      return MainAxisAlignment.spaceAround;
    case 'spaceEvenly':
      return MainAxisAlignment.spaceEvenly;
    default:
      return MainAxisAlignment.start; // Default floatingLabelPosition
  }
}(),
              animationConfig: [],

          ),
        );
        break;
      case 'timepicker':
        base = SizedBox(
          width: size.width,
          height: size.height,
          child: TTimePicker(
             type :  () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'outlined-circle';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'type',
                orElse: () => null,
              );
              return variantProp?['value'] ?? 'outlined-circle';
            }(),
             label: w['label'] ?? 'Enter here' ,
             hintText : w['label'] ?? 'Select here' ,  
             isDisabled : () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'false';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'isDisabled',
                orElse: () => null,
              );
              return variantProp?['value'] ?? 'false';
            }() ,
            //  timeFormat: ,
             helperText: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return '';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'helperText',
                orElse: () => null,
              );
              return variantProp?['value'] ?? '';
            }() ,
            //  timeFormat: ,
             fillColor: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return 'greyShade'; 
  }

  final fillColorProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'fillColor',
    orElse: () => null,
  );

  final fillColorValue = fillColorProp?['value']?.toString();
  return fillColorValue ?? 'greyShade';
}(),
             needClear:() {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'false';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'needClear',
                orElse: () => null,
              );
              return variantProp?['value'] ?? 'false';
            }()  ,
             prefix: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  if (props == null || props.isEmpty) {
    return null; // Default to null for Widget?
  }
  final prefixProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'prefix',
    orElse: () => null,
  );
  final prefixValue = prefixProp?['value']?.toString();
  if (prefixValue != null && prefixValue.isNotEmpty) {
    return Text(prefixValue); // Convert string to Text widget
  }
  return null; 
}(),
            suffix: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  if (props == null || props.isEmpty) {
    return null; // Default to null for Widget?
  }
  final prefixProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'suffix',
    orElse: () => null,
  );
  final prefixValue = prefixProp?['value']?.toString();
  if (prefixValue != null && prefixValue.isNotEmpty) {
    return Text(prefixValue); 
  }
  return null; 
}(),
            isFloatLabel:() {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'true';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'isFloatLabel',
                orElse: () => null,
              );
              return variantProp?['value'] ?? 'true';
            }()  ,
            floatingLabelPosition: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return MainAxisAlignment.start; // Default floatingLabelPosition
  }

  final floatingLabelProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'floatingLabelPosition',
    orElse: () => null,
  );

  final floatingLabelValue = floatingLabelProp?['value']?.toString();
  switch (floatingLabelValue) {
    case 'start':
      return MainAxisAlignment.start;
    case 'end':
      return MainAxisAlignment.end;
    case 'center':
      return MainAxisAlignment.center;
    case 'spaceBetween':
      return MainAxisAlignment.spaceBetween;
    case 'spaceAround':
      return MainAxisAlignment.spaceAround;
    case 'spaceEvenly':
      return MainAxisAlignment.spaceEvenly;
    default:
      return MainAxisAlignment.start; // Default floatingLabelPosition
  }
}(),
            animationConfig: [],
          ),
        );
        break;
      case 'radio':
        base = SizedBox(
          width: size.width,
          height: size.height,
          child: TRadio(),
        );
        break;
      case 'datepicker':
        base = SizedBox(
          width: size.width,
          height: size.height,
          child: TDatePicker(
              type : () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'outlined-circle';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'type',
                orElse: () => null,
              );
              return variantProp?['value'] ?? 'outlined-circle';
            }(),
              hintText :  w['label'] ?? 'Select date' ,
              isDisabled : () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'false';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'isDisabled',
                orElse: () => null,
              );
              return variantProp?['value'] ?? 'false';
            }() ,
              helperText: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return '';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'helperText',
                orElse: () => null,
              );
              return variantProp?['value'] ?? '';
            }() ,
              // selectedDate: ,
              // dateFormat: ,
              label: w['label'] ?? 'Enter here' ,
              needClear: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'false';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'needClear',
                orElse: () => null,
              );
              return variantProp?['value'] ?? 'false';
            }()  ,
              prefix: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  if (props == null || props.isEmpty) {
    return null; // Default to null for Widget?
  }
  final prefixProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'prefix',
    orElse: () => null,
  );
  final prefixValue = prefixProp?['value']?.toString();
  if (prefixValue != null && prefixValue.isNotEmpty) {
    return Text(prefixValue); // Convert string to Text widget
  }
  return null; 
}(),
              suffix: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  if (props == null || props.isEmpty) {
    return null; // Default to null for Widget?
  }
  final prefixProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'suffix',
    orElse: () => null,
  );
  final prefixValue = prefixProp?['value']?.toString();
  if (prefixValue != null && prefixValue.isNotEmpty) {
    return Text(prefixValue); 
  }
  return null; 
}(),
              fillColor: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return 'greyShade'; // Default fillColor
  }

  final fillColorProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'fillColor',
    orElse: () => null,
  );

  final fillColorValue = fillColorProp?['value']?.toString();
  return fillColorValue ?? 'greyShade';
}(),
              isFloatLabel:() {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'true';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'isFloatLabel',
                orElse: () => null,
              );
              return variantProp?['value'] ?? 'true';
            }()  ,
              floatingLabelPosition: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return MainAxisAlignment.start; // Default floatingLabelPosition
  }

  final floatingLabelProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'floatingLabelPosition',
    orElse: () => null,
  );

  final floatingLabelValue = floatingLabelProp?['value']?.toString();
  switch (floatingLabelValue) {
    case 'start':
      return MainAxisAlignment.start;
    case 'end':
      return MainAxisAlignment.end;
    case 'center':
      return MainAxisAlignment.center;
    case 'spaceBetween':
      return MainAxisAlignment.spaceBetween;
    case 'spaceAround':
      return MainAxisAlignment.spaceAround;
    case 'spaceEvenly':
      return MainAxisAlignment.spaceEvenly;
    default:
      return MainAxisAlignment.start; // Default floatingLabelPosition
  }
}(),
              // allowFutureDates: ,
              // allowPastDates: ,
              animationConfig: [],


          ),
        );
        break;
      case 'checkbox':
        base = SizedBox(
          width: size.width,
          height: size.height,
          child: TCheckbox(
            value: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'false';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'value',
                orElse: () => null,
              );
              return variantProp?['value'] ?? 'false';
            }() ,
            isDisabled: ()  {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'false';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'isDisabled',
                orElse: () => null,
              );
              return variantProp?['value'] ?? 'false';
            }()   ,
            contentPosition: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return 'right'; // Default contentPosition
  }

  final contentPositionProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'contentPosition',
    orElse: () => null,
  );

  final contentPositionValue = contentPositionProp?['value']?.toString();
  return contentPositionValue ?? 'right'; // Return string or default
}(),
            checkboxShape: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return 'squared'; // Default checkboxShape
  }

  final checkboxShapeProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'checkboxShape',
    orElse: () => null,
  );

  final checkboxShapeValue = checkboxShapeProp?['value']?.toString();
  return checkboxShapeValue ?? 'squared'; // Return string or default
}(),
            animationConfig: [],
          ),
        );
        break;
      case 'slider':
        base = SizedBox(
          width: size.width,
          height: size.height,
          child: TSlider(value: 0, onChanged: (value) {},
            size: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'medium';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'size',
                orElse: () => null,
              );
              return variantProp?['value'] ?? 'medium';
            }() ,
            min: 10 ,
            max: 100,
            divisions: 10 ,
            label: w['label'] ?? 'Enter here' ,
            labelPosition: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return 'right'; // Default contentPosition
  }

  final contentPositionProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'contentPosition',
    orElse: () => null,
  );

  final contentPositionValue = contentPositionProp?['value']?.toString();
  return contentPositionValue ?? 'right'; // Return string or default
}() ,
          ),
        );
        break;
      case 'switch':
        base = SizedBox(
          width: size.width,
          height: size.height,
          child: TSwitch(
            value: () { 
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'false';
              }
              final valueProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'value',
                orElse: () => null,
              );
              return valueProp?['value'] ?? 'false';
            }()  ,
            label: w['label'] ?? 'Enter here' ,
            isDisabled: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'false';
              }
              final isDisabledProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'isDisabled',
                orElse: () => null,
              );
              return isDisabledProp?['value'] ?? 'false';
            }(),
            leftContent: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return '';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'leftContent',
                orElse: () => null,
              );
              return variantProp?['value'] ?? '';
            }() ,
            rightContent:  () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return '';
              }
              final variantProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'rightContent',
                orElse: () => null,
              );
              return variantProp?['value'] ?? '';
            }(),

          ),
        );
        break;
      case 'avatar':
        base = SizedBox(
          width: size.width,
          height: size.height,
          child: TAvatar(
            text: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return ''; 
  }

  final textProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'text',
    orElse: () => null,
  );

  final textValue = textProp?['value'];
  return textValue ?? '';
}(),
            size: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return 'small'; 
  }

  final sizeProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'size',
    orElse: () => null,
  );

  final sizeValue = sizeProp?['value'];
  return sizeValue ?? 'small';
}(),
            imageUrl:  () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return ''; 
  }

  final iconProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'imageUrl',
    orElse: () => null,
  );

  final iconValue = iconProp?['value'];
  return iconValue ?? '';
}() ,
            icon: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return ''; 
  }

  final iconProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'icon',
    orElse: () => null,
  );

  final iconValue = iconProp?['value'];
  return iconValue ?? '';
}()  ,
            foregroundColor : () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return 'greyShade'; // Default fillColor
  }

  final foregroundColorProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'foregroundColor',
    orElse: () => null,
  );

  final foregroundColorValue = foregroundColorProp?['value'];
  return foregroundColorValue ?? 'greyShade';
}(),
            backgroundColor : () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return 'greyShade'; // Default fillColor
  }

  final backgroundColorProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'backgroundColor',
    orElse: () => null,
  );

  final backgroundColorValue = backgroundColorProp?['value'];
  return backgroundColorValue ?? 'greyShade';
}(), 
            animationConfig: [],
          ),
        );
        break;
      case 'chip':
        base = SizedBox(
          width: size.width,
          height: size.height,
          child: TChip(
            type: () {
        final provider = Provider.of<GlobalProvider>(context, listen: false);
        final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
        
        if (props == null || props.isEmpty) {
          return 'capsule';
        }

        final typeProp = props.firstWhere(
          (prop) => prop is Map && prop['name'] == 'type',
          orElse: () => null,
        );

        final typeValue = typeProp?['value'];
        switch (typeValue) {
          case 'capsule':
          case 'rectangle':
          case 'rounded':
            return typeValue;
          default:
            return 'capsule';
        }
      }(),
            icon: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  if (props == null || props.isEmpty) {
    return null; 
  }
  final prefixProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'icon',
    orElse: () => null,
  );
  final iconValue = prefixProp?['value']?.toString();
   return null; 
}() ,
            label: w['label'] ?? 'Enter here' ,
            backgroundcolor: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'secondary';
              }
              final foregroundcolorProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'backgroundcolor',
                orElse: () => null,
              );
              return foregroundcolorProp?['value']?.toString() ?? 'secondary';
            }(),
            foregroundcolor:  () {
            final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'secondary';
              }
              final foregroundcolorProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'variant',
                orElse: () => null,
              );
              return foregroundcolorProp?['value']?.toString() ?? 'secondary';
            }(),
            animationConfig: [],
          ),
        );
        break;
      case 'image':
        base = SizedBox(
          width: size.width,
          height: size.height,
          child: TImage(
            
            imageUrl : (Provider.of<GlobalProvider>(context, listen: false).currentNode['nodeProperty']
                              ?['elementInfo']?['props'] as List)[1]['value']
                          ?.toString() ??
                      'https://images.squarespace-cdn.com/content/v1/60f1a490a90ed8713c41c36c/1629223610791-LCBJG5451DRKX4WOB4SP/37-design-powers-url-structure.jpeg?format=2500w',
            size: (Provider.of<GlobalProvider>(context, listen: false).currentNode['nodeProperty']
                              ?['elementInfo']?['props'] as List)[1]['value']
                          ?.toString() ?? 'medium',          
          ),
        );
        break;
      case 'text':
        base = SizedBox(
          width: size.width,
          height: size.height,
          child: TextWidget(
            text: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return '';
              }
              final isDisabledProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'text',
                orElse: () => null,
              );
              return isDisabledProp?['value'] ?? '';
            }()  ,    
            textTheme: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'labelMedium';
              }
              final textThemeProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'textTheme',
                orElse: () => null,
              );
              return textThemeProp?['value']?.toString() ?? 'labelMedium';
            }(), 
            textOverflow:  () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'fade';
              }
              final textOverflowProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'textOverflow',
                orElse: () => null,
              );
              return textOverflowProp?['value'] ?? 'fade';
            }(), 
            textAlign: () {
  final provider = Provider.of<GlobalProvider>(context, listen: false);
  final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
  
  if (props == null || props.isEmpty) {
    return TextAlign.start; // Default textAlign
  }

  final textAlignProp = props.firstWhere(
    (prop) => prop is Map && prop['name'] == 'textAlign',
    orElse: () => null,
  );

  final textAlignValue = textAlignProp?['value']?.toString();
  switch (textAlignValue) {
    case 'start':
      return TextAlign.start;
    case 'end':
      return TextAlign.end;
    case 'left':
      return TextAlign.left;
    case 'right':
      return TextAlign.right;
    case 'center':
      return TextAlign.center;
    case 'justify':
      return TextAlign.justify;
    default:
      return TextAlign.start; // Default textAlign
  }
}(),
            fontWeight: () {
              final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'w100';
              }
              final fontWeightProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'fontWeight',
                orElse: () => null,
              );
              return fontWeightProp?['value'] ?? 'w100';
            }(),
            foregroundColor: () {
            final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'secondary';
              }
              final foregroundcolorProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'foregroundColor',
                orElse: () => null,
              );
              return foregroundcolorProp?['value']?.toString() ?? 'secondary';
            }(),
                          ),
        );
        break;
      case 'icon':
        base = SizedBox(
          width: size.width,
          height: size.height,
          child: TIcon(
            icon:  () {
            final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return '';
              }
              final colorProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'icon',
                orElse: () => null,
              );
              return colorProp?['value'] ?? '';
            }() ,
            size: () {
            final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'medium';
              }
              final colorProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'size',
                orElse: () => null,
              );
              return colorProp?['value'] ?? 'medium';
            }() ,
            color:  () {
            final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'secondary';
              }
              final colorProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'color',
                orElse: () => null,
              );
              return colorProp?['value'] ?? 'secondary';
            }() ,
            animationConfig: [],
          ),
         
        );
        break;
      case 'progressbar':
        base = SizedBox(
          width: size.width,
          height: size.height,
          child: TProgressbar(
           type: () { 
           final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'linear';
              }
              final isDisabledProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'type',
                orElse: () => null,
              );
              return isDisabledProp?['value'] ?? 'linear';
            }(),
           color: () {
            final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'secondary';
              }
              final colorProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'color',
                orElse: () => null,
              );
              return colorProp?['value'] ?? 'secondary';
            }(),
           backgroundColor: () {
            final provider =
                  Provider.of<GlobalProvider>(context, listen: false);
              final props = provider.currentNode['nodeProperty']?['elementInfo']
                  ?['props'] as List?;
              if (props == null || props.isEmpty) {
                return 'secondary';
              }
              final backgroundColorProp = props.firstWhere(
                (prop) => prop is Map && prop['name'] == 'backgroundColor',
                orElse: () => null,
              );
              return backgroundColorProp?['value'] ?? 'secondary';
            }(),
           animationConfig: [],


          ),
        );
        break;
      default:
        base = const SizedBox.shrink();
    }

    if (type == 'appbar') {
      return Positioned(
        left: 0,
        top: 0,
        child: base,
      );
    }

    return interactiveWrapper(w, base);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final appBarWidget = widgets.firstWhere(
      (w) => w['type']?.toString() == 'appbar',
      orElse: () => <String, dynamic>{},
    );
    final otherWidgets =
        widgets.where((w) => w['type']?.toString() != 'appbar').toList();

    return Scaffold(
      appBar: appBarWidget.isNotEmpty ? buildAppBarWidget(appBarWidget) : null,
      body: Container(
        color: Colors.white,
        width: screenSize.width,
        height: double.infinity,
        child: Stack(
          children: [
            CustomPaint(
              size: Size(screenSize.width, screenSize.height),
              painter: GridPainter(gridSize: gridSize),
            ),
            for (var w in otherWidgets) buildWidget(w, false),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final double gridSize;
  GridPainter({required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    // Vertical grid lines
    double x = 0;
    while (x <= size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      x += gridSize;
    }

    // Horizontal grid lines
    double y = 0;
    while (y <= size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += gridSize;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ResizableWidget extends StatefulWidget {
  final Widget child;
  final Size size;
  final Offset pos;
  final Function(Size) onResize;
  final Function(Offset) onMove;
  final bool dev;

  const ResizableWidget({
    super.key,
    required this.child,
    required this.size,
    required this.pos,
    required this.onResize,
    required this.onMove,
    this.dev = true,
  });

  @override
  State<ResizableWidget> createState() => _ResizableWidgetState();
}
 
 class _ResizableWidgetState extends State<ResizableWidget> {
  late double width;
  late double height;
  late Offset pos;
  bool _isResizing = false;
  bool _isDragging = false;
  bool _isHovered = false;
  String? _activeHandle;

  @override
  void initState() {
    super.initState();
    width = widget.size.width;
    height = widget.size.height;
    pos = widget.pos;
    print('Flutter: Initialized ResizableWidget at $pos with size $width x $height');
  }

  @override
  void didUpdateWidget(covariant ResizableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.size != widget.size) {
      setState(() {
        width = widget.size.width;
        height = widget.size.height;
        print('Flutter: Updated ResizableWidget size to $width x $height');
      });
    }
    if (oldWidget.pos != widget.pos) {
      setState(() {
        pos = widget.pos;
        print('Flutter: Updated ResizableWidget pos to $pos');
      });
    }
  }

  Widget _buildHandle({
    required String position,
    required Function(DragUpdateDetails) onPanUpdate,
  }) {
    const double handleSize = 8.0;
    const double offset = handleSize / 2;

    double? left, top, right, bottom;
    MouseCursor cursor;
    switch (position) {
      case 'top':
        left = (width - handleSize) / 2;
        top = -offset;
        cursor = SystemMouseCursors.resizeUpDown;
        break;
      case 'bottom':
        left = (width - handleSize) / 2;
        bottom = -offset;
        cursor = SystemMouseCursors.resizeUpDown;
        break;
      case 'left':
        left = -offset;
        top = (height - handleSize) / 2;
        cursor = SystemMouseCursors.resizeLeftRight;
        break;
      case 'right':
        right = -offset;
        top = (height - handleSize) / 2;
        cursor = SystemMouseCursors.resizeLeftRight;
        break;
      default:
        cursor = SystemMouseCursors.basic;
    }

    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) {
            setState(() {
              _isResizing = true;
              _activeHandle = position;
              print('Flutter: Started resizing at $position');
            });
          },
          onPanUpdate: onPanUpdate,
          onPanEnd: (_) {
            setState(() {
              _isResizing = false;
              _activeHandle = null;
              print('Flutter: Ended resizing, new size: $width x $height');
            });
            widget.onResize(Size(width, height));
            widget.onMove(pos);
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _activeHandle == position ? Colors.blue : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.dev) {
      return SizedBox(
        width: width,
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: widget.child,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
          print('Flutter: Hovered over ResizableWidget');
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
          print('Flutter: Exited ResizableWidget');
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          if (!_isResizing) {
            setState(() => _isDragging = true);
            print('Flutter: Started dragging');
          }
        },
        onPanUpdate: (details) {
          if (_isDragging && !_isResizing) {
            setState(() {
              pos += details.delta;
              print('Flutter: Dragging to $pos');
            });
            widget.onMove(pos);
          }
        },
        onPanEnd: (_) {
          if (_isDragging && !_isResizing) {
            setState(() => _isDragging = false);
            print('Flutter: Ended dragging at $pos');
            widget.onMove(pos);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _isResizing || _isDragging ? Colors.blue : Colors.grey.shade200,
              width: _isResizing || _isDragging ? 1.0 : 0.5,
            ),
          ),
          child: Stack(
            children: [
              SizedBox(
                width: width,
                height: height,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: widget.child,
                ),
              ),
              if (_isHovered || _isResizing || _isDragging) ...[
                _buildHandle(
                  position: 'top',
                  onPanUpdate: (details) {
                    setState(() {
                      double newHeight = (height - details.delta.dy).clamp(20.0, double.infinity);
                      double deltaY = height - newHeight;
                      pos = Offset(pos.dx, pos.dy + deltaY);
                      height = newHeight;
                    });
                  },
                ),
                _buildHandle(
                  position: 'bottom',
                  onPanUpdate: (details) {
                    setState(() {
                      height = (height + details.delta.dy).clamp(20.0, double.infinity);
                    });
                  },
                ),
                _buildHandle(
                  position: 'left',
                  onPanUpdate: (details) {
                    setState(() {
                      double newWidth = (width - details.delta.dx).clamp(20.0, double.infinity);
                      double deltaX = width - newWidth;
                      pos = Offset(pos.dx + deltaX, pos.dy);
                      width = newWidth;
                    });
                  },
                ),
                _buildHandle(
                  position: 'right',
                  onPanUpdate: (details) {
                    setState(() {
                      width = (width + details.delta.dx).clamp(20.0, double.infinity);
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}