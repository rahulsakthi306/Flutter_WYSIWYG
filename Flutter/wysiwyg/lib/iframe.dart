// canvas_widget.dart (updated)
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/html.dart';
import 'package:wysiwyg/builder/widget.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:wysiwyg/provider/global.dart';
import 'package:wysiwyg/utils/constants.dart';

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

  String sessionId = Uri.base.queryParameters['sessionId'] ?? '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        columnWidth = 375 / columnCount;
        rowHeight = 812 / 100; 
        gridSize = 8.0;
      });
    });

    html.window.onContextMenu.listen((event) {
      event.preventDefault();
    });

    channel = HtmlWebSocketChannel.connect(dotenv.env['WS_URL'] ?? '');

    channel.sink.add(jsonEncode({'action': Constants.connect, 'sessionId': sessionId}));

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
          print('Flutter: Received action $action');
          setState(() {
            if(action == Constants.connect) {
              sessionId = data['sessionId'] as String;
            }
            if (action == Constants.initialize) {
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
              print('Flutter: Initialized widgets');

              emitJson();
              // channel.sink.add(jsonEncode({'action': 'SYNC', 'sessionId': sessionId}));
            } else if (action == Constants.drop) {
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

                final parentId = data['parentId']?.toString() ??
                    findGroupAtPosition(finalPos, id) ??
                    'root';

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
            } else if (action == Constants.resize) {
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
            } else if (action == Constants.move) {
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
                Provider.of<GlobalProvider>(context, listen: false).currentNode['nodeProperty']['elementInfo'][pathParts[0]][int.tryParse(pathParts[1])][pathParts[2]] = value;
                // Sync the update to the corresponding widget in the list
                final idx = widgets.indexWhere((w) => w['id'] == id);
                if (idx != -1 && widgets[idx]['nodeProperty'] != null) {
                  final nodeProperty =
                      widgets[idx]['nodeProperty'] as Map<String, dynamic>;
                  if (nodeProperty['elementInfo'] != null) {
                    final elementInfo =
                        nodeProperty['elementInfo'] as Map<String, dynamic>;
                    if (elementInfo[pathParts[0]] != null) {
                      final array = elementInfo[pathParts[0]] as List<dynamic>;
                      final index = int.tryParse(pathParts[1]);
                      if (index != null && index < array.length) {
                        final item = array[index] as Map<String, dynamic>;
                        item[pathParts[2]] = value;
                      }
                    }
                  }
                }
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
        Future.delayed(Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() {
            channel = HtmlWebSocketChannel.connect('ws://192.168.2.95:8080');
            channel.sink.add(jsonEncode({'action': 'CONNECT', 'sessionId': sessionId}));
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
      return areaA.compareTo(areaB); // Smallest span first (innermost)
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
                          emitJson();
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

    final nodeData = Map<String, dynamic>.from(widget);
    Provider.of<GlobalProvider>(context, listen: false).setCurrentNode(nodeData);

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
    final rowSpan = (widget['rowSpan'] as int?) ??
        ((widget['size'] as Size?)?.height ?? rowHeight / rowHeight).ceil();
    final colSpan = (widget['colSpan'] as int?) ??
        ((widget['size'] as Size?)?.width ?? columnWidth / columnWidth).ceil();

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
      'nodeProperty': widget['nodeProperty'], // Copy properties
    };
    setState(() {
      widgets.add(newWidget);
    });

    // NEW: If group, recursively duplicate direct children (offset pos, new IDs)
    if (widgetType == 'group') {
      final originalChildren =
          widgets.where((w) => w['parentId'] == widget['id']).toList();
      for (var child in originalChildren) {
        final childNewId = DateTime.now().millisecondsSinceEpoch.toString() +
            '_' +
            child['id'].toString();
        final childPos = child['pos'] as Offset? ?? const Offset(0, 0);
        final childDelta = snappedPos - pos; // Offset relative to group move
        final childNewPos = snapToGrid(childPos + childDelta);
        // Recurse for this child (but stop at groups? No, full recurse via helper)
        _duplicateChildRecursively(child, childNewId, childNewPos, newId, pos,
            snappedPos); // Helper below
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
    emitJson(); // Sync full tree
  }

// NEW: Helper for recursive child duplication
  void _duplicateChildRecursively(
      Map<String, dynamic> original,
      String newId,
      Offset newPos,
      String newParentId,
      Offset originalGroupPos,
      Offset newGroupPos) {
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
    final grandChildren =
        widgets.where((w) => w['parentId'] == original['id']).toList();
    for (var grand in grandChildren) {
      final grandNewId = DateTime.now().millisecondsSinceEpoch.toString() +
          '_' +
          grand['id'].toString();
      final grandDelta = newPos -
          (original['pos'] as Offset? ?? Offset.zero); // Relative to parent
      _duplicateChildRecursively(
          grand,
          grandNewId,
          (grand['pos'] as Offset?)! + grandDelta,
          newId,
          Offset.zero,
          Offset.zero);
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

    final type = w['type']?.toString().toLowerCase() ?? '';
    final fixedTypes = ['floatingactionbutton', 'radio', 'checkbox', 'switch', 'avatar', 'icon'];
    final allowResize = !fixedTypes.contains(type);

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
          allowResize: allowResize,
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

  @override
  Widget build(BuildContext context) {
    const double canvasWidth = 400;
    const double canvasHeight = 651;
    final screenSize = MediaQuery.of(context).size;
    final appBarWidget = widgets.firstWhere(
      (w) => w['type']?.toString() == 'appbar',
      orElse: () => <String, dynamic>{},
    );
    final otherWidgets =
        widgets.where((w) => w['type']?.toString() != 'appbar').toList();

    return Scaffold(
      appBar: appBarWidget.isNotEmpty ? buildAppBarWidget(appBarWidget) : null,
      // appBar: AppBar(title: Text('Flutter Editor'), automaticallyImplyLeading: false),
      body: Container(
        color: Colors.white,
        width: screenSize.width,
        height: double.infinity,
        child: Stack(
          children: [
            CustomPaint(
              size: Size(canvasWidth, canvasHeight),
              painter: GridPainter(gridSize: gridSize),
            ),
            for (var w in otherWidgets) 
              interactiveWrapper(w, buildBaseWidget(context, w, false)),
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
  final bool allowResize;
  final bool dev;

  const ResizableWidget({
    super.key,
    required this.child,
    required this.size,
    required this.pos,
    required this.onResize,
    required this.onMove,
    this.allowResize = true,
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
  }

  @override
  void didUpdateWidget(covariant ResizableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.size != widget.size) {
      setState(() {
        width = widget.size.width;
        height = widget.size.height;
      });
    }
    if (oldWidget.pos != widget.pos) {
      setState(() {
        pos = widget.pos;
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
            });
          },
          onPanUpdate: onPanUpdate,
          onPanEnd: (_) {
            setState(() {
              _isResizing = false;
              _activeHandle = null;
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
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          if (!_isResizing) {
            setState(() => _isDragging = true);
          }
        },
        onPanUpdate: (details) {
          if (_isDragging && !_isResizing) {
            setState(() {
              pos += details.delta;
            });
            widget.onMove(pos);
          }
        },
        onPanEnd: (_) {
          if (_isDragging && !_isResizing) {
            setState(() => _isDragging = false);
            widget.onMove(pos);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _isResizing || _isDragging
                  ? Colors.blue
                  : Colors.grey.shade200,
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
              if ((widget.allowResize ? (_isHovered || _isResizing || _isDragging) : (_isDragging)) ) ...[
                if (widget.allowResize) ...[
                  _buildHandle(
                    position: 'top',
                    onPanUpdate: (details) {
                      setState(() {
                        double newHeight = (height - details.delta.dy)
                            .clamp(20.0, double.infinity);
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
                        height = (height + details.delta.dy)
                            .clamp(20.0, double.infinity);
                      });
                    },
                  ),
                  _buildHandle(
                    position: 'left',
                    onPanUpdate: (details) {
                      setState(() {
                        double newWidth = (width - details.delta.dx)
                            .clamp(20.0, double.infinity);
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
                        width = (width + details.delta.dx)
                            .clamp(20.0, double.infinity);
                      });
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}