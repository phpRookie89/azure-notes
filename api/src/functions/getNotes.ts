import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { getContainer } from "../lib/cosmosClient";

// GET /api/notes?userId=<id>
export async function getNotes(req: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
  const userId = req.query.get("userId");

  if (!userId) {
    return { status: 400, jsonBody: { error: "userId query parameter is required" } };
  }

  try {
    const container = await getContainer();
    const { resources } = await container.items
      .query({
        query: "SELECT * FROM c WHERE c.userId = @userId ORDER BY c.createdAt DESC",
        parameters: [{ name: "@userId", value: userId }],
      })
      .fetchAll();

    return { status: 200, jsonBody: resources };
  } catch (err) {
    context.error("getNotes error:", err);
    return { status: 500, jsonBody: { error: "Failed to fetch notes" } };
  }
}

app.http("getNotes", {
  methods: ["GET"],
  authLevel: "anonymous",
  route: "notes",
  handler: getNotes,
});
