(() => {
  "use strict";
  const data = window.CHANGE_MAP_DATA;
  if (!data) throw new Error("Missing Change Map data");

  const $ = (selector, root = document) => root.querySelector(selector);
  const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];
  const esc = (value = "") => String(value).replace(/[&<>"']/g, (char) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  })[char]);
  const label = (value = "") => value.replace(/[-_]/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
  const icon = {entry:"→",function:"ƒ",component:"◫",route:"↗",state:"◇",transform:"⇄",database:"◉",external:"✉",queue:"≋",job:"⚙",test:"✓",abstraction:"◆"};
  const statusGlyph = {unchanged:"",modified:"M",added:"+",removed:"−",inferred:"?",implemented:"✓",deviated:"!"};
  const currentStatuses = new Set(["unchanged", "modified", "removed", "inferred", "implemented", "deviated"]);
  const proposedStatuses = new Set(["unchanged", "modified", "added", "inferred", "implemented", "deviated"]);

  let mode = data.stage === "implemented" ? "implemented" : "proposed";
  let zoom = window.innerWidth <= 900 ? 0.48 : 0.78;
  let panX = 0;
  let panY = 0;
  let dragging = false;
  let dragStart;

  const stage = $("#graphStage");
  const viewport = $("#viewport");
  const nodesRoot = $("#nodes");
  const edgeSvg = $("#edges");

  function setHeader() {
    const request = data.request || {};
    $("#repo").textContent = request.repository || "repository";
    $("#branch").textContent = request.branch || "working tree";
    $("#time").textContent = request.analyzedAt ? new Date(request.analyzedAt).toLocaleString() : "Analyzed now";
    $("#stage").textContent = `${label(data.stage || "proposed")} change`;
    $("#confidence").textContent = `${Math.round((data.confidence ?? 1) * 100)}% confidence`;
    $("#title").textContent = request.title || "Proposed change";
    $("#description").textContent = request.summary || "";
    $("#fileCount").textContent = data.impact?.files?.length || 0;
    $("#symbolCount").textContent = data.impact?.symbols?.length || data.nodes.length;
    $("#assumptionCount").textContent = data.impact?.assumptions?.length || 0;
    const changeCounts = data.nodes.reduce((acc, node) => ((acc[node.status] = (acc[node.status] || 0) + 1), acc), {});
    $("#reviewSummary").textContent = `${changeCounts.added || 0} additions · ${changeCounts.modified || 0} modifications · ${data.impact?.assumptions?.length || 0} assumptions`;
  }

  function visibleInMode(node, selectedMode) {
    if (selectedMode === "current") return currentStatuses.has(node.status);
    if (selectedMode === "proposed") return proposedStatuses.has(node.status);
    return true;
  }

  function layoutGraph() {
    const nodes = data.nodes;
    const incoming = new Map(nodes.map((node) => [node.id, 0]));
    const outgoing = new Map(nodes.map((node) => [node.id, []]));
    data.edges.forEach((edge) => {
      if (incoming.has(edge.target)) incoming.set(edge.target, incoming.get(edge.target) + 1);
      if (outgoing.has(edge.source)) outgoing.get(edge.source).push(edge.target);
    });

    const levels = new Map();
    const queue = nodes.filter((node) => incoming.get(node.id) === 0).map((node) => node.id);
    if (!queue.length && nodes[0]) queue.push(nodes[0].id);
    queue.forEach((id) => levels.set(id, 0));

    while (queue.length) {
      const id = queue.shift();
      const nextLevel = (levels.get(id) || 0) + 1;
      (outgoing.get(id) || []).forEach((target) => {
        if (!levels.has(target) || levels.get(target) < nextLevel) {
          levels.set(target, Math.min(nextLevel, 4));
          queue.push(target);
        }
      });
    }
    nodes.forEach((node) => { if (!levels.has(node.id)) levels.set(node.id, 0); });

    const columns = new Map();
    nodes.forEach((node) => {
      const level = levels.get(node.id);
      if (!columns.has(level)) columns.set(level, []);
      columns.get(level).push(node);
    });

    const positions = new Map();
    [...columns.entries()].sort((a,b) => a[0]-b[0]).forEach(([level, column]) => {
      const gap = 132;
      const total = (column.length - 1) * gap;
      column.forEach((node, index) => positions.set(node.id, {
        x: 40 + level * 285,
        y: 330 - total / 2 + index * gap - 54,
      }));
    });
    return positions;
  }

  const positions = layoutGraph();

  function sourceLabel(node) {
    if (!node.source?.file) return "Planned";
    const line = node.source.startLine ? `:${node.source.startLine}${node.source.endLine && node.source.endLine !== node.source.startLine ? `–${node.source.endLine}` : ""}` : ":new";
    return `${node.source.file}${line}`;
  }

  function renderNodes() {
    nodesRoot.innerHTML = data.nodes.map((node, index) => {
      const position = positions.get(node.id);
      const code = node.proposedCode || node.code || "";
      return `<article class="node ${esc(node.status)}" data-node="${esc(node.id)}" style="left:${position.x}px;top:${position.y}px;animation-delay:${Math.min(index * 55, 400)}ms">
        <button class="node-main">
          <span class="node-icon">${esc(icon[node.kind] || "◇")}</span>
          <span class="node-copy"><span class="node-kind">${esc(label(node.kind))} · ${esc(label(node.status))}</span><strong>${esc(node.label)}</strong><small>${esc(node.summary)}</small></span>
          <span class="status">${esc(statusGlyph[node.status] || "")}</span>
        </button>
        <footer><span title="${esc(sourceLabel(node))}">${esc(sourceLabel(node))}</span>${code ? '<button class="code-toggle">Code ›</button>' : `<span>${Math.round(node.confidence * 100)}%</span>`}</footer>
        ${code ? `<div class="code"><div class="code-head"><span>${esc(node.source?.file || "proposed")}</span><button class="copy">Copy</button></div><pre>${esc(code)}</pre></div>` : ""}
      </article>`;
    }).join("");

    $$(".node").forEach((element) => {
      $(".node-main", element).addEventListener("click", () => selectNode(element.dataset.node));
      element.addEventListener("dblclick", () => focusNode(element.dataset.node));
      $(".code-toggle", element)?.addEventListener("click", (event) => {
        event.stopPropagation();
        element.classList.toggle("expanded");
      });
      $(".copy", element)?.addEventListener("click", async () => {
        const text = $("pre", element).textContent;
        try { await navigator.clipboard.writeText(text); showToast("Source copied", "Code excerpt copied to clipboard."); }
        catch { showToast("Copy unavailable", "Select the source manually."); }
      });
    });
  }

  function edgePath(source, target, index) {
    const sx = source.x + 236, sy = source.y + 54;
    const tx = target.x, ty = target.y + 54;
    if (tx >= sx) {
      const curve = Math.max(38, (tx - sx) * .48);
      return `M${sx} ${sy} C${sx + curve} ${sy},${tx - curve} ${ty},${tx} ${ty}`;
    }
    const offset = 34 + index * 5;
    return `M${sx} ${sy} C${sx + offset} ${sy + 90},${tx - offset} ${ty + 90},${tx} ${ty}`;
  }

  function renderEdges() {
    edgeSvg.setAttribute("viewBox", "0 0 1200 700");
    edgeSvg.innerHTML = `<defs><marker id="arrow" markerWidth="6" markerHeight="6" refX="5" refY="3" orient="auto"><path d="M0 0L6 3 0 6Z" fill="#5a5a66"/></marker></defs>` +
      data.edges.map((edge, index) => {
        const source = positions.get(edge.source), target = positions.get(edge.target);
        if (!source || !target) return "";
        const path = edgePath(source, target, index);
        return `<g class="edge ${esc(edge.status)} ${edge.confidence < 1 ? "inferred" : ""}" data-edge="${esc(edge.id)}" data-source="${esc(edge.source)}" data-target="${esc(edge.target)}"><path class="edge-base" marker-end="url(#arrow)" d="${path}"/><path class="edge-flow" d="${path}"/></g>`;
      }).join("");
  }

  function renderTabs() {
    const modes = ["current", "proposed", "compare"];
    if (data.stage === "implemented" || data.implementation) modes.push("implemented");
    $("#viewTabs").innerHTML = modes.map((item) => `<button data-mode="${item}">${label(item)}</button>`).join("");
    $$("#viewTabs button").forEach((button) => button.addEventListener("click", () => setMode(button.dataset.mode)));
  }

  function setMode(next) {
    mode = next;
    $$("#viewTabs button").forEach((button) => button.classList.toggle("active", button.dataset.mode === mode));
    data.nodes.forEach((node) => $(`[data-node="${CSS.escape(node.id)}"]`).classList.toggle("hidden", !visibleInMode(node, mode)));
    data.edges.forEach((edge) => {
      const source = data.nodes.find((node) => node.id === edge.source);
      const target = data.nodes.find((node) => node.id === edge.target);
      $(`[data-edge="${CSS.escape(edge.id)}"]`)?.classList.toggle("hidden", !visibleInMode(source, mode) || !visibleInMode(target, mode));
    });
    const selected = $(".node.selected");
    if (selected?.classList.contains("hidden")) clearSelection();
  }

  function selectNode(id) {
    const node = data.nodes.find((item) => item.id === id);
    if (!node) return;
    $$(".node").forEach((element) => element.classList.toggle("selected", element.dataset.node === id));
    $("#detailsPanel").classList.add("has-selection");
    activatePanel("details");
    const incoming = data.edges.filter((edge) => edge.target === id);
    const outgoing = data.edges.filter((edge) => edge.source === id);
    const relations = [
      ...incoming.map((edge) => ({direction:"IN", node:data.nodes.find((n) => n.id === edge.source), edge})),
      ...outgoing.map((edge) => ({direction:"OUT", node:data.nodes.find((n) => n.id === edge.target), edge})),
    ];
    $(".detail-content").innerHTML = `
      <span class="detail-type">${esc(label(node.kind))} · ${esc(label(node.status))}</span>
      <h2>${esc(node.label)}</h2>
      <p class="detail-summary">${esc(node.summary)}</p>
      <div class="properties">
        <div class="property"><span>Status</span><strong>${esc(label(node.status))}</strong></div>
        <div class="property"><span>Source</span><strong>${esc(sourceLabel(node))}</strong></div>
        <div class="property"><span>Confidence</span><strong>${Math.round(node.confidence * 100)}%</strong></div>
        <div class="property"><span>Boundary</span><strong>${esc(label(node.boundary || "none"))}</strong></div>
      </div>
      ${relations.length ? `<div class="section"><h3>Relationships</h3>${relations.map((item) => `<div class="relation"><b>${item.direction}</b><div><strong>${esc(item.node?.label || "Unknown")}</strong><small>${esc(label(item.edge.kind))}${item.edge.label ? ` · ${esc(item.edge.label)}` : ""}</small></div></div>`).join("")}</div>` : ""}
      ${node.inputs?.length ? `<div class="section"><h3>Inputs</h3><div class="chips">${node.inputs.map((item) => `<span class="chip">${esc(item)}</span>`).join("")}</div></div>` : ""}
      ${node.outputs?.length ? `<div class="section"><h3>Outputs</h3><div class="chips">${node.outputs.map((item) => `<span class="chip">${esc(item)}</span>`).join("")}</div></div>` : ""}
      ${node.sideEffects?.length ? `<div class="section"><h3>Side effects</h3><div class="chips">${node.sideEffects.map((item) => `<span class="chip">${esc(item)}</span>`).join("")}</div></div>` : ""}
      ${node.assumptions?.length ? `<div class="section"><h3>Assumptions</h3>${node.assumptions.map((item) => `<div class="bullet">△ ${esc(item)}</div>`).join("")}</div>` : ""}`;
  }

  function clearSelection() {
    $$(".node").forEach((node) => node.classList.remove("selected"));
    $("#detailsPanel").classList.remove("has-selection");
  }

  function renderImpact() {
    const impact = data.impact || {};
    const groups = [
      ["Risks", impact.risks],
      ["Assumptions", impact.assumptions],
      ["Open questions", impact.questions],
      ["Security", impact.security],
      ["Schema", impact.schema],
    ].filter(([,items]) => items?.length);
    $("#impactCount").textContent = (impact.files?.length || 0) + groups.reduce((sum,[,items]) => sum + items.length, 0);
    $("#impactPanel").innerHTML = `<div class="impact-wrap">
      <div class="impact-head"><span class="impact-score">${impact.risks?.length > 2 ? "High" : impact.risks?.length ? "Med" : "Low"}</span><div><strong>Scoped impact</strong><p>${impact.files?.length || 0} files and ${impact.symbols?.length || data.nodes.length} symbols</p></div></div>
      ${impact.files?.length ? `<div class="impact-list"><h3>Files affected</h3>${impact.files.map((file) => `<div class="impact-item"><i class="${esc(file.status)}"></i><span>${esc(file.path)}</span><em>${esc(label(file.status))}</em></div>`).join("")}</div>` : ""}
      ${impact.tests?.length ? `<div class="impact-list"><h3>Tests</h3>${impact.tests.map((test) => `<div class="impact-item"><i class="${esc(test.status)}"></i><span>${esc(test.path || test.name)}</span><em>${esc(label(test.status))}</em></div>`).join("")}</div>` : ""}
      ${groups.map(([name,items]) => `<div class="impact-list"><h3>${esc(name)}</h3>${items.map((item) => `<div class="bullet">${esc(item)}</div>`).join("")}</div>`).join("")}
      ${data.implementation ? `<div class="impact-list"><h3>Implementation</h3><div class="bullet">${esc(data.implementation.summary || "")}</div>${(data.implementation.verification || []).map((item) => `<div class="impact-item"><i class="${item.status === "passed" ? "added" : ""}"></i><span>${esc(item.name)}</span><em>${esc(label(item.status))}</em></div>`).join("")}</div>` : ""}
    </div>`;
  }

  function activatePanel(name) {
    $$(".aside-tabs button").forEach((button) => button.classList.toggle("active", button.dataset.panel === name));
    $$(".panel").forEach((panel) => panel.classList.toggle("active", panel.id === `${name}Panel`));
  }

  function focusNode(id) {
    const pos = positions.get(id);
    if (!pos) return;
    selectNode(id);
    zoom = 1;
    panX = 600 - (pos.x + 118);
    panY = 350 - (pos.y + 54);
    applyTransform();
  }

  function applyTransform(animated = true) {
    if (!animated) stage.style.transition = "none";
    stage.style.transform = `translate(calc(-50% + ${panX}px),calc(-50% + ${panY}px)) scale(${zoom})`;
    $("#zoomLabel").textContent = `${Math.round(zoom * 100)}%`;
    if (!animated) requestAnimationFrame(() => stage.style.transition = "");
  }

  function showToast(title, detail) {
    $(".toast strong").textContent = title;
    $(".toast small").textContent = detail;
    $("#toast").classList.add("visible");
    clearTimeout(showToast.timer);
    showToast.timer = setTimeout(() => $("#toast").classList.remove("visible"), 3600);
  }

  $$(".aside-tabs button").forEach((button) => button.addEventListener("click", () => activatePanel(button.dataset.panel)));
  $("#fit").addEventListener("click", () => { zoom = window.innerWidth <= 900 ? .48 : .78; panX = 0; panY = 0; applyTransform(); });
  $("#zoomIn").addEventListener("click", () => { zoom = Math.min(1.18, zoom + .1); applyTransform(); });
  $("#zoomOut").addEventListener("click", () => { zoom = Math.max(.55, zoom - .1); applyTransform(); });
  viewport.addEventListener("pointerdown", (event) => {
    if (event.target.closest(".node,button")) return;
    dragging = true; dragStart = {x:event.clientX-panX,y:event.clientY-panY};
    viewport.classList.add("dragging"); viewport.setPointerCapture(event.pointerId);
  });
  viewport.addEventListener("pointermove", (event) => {
    if (!dragging) return;
    panX = event.clientX-dragStart.x; panY = event.clientY-dragStart.y; applyTransform(false);
  });
  viewport.addEventListener("pointerup", () => { dragging = false; viewport.classList.remove("dragging"); });
  viewport.addEventListener("wheel", (event) => {
    if (!event.metaKey && !event.ctrlKey) return;
    event.preventDefault(); zoom = Math.max(.55,Math.min(1.18,zoom-event.deltaY*.001)); applyTransform();
  }, {passive:false});
  $("#approve").addEventListener("click", async () => {
    const message = `Approved. Implement the Change Map for: ${data.request?.title || "this change"}.`;
    try { await navigator.clipboard.writeText(message); showToast("Approval message copied", "Paste it into Codex to begin implementation."); }
    catch { showToast("Approve in Codex", message); }
  });
  $("#revise").addEventListener("click", () => showToast("Revise in Codex", "Describe the node or path you want changed."));
  $("#cancel").addEventListener("click", () => showToast("Change Map paused", "No approval has been given."));
  document.addEventListener("keydown", (event) => {
    if ((event.metaKey || event.ctrlKey) && event.key === "Enter") $("#approve").click();
  });

  setHeader(); renderTabs(); renderNodes(); renderEdges(); renderImpact(); setMode(mode); applyTransform(false);
})();
