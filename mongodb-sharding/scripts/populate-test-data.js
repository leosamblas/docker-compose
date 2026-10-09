// -----------------------------------------------------------------------------
// Script de teste para MongoDB Sharded Cluster
// Uso: docker exec -i mongo-router mongosh < scripts/populate-test-data.js
// -----------------------------------------------------------------------------

const dbName = "ecommerce";
const collName = "pedidos";

print(`\n>>> Alternando para o database '${dbName}'...`);
const db = db.getSiblingDB(dbName);

print(`>>> Habilitando Sharding no database '${dbName}'...`);
try {
  sh.enableSharding(dbName);
} catch (e) {
  print(`Nota: ${e}`);
}

print(`>>> Habilitando Sharding na coleção '${dbName}.${collName}' com Shard Key { clienteId: "hashed" }...`);
try {
  sh.shardCollection(`${dbName}.${collName}`, { "clienteId": "hashed" });
} catch (e) {
  print(`Nota: ${e}`);
}

print("\n>>> Inserindo 20.000 documentos em lotes de 1.000...");
var docs = [];
for (var i = 1; i <= 20000; i++) {
  docs.push({
    numero: i,
    clienteId: "cliente_" + (i % 500),
    valor: NumberDecimal((Math.random() * 500).toFixed(2)),
    status: (i % 2 === 0 ? "CONCLUIDO" : "PENDENTE"),
    data: new Date()
  });

  if (docs.length === 1000) {
    db[collName].insertMany(docs);
    docs = [];
    process.stdout.write(".");
  }
}

if (docs.length > 0) {
  db[collName].insertMany(docs);
}

print(`\n>>> Total de documentos inseridos: ${db[collName].countDocuments()}`);

print("\n========================================================");
print(">>> DISTRIBUIÇÃO DOS DADOS ENTRE OS SHARDS:");
print("========================================================");
db[collName].getShardDistribution();
print("========================================================\n");
