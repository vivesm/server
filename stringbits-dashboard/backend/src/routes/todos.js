const express = require('express');
const router = express.Router();
const fs = require('fs').promises;
const path = require('path');

// In-memory storage for todos (in production, use a database)
let todos = [];
let nextId = 1;

// Load todos from file on startup
const TODOS_FILE = path.join(__dirname, '../../data/todos.json');

async function loadTodos() {
  try {
    const data = await fs.readFile(TODOS_FILE, 'utf8');
    const parsed = JSON.parse(data);
    todos = parsed.todos || [];
    nextId = parsed.nextId || 1;
  } catch (error) {
    console.log('No existing todos file, starting fresh');
    todos = [
      {
        id: 1,
        title: 'Enable UFW Firewall',
        description: 'Critical security task - firewall is currently disabled',
        status: 'pending',
        priority: 'high',
        category: 'security',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        id: 2,
        title: 'Change n8n default password',
        description: 'Default credentials are active on n8n service',
        status: 'pending',
        priority: 'high',
        category: 'security',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        id: 3,
        title: 'Restrict SSH to Tailscale',
        description: 'SSH is currently open to all interfaces',
        status: 'pending',
        priority: 'high',
        category: 'security',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        id: 4,
        title: 'Setup automated backups',
        description: 'Configure cron job for daily backups',
        status: 'pending',
        priority: 'medium',
        category: 'maintenance',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        id: 5,
        title: 'Document API endpoints',
        description: 'Create comprehensive API documentation',
        status: 'in_progress',
        priority: 'low',
        category: 'documentation',
        createdAt: new Date(),
        updatedAt: new Date()
      }
    ];
    nextId = 6;
  }
}

async function saveTodos() {
  try {
    await fs.mkdir(path.dirname(TODOS_FILE), { recursive: true });
    await fs.writeFile(TODOS_FILE, JSON.stringify({ todos, nextId }, null, 2));
  } catch (error) {
    console.error('Error saving todos:', error);
  }
}

// Load todos on startup
loadTodos();

// Get all todos
router.get('/', async (req, res) => {
  try {
    const { status, priority, category } = req.query;
    
    let filteredTodos = [...todos];
    
    // Apply filters
    if (status) {
      filteredTodos = filteredTodos.filter(todo => todo.status === status);
    }
    if (priority) {
      filteredTodos = filteredTodos.filter(todo => todo.priority === priority);
    }
    if (category) {
      filteredTodos = filteredTodos.filter(todo => todo.category === category);
    }
    
    // Sort by priority and date
    filteredTodos.sort((a, b) => {
      const priorityOrder = { high: 3, medium: 2, low: 1 };
      if (priorityOrder[a.priority] !== priorityOrder[b.priority]) {
        return priorityOrder[b.priority] - priorityOrder[a.priority];
      }
      return new Date(b.createdAt) - new Date(a.createdAt);
    });
    
    res.json({
      todos: filteredTodos,
      summary: {
        total: todos.length,
        pending: todos.filter(t => t.status === 'pending').length,
        in_progress: todos.filter(t => t.status === 'in_progress').length,
        completed: todos.filter(t => t.status === 'completed').length,
        high_priority: todos.filter(t => t.priority === 'high' && t.status !== 'completed').length
      }
    });
  } catch (error) {
    console.error('Todos error:', error);
    res.status(500).json({ error: 'Failed to fetch todos' });
  }
});

// Get single todo
router.get('/:id', async (req, res) => {
  try {
    const todo = todos.find(t => t.id === parseInt(req.params.id));
    if (!todo) {
      return res.status(404).json({ error: 'Todo not found' });
    }
    res.json(todo);
  } catch (error) {
    console.error('Todo detail error:', error);
    res.status(500).json({ error: 'Failed to fetch todo' });
  }
});

// Create new todo
router.post('/', async (req, res) => {
  try {
    const { title, description, priority = 'medium', category = 'general' } = req.body;
    
    if (!title) {
      return res.status(400).json({ error: 'Title is required' });
    }
    
    const newTodo = {
      id: nextId++,
      title,
      description: description || '',
      status: 'pending',
      priority,
      category,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    todos.push(newTodo);
    await saveTodos();
    
    res.status(201).json(newTodo);
  } catch (error) {
    console.error('Create todo error:', error);
    res.status(500).json({ error: 'Failed to create todo' });
  }
});

// Update todo
router.put('/:id', async (req, res) => {
  try {
    const todoIndex = todos.findIndex(t => t.id === parseInt(req.params.id));
    if (todoIndex === -1) {
      return res.status(404).json({ error: 'Todo not found' });
    }
    
    const updatedTodo = {
      ...todos[todoIndex],
      ...req.body,
      id: todos[todoIndex].id, // Prevent ID change
      updatedAt: new Date()
    };
    
    todos[todoIndex] = updatedTodo;
    await saveTodos();
    
    res.json(updatedTodo);
  } catch (error) {
    console.error('Update todo error:', error);
    res.status(500).json({ error: 'Failed to update todo' });
  }
});

// Delete todo
router.delete('/:id', async (req, res) => {
  try {
    const todoIndex = todos.findIndex(t => t.id === parseInt(req.params.id));
    if (todoIndex === -1) {
      return res.status(404).json({ error: 'Todo not found' });
    }
    
    todos.splice(todoIndex, 1);
    await saveTodos();
    
    res.json({ message: 'Todo deleted successfully' });
  } catch (error) {
    console.error('Delete todo error:', error);
    res.status(500).json({ error: 'Failed to delete todo' });
  }
});

// Bulk update todos (for marking multiple as complete, etc)
router.post('/bulk', async (req, res) => {
  try {
    const { ids, updates } = req.body;
    
    if (!Array.isArray(ids) || ids.length === 0) {
      return res.status(400).json({ error: 'IDs array is required' });
    }
    
    const updatedTodos = [];
    
    ids.forEach(id => {
      const todoIndex = todos.findIndex(t => t.id === id);
      if (todoIndex !== -1) {
        todos[todoIndex] = {
          ...todos[todoIndex],
          ...updates,
          id: todos[todoIndex].id, // Prevent ID change
          updatedAt: new Date()
        };
        updatedTodos.push(todos[todoIndex]);
      }
    });
    
    await saveTodos();
    
    res.json({
      updated: updatedTodos.length,
      todos: updatedTodos
    });
  } catch (error) {
    console.error('Bulk update error:', error);
    res.status(500).json({ error: 'Failed to update todos' });
  }
});

module.exports = router;