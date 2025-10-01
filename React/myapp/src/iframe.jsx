import React, { useState, useEffect, useRef } from 'react';
import { v4 as uuidv4 } from 'uuid';

function debounce(func, wait) {
  let timeout;
  return (...args) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
}

const urlParams = new URLSearchParams(window.location.search);
const sessionId = urlParams.get('sessionId') || 'default';

function DragAndDrop() {
  const [paletteWidgets, setPaletteWidgets] = useState([]);
  const [canvasWidgets, setCanvasWidgets] = useState([]);
  const [dragging, setDragging] = useState(null);
  const [resizing, setResizing] = useState(null);
  const [moving, setMoving] = useState(null);
  const wsRef = useRef(null);

  const WS_URL = 'ws://192.168.2.95:8080';
  const canvasWidth = 320;
  const canvasHeight = 651;
  const gridSize = 20;
  const rowHeight = 100;
  const columnWidth = 1440 / 12;

  const snap = (val) => Math.round(val / gridSize) * gridSize;

  // Initial JSON to send on INIT
  // const initialJson = {
  //   "root": {
  //     "id": "root",
  //     "Parent": "root",
  //     "type": "Canvas",
  //     "T_parentId": "root",
  //     "children": [
  //       "4efea22f-791c-4c93-8624-1bcc5f61d741"
  //     ],
  //     "data": {
  //       "label": "Root",
  //       "nodeProperty": {
  //         "nodeId": "root",
  //         "nodeName": "Root",
  //         "nodeType": "Canvas",
  //         "nodeVersion": "v1",
  //         "elementInfo": {}
  //       }
  //     },
  //     "grid": {
  //       "style": {}
  //     },
  //     "property": {
  //       "name": "",
  //       "nodeType": "Canvas",
  //       "description": "",
  //       "backgroundColor": "#ffffff",
  //       "rowHeight": "100px",
  //       "rowGap": "10px",
  //       "columnGap": "10px",
  //       "props": {
  //         "meta": {
  //           "row": 1,
  //           "col": 1,
  //           "rowSpan": 12,
  //           "colSpan": 12
  //         }
  //       },
  //       "rowCount": 100,
  //       "columnCount": 12,
  //       "width": 1440,
  //       "height": 900
  //     },
  //     "groupType": "group"
  //   },
  //   "4efea22f-791c-4c93-8624-1bcc5f61d741": {
  //     "id": "4efea22f-791c-4c93-8624-1bcc5f61d741",
  //     "parent": "root",
  //     "type": "group",
  //     "T_parentId": "root",
  //     "children": [
  //       "c9db4aec-943b-4fd8-aa92-94bb31145d97",
  //       "6c4f1ada-bc18-4bd4-9797-3e6ed3402f47"
  //     ],
  //     "property": {
  //       "props": {
  //         "meta": {
  //           "row": 1,
  //           "col": 1,
  //           "rowSpan": 3,
  //           "colSpan": 3
  //         }
  //       },
  //       "name": "group",
  //       "nodeType": "group",
  //       "description": "",
  //       "columnCount": 12,
  //       "rowCount": 4
  //     },
  //     "grid": {
  //       "style": {
  //         "styles": ""
  //       }
  //     },
  //     "groupType": "group",
  //     "t_parentId": "root",
  //     "data": {
  //       "label": "group",
  //       "nodeAppearance": {
  //         "icon": "https://varnishdev.gsstvl.com/files/torus/9.1/resources/nodeicons/UF-UFM/group.svg",
  //         "label": "group",
  //         "color": "#0736C4",
  //         "shape": "square"
  //       },
  //       "nodeProperty": {}
  //     },
  //     "version": "TRL:AFR:UF-UFM:Flutter:Defaults:group:v1"
  //   },
  //   "c9db4aec-943b-4fd8-aa92-94bb31145d97": {
  //     "id": "c9db4aec-943b-4fd8-aa92-94bb31145d97",
  //     "parent": "4efea22f-791c-4c93-8624-1bcc5f61d741",
  //     "type": "textinput",
  //     "T_parentId": "4efea22f-791c-4c93-8624-1bcc5f61d741",
  //     "children": [],
  //     "property": {
  //       "props": {
  //         "meta": {
  //           "row": 1,
  //           "col": 1,
  //           "rowSpan": 1,
  //           "colSpan": 3
  //         }
  //       },
  //       "name": "textinput",
  //       "nodeType": "textinput",
  //       "description": "",
  //       "rowCount": 1
  //     },
  //     "grid": {
  //       "style": {
  //         "styles": ""
  //       }
  //     },
  //     "groupType": "group",
  //     "t_parentId": "4efea22f-791c-4c93-8624-1bcc5f61d741",
  //     "data": {
  //       "label": "textinput",
  //       "nodeAppearance": {
  //         "icon": "https://varnishdev.gsstvl.com/files/torus/9.1/resources/nodeicons/UF-UFM/textinput.svg",
  //         "label": "textinput",
  //         "color": "#0736C4",
  //         "shape": "square"
  //       },
  //       "nodeProperty": {}
  //     },
  //     "version": "TRL:AFR:UF-UFM:Flutter:Inputs:textinput:v1"
  //   },
  //   "6c4f1ada-bc18-4bd4-9797-3e6ed3402f47": {
  //     "id": "6c4f1ada-bc18-4bd4-9797-3e6ed3402f47",
  //     "parent": "4efea22f-791c-4c93-8624-1bcc5f61d741",
  //     "type": "button",
  //     "T_parentId": "4efea22f-791c-4c93-8624-1bcc5f61d741",
  //     "children": [],
  //     "property": {
  //       "props": {
  //         "meta": {
  //           "row": 2,
  //           "col": 1,
  //           "rowSpan": 1,
  //           "colSpan": 3
  //         }
  //       },
  //       "name": "button",
  //       "nodeType": "button",
  //       "description": "",
  //       "rowCount": 1
  //     },
  //     "grid": {
  //       "style": {
  //         "styles": ""
  //       }
  //     },
  //     "groupType": "group",
  //     "t_parentId": "4efea22f-791c-4c93-8624-1bcc5f61d741",
  //     "data": {
  //       "label": "button",
  //       "nodeAppearance": {
  //         "icon": "https://varnishdev.gsstvl.com/files/torus/9.1/resources/nodeicons/UF-UFM/button.svg",
  //         "label": "button",
  //         "color": "#0736C4",
  //         "shape": "square",
  //         "size": 45
  //       },
  //       "nodeProperty": {}
  //     },
  //     "version": "TRL:AFR:UF-UFM:Flutter:Inputs:button:v1"
  //   }
  // };

  const initialJson = {};

  // WebSocket connection
  useEffect(() => {
    let reconnectTimeout;

    const connectWebSocket = () => {
      wsRef.current = new WebSocket(WS_URL);

      wsRef.current.onopen = () => {
        console.log('WebSocket connected, readyState:', wsRef.current.readyState);
        if (wsRef.current.readyState === WebSocket.OPEN) {
          // Send CONNECT message
          wsRef.current.send(JSON.stringify({ action: 'CONNECT', sessionId }));
          // Send INIT message with JSON
          const initMessage = {
            action: 'INIT',
            sessionId,
            data: initialJson // Wrap initialJson in data
          };
          wsRef.current.send(JSON.stringify(initMessage));
          console.log('React: Sent INIT message:', JSON.stringify(initMessage, null, 2));

          // Populate canvasWidgets from JSON
          const newWidgets = Object.keys(initialJson)
            .filter((key) => key !== 'root')
            .map((key) => {
              const w = initialJson[key];
              const meta = w.property?.props?.meta || {};
              const row = meta.row || 1;
              const col = meta.col || 1;
              const rowSpan = meta.rowSpan || 1;
              const colSpan = meta.colSpan || 1;
              return {
                id: w.id,
                type: w.type.toUpperCase(),
                x: snap((col - 1) * columnWidth),
                y: snap((row - 1) * rowHeight),
                width: snap(colSpan * columnWidth),
                height: snap(rowSpan * rowHeight),
                parentId: w.parent || w.T_parentId || 'root',
                sessionId
              };
            });
          setCanvasWidgets(newWidgets);
          console.log('React: Initialized canvasWidgets:', newWidgets);
        }
      };

      wsRef.current.onmessage = (msg) => {
        try {
          const data = JSON.parse(msg.data);
          console.log('React: Received WebSocket message:', data);
          const { action, id, x, y, width, height, type, parentId, widgets, json } = data;

          if (action === 'SAVE') {
            console.log('React: Received Flutter SAVE JSON:', JSON.stringify(json, null, 2));
            return;
          }

        } catch (err) {
          console.error('React: WebSocket message parsing error:', err);
        }
      };

      wsRef.current.onclose = () => {
        console.log('React: WebSocket disconnected, reconnecting in 2s...');
        clearTimeout(reconnectTimeout);
        reconnectTimeout = setTimeout(connectWebSocket, 2000);
      };

      wsRef.current.onerror = (err) => {
        console.error('React: WebSocket error:', err);
        wsRef.current.close();
      };
    };

    connectWebSocket();

    return () => {
      clearTimeout(reconnectTimeout);
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, []);

  // Fetch Palette
  useEffect(() => {
    const fetchPalette = async () => {
      const widgets = [
        { name: 'BUTTON', group: 'Controls', icon: '', color: '#0736C4', redisKey: 'button1' },
        { name: 'TEXTINPUT', group: 'Controls', icon: '', color: '#0736C4', redisKey: 'textinput1' },
        { name: 'APPBAR', group: 'Controls', icon: '', color: '#0736C4', redisKey: 'appbar1' },
        { name: 'GROUP', group: 'Controls', icon: '', color: '#0736C4', redisKey: 'group1' },
        { name: 'DROPDOWN', group: 'Controls', icon: '', color: '#0736C4', redisKey: 'dropdown1' },
        { name: 'TEXTAREA', group: 'Controls', icon: '', color: '#0736C4', redisKey: 'textarea1' },
        { name: 'TIMEPICKER', group: 'Controls', icon: '', color: '#0736C4', redisKey: 'timepicker1' },
        { name: 'RADIO', group: 'Controls', icon: '', color: '#0736C4', redisKey: 'radio1' },
        { name: 'DATEPICKER', group: 'Controls', icon: '', color: '#0736C4', redisKey: 'datepicker1' },
        { name: 'CHECKBOX', group: 'Controls', icon: '', color: '#0736C4', redisKey: 'checkbox1' },
        { name: 'SLIDER', group: 'Controls', icon: '', color: '#0736C4', redisKey: 'slider1' },
        { name: 'SWITCH', group: 'Controls', icon: '', color: '#0736C4', redisKey: 'switch1' },
        { name: 'AVATAR', group: 'Display', icon: '', color: '#0736C4', redisKey: 'avatar1' },
        { name: 'CHIP', group: 'Display', icon: '', color: '#0736C4', redisKey: 'chip1' },
        { name: 'IMAGE', group: 'Display', icon: '', color: '#0736C4', redisKey: 'image1' },
        { name: 'TEXT', group: 'Display', icon: '', color: '#0736C4', redisKey: 'text1' },
        { name: 'ICON', group: 'Display', icon: '', color: '#0736C4', redisKey: 'icon1' },
        { name: 'PROGRESSBAR', group: 'Display', icon: '', color: '#0736C4', redisKey: 'progressbar1' },
      ];
      setPaletteWidgets(widgets);
    };

    fetchPalette();
  }, []);

  const handleDrop = (e) => {
    e.preventDefault();
    const widgetData = e.dataTransfer.getData('widget');

    if (widgetData) {
      try {
        const widget = JSON.parse(widgetData);
        const rect = e.currentTarget.getBoundingClientRect();
        const x = snap(e.clientX - rect.left);
        const y = snap(e.clientY - rect.top);

        let parentId = null;
        const container = canvasWidgets.find((w) => {
          if (w.type !== 'GROUP') return false;
          return (
            x >= w.x &&
            x <= w.x + w.width &&
            y >= w.y &&
            y <= w.y + w.height
          );
        });

        if (container && widget.name !== 'GROUP') {
          parentId = container.id;
        }

        // Set custom sizes based on widget type
        let width, height;
        switch (widget.name) {
          case 'GROUP':
            width = snap(200);
            height = snap(200);
            break;
          case 'TEXTAREA':
          case 'IMAGE':
            width = snap(200);
            height = snap(100);
            break;
          case 'AVATAR':
          case 'ICON':
            width = snap(50);
            height = snap(50);
            break;
          case 'PROGRESSBAR':
          case 'SLIDER':
            width = snap(200);
            height = snap(30);
            break;
          default:
            width = snap(120);
            height = snap(50);
        }

        const newWidget = {
          id: uuidv4(),
          type: widget.name,
          x,
          y,
          width,
          height,
          parentId,
          sessionId,
        };

        setCanvasWidgets((prev) => {
          const filtered = prev.filter((w) => w.id !== newWidget.id);
          return [...filtered, newWidget];
        });

        if (wsRef.current?.readyState === WebSocket.OPEN) {
          wsRef.current.send(JSON.stringify({ action: 'DROP', ...newWidget }));
          console.log('React: Sent DROP message:', newWidget);
        } else {
          console.warn('WebSocket not open, cannot send DROP action');
        }
      } catch (err) {
        console.error('Error parsing widget data:', err);
      }
    }

    setDragging(null);
  };

  const handleDragStartPalette = (e, widget) => {
    setDragging('palette');
    e.dataTransfer.setData('widget', JSON.stringify(widget));
  };

  const handleDragOver = (e) => e.preventDefault();

  const handleSave = () => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(
        JSON.stringify({
          action: 'REQUEST_JSON',
          sessionId,
        })
      );
      console.log('React: Sent REQUEST_JSON message:', { sessionId });
    } else {
      console.warn('WebSocket not open, cannot send REQUEST_JSON action');
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '20px' }}>
      <button
        onClick={handleSave}
        style={{
          marginBottom: '20px',
          padding: '10px 20px',
          backgroundColor: '#2b6cb0',
          color: 'white',
          border: 'none',
          borderRadius: '8px',
          cursor: 'pointer',
          fontSize: '16px',
        }}
      >
        Save
      </button>
      <div style={{ display: 'flex', justifyContent: 'center', gap: '20px' }}>
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(2, 1fr)',
            gap: '10px',
            overflowY: 'auto',
            border: '1px solid #ccc',
            padding: '10px',
            borderRadius: '8px',
          }}
        >
          {paletteWidgets.map((w) => (
            <div
              key={w.redisKey}
              draggable
              onDragStart={(e) => handleDragStartPalette(e, w)}
              onDragEnd={() => setDragging(null)}
              style={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                padding: '10px',
                borderRadius: '8px',
                border: '1px solid #ccc',
                backgroundColor: '#fff',
                cursor: 'grab',
                gap: '4px',
                minHeight: '80px',
                textAlign: 'center',
              }}
            >
              <img src={w.icon} alt={w.name} style={{ width: '24px', height: '24px' }} />
              <span style={{ fontSize: '12px', fontWeight: '500' }}>{w.name}</span>
              <span
                style={{
                  fontSize: '10px',
                  backgroundColor: '#2b6cb0',
                  color: 'white',
                  borderRadius: '8px',
                  padding: '2px 4px',
                }}
              >
                v1
              </span>
            </div>
          ))}
        </div>

        <div
          style={{
            position: 'relative',
            width: canvasWidth,
            height: canvasHeight,
            border: '1px solid #ccc',
            background: `repeating-linear-gradient(
              0deg,
              transparent,
              transparent ${gridSize - 1}px,
              #ccc ${gridSize - 1}px,
              #ccc ${gridSize}px
            ),
            repeating-linear-gradient(
              90deg,
              transparent,
              transparent ${gridSize - 1}px,
              #ccc ${gridSize - 1}px,
              #ccc ${gridSize}px
            )`,
          }}
          onDragOver={handleDragOver}
          onDrop={handleDrop}
        >
          <iframe
            src={`http://192.168.2.95:5000?sessionId=${sessionId}`}
            style={{ width: '100%', height: '100%', border: 'none', zIndex: 1 }}
          />
          {(dragging || moving || resizing) && (
            <div
              style={{
                position: 'absolute',
                top: 0,
                left: 0,
                width: '100%',
                height: '100%',
                zIndex: 2,
                backgroundColor: 'transparent',
              }}
            />
          )}
        </div>
      </div>
    </div>
  );
}

export default DragAndDrop;