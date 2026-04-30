const express = require('express');
const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');
const { PrismaClient } = require('@prisma/client');

const argv = yargs(hideBin(process.argv))
  .option('port', { alias: 'p', type: 'number', default: 8000 })
  .option('db_url', { type: 'string', description: 'Database connection string' })
  .argv;

const app = express();
const prisma = new PrismaClient();
app.use(express.json());

app.get('/health/alive', (req, res) => res.status(200).send('OK'));

app.get('/health/ready', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.status(200).send('OK');
  } catch (err) {
    res.status(500).send('Database connection failed');
  }
});

app.get('/items', async (req, res) => {
  const items = await prisma.item.findMany({ select: { id: true, name: true } });
  
  res.format({
    'text/html': () => {
      let table = '<table border="1"><tr><th>ID</th><th>Name</th></tr>';
      items.forEach(i => table += `<tr><td>${i.id}</td><td>${i.name}</td></tr>`);
      res.send(table + '</table>');
    },
    'application/json': () => res.json(items)
  });
});

app.get('/', (req, res) => {
  res.send(`
    <h1>Available Endpoints</h1>
    <ul>
      <li>GET /items</li>
      <li>POST /items</li>
      <li>GET /items/:id</li>
    </ul>
  `);
});

app.listen(argv.port, () => {
  console.log(`Server running on port ${argv.port}`);
});