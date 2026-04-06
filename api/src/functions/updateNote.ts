import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { getContainer, Note } from "../lib/cosmosClient";

// PATCH /api/notes/{id}?userId=<id>
export async function updateNote(req: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
  const id = req.params.id;
  const userId = req.query.get("userId");

  if (!id || !userId) {
    return { status: 400, jsonBody: { error: "Note id and userId are required" } };
  }

  let patch: Partial<Pick<Note, "title" | "body">>;
  try {
    patch = await req.json() as Partial<Pick<Note, "title" | "body">>;
  } catch {
    return { status: 400, jsonBody: { error: "Invalid JSON body" } };
  }

  try {
    const container = await getContainer();
    const { resource: existing } = await container.item(id, userId).read<Note>();

    if (!existing) {
      return { status: 404, jsonBody: { error: "Note not found" } };
    }

    const updated: Note = {
      ...existing,
      ...(patch.title !== undefined && { title: patch.title }),
      ...(patch.body !== undefined && { body: patch.body }),
      updatedAt: new Date().toISOString(),
    };

    const { resource } = await container.item(id, userId).replace(updated);
    return { status: 200, jsonBody: resource };
  } catch (err) {
    context.error("updateNote error:", err);
    return { status: 500, jsonBody: { error: "Failed to update note" } };
  }
}

app.http("updateNote", {
  methods: ["PATCH"],
  authLevel: "anonymous",
  route: "notes/{id}",
  handler: updateNote,
});
