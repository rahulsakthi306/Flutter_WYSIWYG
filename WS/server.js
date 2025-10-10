const WebSocket = require('ws');
// const wss = new WebSocket.Server({ port: 8080 });

const wss = new WebSocket.Server({ host: '0.0.0.0', port: 8080 });

const sessions = new Map();
const sessionStates = new Map();

wss.on('connection', (ws) => {
  let clientSessionId = null;

  ws.on('message', (message) => {
    let data;
    try {
      data = JSON.parse(message);
    } catch (err) {
      console.error('WebSocket: Invalid JSON:', message);
      return;
    }

    const { action, sessionId, id, x, y, width, height, type, parentId, json } = data;
    if (!sessionId || !['CONNECT', 'INIT', 'INIT_WIDGETS', 'DROP', 'MOVE', 'RESIZE', 'DELETE', 'REQUEST_JSON', 'JSON', 'SET_NODE_PROPERTY', 'UPDATE_CURRENT_NODE', 'SYNC'].includes(action)) {
      console.warn('WebSocket: Invalid message:', data);
      return;
    }

    if (!clientSessionId) {
      clientSessionId = sessionId;
      ws.sessionId = sessionId;
      if (!sessions.has(sessionId)) {
        sessions.set(sessionId, new Set());
        sessionStates.set(sessionId, {});
      }
      sessions.get(sessionId).add(ws);
      console.log(`WebSocket: Client connected to session: ${sessionId}, Total clients: ${sessions.get(sessionId).size}`);
    }

    // Update session state for DROP, MOVE, RESIZE, DELETE, INIT
    if (['INIT', 'INIT_WIDGETS', 'DROP', 'MOVE', 'RESIZE', 'DELETE', 'JSON','SET_NODE_PROPERTY', 'UPDATE_CURRENT_NODE', 'SYNC'].includes(action)) {
      let state = sessionStates.get(sessionId);
      if (action === 'INIT_WIDGETS') {
        // Store the full JSON (root and widget nodes)
        state = { ...data }; // Clone the entire INIT message
      } else if (action === 'DROP') {
        state.widgets = state.widgets || [];
        state.widgets.push({ id, type, x, y, width, height, parentId });
      } else if (action === 'MOVE') {
        state.widgets = (state.widgets || []).map((w) => (w.id === id ? { ...w, x, y, parentId } : w));
      } else if (action === 'RESIZE') {
        state.widgets = (state.widgets || []).map((w) => (w.id === id ? { ...w, width, height } : w));
      } else if (action === 'DELETE') {
        state.widgets = (state.widgets || []).filter((w) => w.id !== id);
      } else if(action === 'JSON'){
        state = { ...data };
      } else if(action === 'SET_NODE_PROPERTY'){
        state = { ...data };
      } else if(action === 'UPDATE_CURRENT_NODE'){
        state = { ...data };
      }
      sessionStates.set(sessionId, state);
    }

    // Broadcast to all clients in the session
    const clients = sessions.get(sessionId);
    if (clients) {
      clients.forEach((client) => {
        if (client.readyState === WebSocket.OPEN && client !== ws) { // Avoid sending back to sender
          client.send(JSON.stringify(data));
        }
      });
      console.log(`WebSocket: Broadcasted ${action} to ${clients.size - 1} other clients in session ${sessionId}`);
    }
  });

  ws.on('close', () => {
    if (clientSessionId && sessions.has(clientSessionId)) {
      sessions.get(clientSessionId).delete(ws);
      console.log(`WebSocket: Client disconnected from session: ${clientSessionId}, Remaining: ${sessions.get(clientSessionId).size}`);
      if (sessions.get(clientSessionId).size === 0) {
        sessions.delete(clientSessionId);
        sessionStates.delete(clientSessionId);
      }
    }
  });
});

console.log('WebSocket server running on ws://localhost:8080');