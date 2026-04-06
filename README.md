# Azure Notes — Learn Azure by Building

A cloud-native note-taking app designed to help you master Azure hands-on.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                        Azure                            │
│                                                         │
│  [Browser] ──► [Static Web App]                         │
│                      │                                  │
│                      ▼                                  │
│             [Azure Functions v4]  ◄── [App Insights]    │
│                      │                                  │
│                      ▼                                  │
│              [Cosmos DB (NoSQL)]                        │
│                                                         │
│  Secrets: Key Vault ◄── Managed Identity                │
│  Files:   Blob Storage                                  │
│  CI/CD:   GitHub Actions ──► Bicep ──► Azure            │
└─────────────────────────────────────────────────────────┘
```

## Azure Services Used

| Service | Purpose | Phase |
|---|---|---|
| Azure Functions | Serverless API (CRUD for notes) | 1 |
| Cosmos DB | NoSQL database | 1 |
| Azure Blob Storage | File attachments + Functions runtime | 2 |
| Key Vault | Secure secret storage | 3 |
| Managed Identity | Passwordless auth between services | 3 |
| App Insights | Logging, metrics, traces | 4 |
| Static Web Apps | Frontend hosting | 4 |
| Bicep (IaC) | Repeatable infra provisioning | All |
| GitHub Actions | CI/CD pipeline | All |

## Learning Phases

### Phase 1 — Run it locally
Get the API running on your machine against a real Cosmos DB.

**Prerequisites:**
- [Node.js 20+](https://nodejs.org)
- [Azure Functions Core Tools v4](https://learn.microsoft.com/azure/azure-functions/functions-run-local)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
- A free Azure account ([sign up](https://azure.microsoft.com/free/))

```bash
# 1. Run setup script
bash scripts/setup-local.sh

# 2. Fill in your Cosmos DB creds
#    Edit api/local.settings.json

# 3. Start the API
cd api && npm start

# 4. Open frontend/index.html in your browser
```

### Phase 2 — Deploy to Azure with Bicep
Provision all resources with one command.

```bash
bash scripts/deploy-infra.sh
```

Then update `API_BASE` in `frontend/app.js` with the output URL.

### Phase 3 — Set up CI/CD
1. Push this repo to GitHub
2. Create an Azure service principal:
   ```bash
   az ad sp create-for-rbac --name "github-azure-notes" \
     --role Contributor \
     --scopes /subscriptions/<sub-id>/resourceGroups/rg-azure-notes \
     --sdk-auth
   ```
3. Add the JSON output as GitHub secret `AZURE_CREDENTIALS`
4. Add your Static Web App token as `AZURE_STATIC_WEB_APPS_TOKEN`
5. Push to `main` — the workflow deploys everything automatically

### Phase 4 — Explore monitoring
After deploying, visit **Azure Portal → Application Insights → ai-func-notes-azn001** to see:
- Live requests and response times
- Failed requests and exceptions
- End-to-end traces

## Project Structure

```
azure-dev/
├── api/                    # Azure Functions (Node.js/TypeScript)
│   └── src/
│       ├── functions/      # HTTP trigger handlers
│       └── lib/            # Cosmos DB client
├── frontend/               # Static HTML/JS/CSS app
├── infra/                  # Bicep IaC templates
│   └── modules/            # Per-service modules
├── scripts/                # Helper shell scripts
└── .github/workflows/      # GitHub Actions CI/CD
```

## API Reference

| Method | Route | Description |
|---|---|---|
| GET | `/api/notes?userId=X` | List all notes for a user |
| POST | `/api/notes` | Create a new note |
| PATCH | `/api/notes/{id}?userId=X` | Update a note |
| DELETE | `/api/notes/{id}?userId=X` | Delete a note |

**Note shape:**
```json
{
  "id": "uuid",
  "userId": "user-001",
  "title": "My first note",
  "body": "Hello Azure!",
  "createdAt": "2026-04-06T00:00:00.000Z",
  "updatedAt": "2026-04-06T00:00:00.000Z"
}
```
