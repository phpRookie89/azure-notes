import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { getContainer } from "../lib/cosmosClient";

// DELETE /api/notes/{id}?userId=<id>
export async function deleteNote(req: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
  const id = req.params.id;
  const userId = req.query.get("userId");

  if (!id || !userId) {
    return { status: 400, jsonBody: { error: "Note id and userId are required" } };
  }

  try {
    const container = await getContainer();
    await container.item(id, userId).delete();
    return { status: 204 };
  } catch (err: any) {
    if (err?.code === 404) {
      return { status: 404, jsonBody: { error: "Note not found" } };
    }
    context.error("deleteNote error:", err);
    return { status: 500, jsonBody: { error: "Failed to delete note" } };
  }
}

app.http("deleteNote", {
  methods: ["DELETE"],
  authLevel: "anonymous",
  route: "notes/{id}",
  handler: deleteNote,
});
