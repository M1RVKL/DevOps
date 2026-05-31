const express = require('express');
const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');
const { PrismaClient } = require('@prisma/client');

const argv = yargs(hideBin(process.argv))
  .option('port', { alias: 'p', type: 'number', default: 8000 })
  .option('db_url', { 
    type: 'string', 
    description: 'MariaDB connection string',
    default: process.env.DATABASE_URL 
  })
  .argv;

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: argv.db_url,
    },
  },
});
const app = express();
app.use(express.json());

app.get('/health/alive', (req, res) => res.status(200).send('OK'));

app.get('/health/ready', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.status(200).send('OK');
  } catch {
    res.status(500).send('Database connection failed');
  }
});

app.get('/', (req, res) => {
  res.send(`
    <h1>Simple Inventory API</h1>
    <ul>
      <li><a href="/items">GET /items</a></li>
      <li>POST /items (через API клієнт)</li>
    </ul>
  `);
});

app.get('/items', async (req, res) => {
  try {
    const items = await prisma.item.findMany({ select: { id: true, name: true } });
    res.format({
      'text/html': () => {
        let table = '<h1>Inventory Items</h1><table border="1"><tr><th>ID</th><th>Name</th></tr>';
        items.forEach(i => table += `<tr><td>${i.id}</td><td>${i.name}</td></tr>`);
        res.send(table + '</table>');
      },
      'application/json': () => res.json(items)
    });
  } catch {
    res.status(500).send("Error fetching items");
  }
});

app.post('/items', async (req, res) => {
  const { name, quantity } = req.body;
  try {
    const newItem = await prisma.item.create({
      data: { name, quantity: parseInt(quantity) }
    });
    res.status(201).json(newItem);
  } catch {
    res.status(400).send("Error creating item. Make sure that name and quantity are provided.");
  }
});

app.get('/items/:id', async (req, res) => {
  try {
    const item = await prisma.item.findUnique({
      where: { id: parseInt(req.params.id) }
    });

    if (!item) return res.status(404).send("Item not found");

    res.format({
      'text/html': () => {
        res.send(`
          <h1>Item Details</h1>
          <p><b>ID:</b> ${item.id}</p>
          <p><b>Name:</b> ${item.name}</p>
          <p><b>Quantity:</b> ${item.quantity}</p>
          <p><b>Created At:</b> ${item.createdAt}</p>
          <a href="/items">Back to list</a>
        `);
      },
      'application/json': () => res.json(item)
    });
  } catch {
    res.status(400).send("Invalid ID format");
  }
});

const socketFd = process.env.LISTEN_FDS > 0 ? 3 : null;

module.exports = app;