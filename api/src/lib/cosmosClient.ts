import { CosmosClient, Container } from "@azure/cosmos";

// In production, these values come from Key Vault via app settings.
// Locally, they come from local.settings.json.
const endpoint = process.env.COSMOS_ENDPOINT!;
const key = process.env.COSMOS_KEY!;
const databaseId = process.env.COSMOS_DATABASE ?? "notesdb";
const containerId = process.env.COSMOS_CONTAINER ?? "notes";

let _container: Container | null = null;

export async function getContainer(): Promise<Container> {
  if (_container) return _container;

  const client = new CosmosClient({ endpoint, key });

  // Creates database + container if they don't exist (dev convenience).
  const { database } = await client.databases.createIfNotExists({ id: databaseId });
  const { container } = await database.containers.createIfNotExists({
    id: containerId,
    partitionKey: { paths: ["/userId"] },
  });

  _container = container;
  return _container;
}

export interface Note {
  id?: string;
  userId: string;
  title: string;
  body: string;
  createdAt: string;
  updatedAt: string;
}
