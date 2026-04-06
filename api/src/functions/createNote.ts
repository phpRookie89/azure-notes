import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { getContainer, Note } from "../lib/cosmosClient";
import { randomUUID } from "crypto";

// POST /api/notes
export async function createNote(req: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
  let body: Partial<Note>;

  try {
    body = await req.json() as Partial<Note>;
  } catch {
    return { status: 400, jsonBody: { error: "Invalid JSON body" } };
  }

  const { userId, title, body: noteBody } = body;

  if (!userId || !title || !noteBody) {
    return { status: 400, jsonBody: { error: "userId, title, and body are required" } };
  }

  const now = new Date().toISOString();
  const note: Note = {
    id: randomUUID(),
    userId,
    title,
    body: noteBody,
    createdAt: now,
    updatedAt: now,
  };

  try {
    const container = await getContainer();
    const { resource } = await container.items.create(note);
    return { status: 201, jsonBody: resource };
  } catch (err) {
    context.error("createNote error:", err);
    return { status: 500, jsonBody: { error: "Failed to create note" } };
  }
}

app.http("createNote", {
  methods: ["POST"],
  authLevel: "anonymous",
  route: "notes",
  handler: createNote,
});
