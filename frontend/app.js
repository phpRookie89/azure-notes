// ── Config ─────────────────────────────────────────────────
// Replace this with your deployed Function App URL after running deploy-infra.sh
const API_BASE = "https://func-notes-azn001.azurewebsites.net/api";

// ── Helpers ────────────────────────────────────────────────
const getUserId = () => document.getElementById("userId").value.trim();
const $ = (id) => document.getElementById(id);

function showError(msg) {
  alert("Error: " + msg);
}

// ── Render ─────────────────────────────────────────────────
function renderNotes(notes) {
  const container = $("notes");
  if (!notes.length) {
    container.innerHTML = '<p style="color:#9ca3af">No notes yet. Create one above!</p>';
    return;
  }

  container.innerHTML = notes
    .map(
      (n) => `
      <div class="note-card" data-id="${n.id}" data-userid="${n.userId}">
        <h3>${escapeHtml(n.title)}</h3>
        <p>${escapeHtml(n.body)}</p>
        <span class="note-meta">Created: ${new Date(n.createdAt).toLocaleString()}</span>
        <div class="note-actions">
          <button onclick="editNote('${n.id}', '${n.userId}')">Edit</button>
          <button class="delete-btn" onclick="deleteNote('${n.id}', '${n.userId}')">Delete</button>
        </div>
      </div>
    `
    )
    .join("");
}

function escapeHtml(str) {
  const d = document.createElement("div");
  d.appendChild(document.createTextNode(str));
  return d.innerHTML;
}

// ── API calls ───────────────────────────────────────────────
async function loadNotes() {
  const userId = getUserId();
  if (!userId) return showError("Enter a User ID first");

  const res = await fetch(`${API_BASE}/notes?userId=${encodeURIComponent(userId)}`);
  if (!res.ok) return showError("Failed to load notes");
  renderNotes(await res.json());
}

async function saveNote() {
  const userId = getUserId();
  const title = $("noteTitle").value.trim();
  const body = $("noteBody").value.trim();

  if (!userId || !title || !body) return showError("Fill in User ID, Title and Body");

  const res = await fetch(`${API_BASE}/notes`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ userId, title, body }),
  });

  if (!res.ok) return showError("Failed to save note");

  $("noteTitle").value = "";
  $("noteBody").value = "";
  await loadNotes();
}

async function editNote(id, userId) {
  const newTitle = prompt("New title:");
  if (newTitle === null) return;
  const newBody = prompt("New body:");
  if (newBody === null) return;

  const res = await fetch(`${API_BASE}/notes/${id}?userId=${encodeURIComponent(userId)}`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ title: newTitle, body: newBody }),
  });

  if (!res.ok) return showError("Failed to update note");
  await loadNotes();
}

async function deleteNote(id, userId) {
  if (!confirm("Delete this note?")) return;

  const res = await fetch(`${API_BASE}/notes/${id}?userId=${encodeURIComponent(userId)}`, {
    method: "DELETE",
  });

  if (res.status !== 204) return showError("Failed to delete note");
  await loadNotes();
}

// ── Event listeners ─────────────────────────────────────────
$("loadBtn").addEventListener("click", loadNotes);
$("saveBtn").addEventListener("click", saveNote);

// Auto-load on page start
loadNotes();
