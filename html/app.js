const RES = typeof GetParentResourceName === "function" ? GetParentResourceName() : "ra7-media";
const post = (name, data) =>
    fetch(`https://${RES}/${name}`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(data || {}) })
        .then((r) => r.json())
        .catch(() => ({}));

const $ = (s) => document.querySelector(s);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

const I18N = {
    ar: {
        kicker: "RA7 DEV", title: "لوحة الوسائط",
        overlay: "أماكن (فوق أي صورة)", help: "شرح",
        exportSql: "تصدير SQL", expTitle: "تصدير SQL", expHint: "انسخ هذا الكود وشغله في قاعدة بيانات السيرفر الثاني، بعدها: restart ra7-media", expFile: "انحفظ كملف في", copy: "نسخ", copied: "تم النسخ",
        new: "إضافة", quick: "تغطية سريعة بالأسود", empty: "لا يوجد عناصر بعد",
        edit: "تعديل", del: "حذف", goto: "انتقل", on: "مفعّل",
        label: "الاسم", mode: "المحتوى", url: "رابط الصورة / الفيديو", urlHint: "https://...",
        black: "أسود", white: "أبيض / فاضي", clear: "شفاف", image: "صورة", video: "فيديو",
        loop: "تكرار", muted: "بدون صوت", volume: "الصوت", fit: "الملاءمة",
        fill: "تمديد", cover: "تغطية", contain: "احتواء",
        pick: "تحديد المكان من الشاشة", picked: "تم تحديد المكان", nopos: "لم يتم تحديد مكان بعد",
        width: "العرض", height: "الطول", roll: "الدوران", offset: "البعد", dist: "مسافة العرض",
        txd: "اسم الـ txd", txn: "اسم النسيج", preset: "قوالب جاهزة", resW: "دقة العرض", resH: "دقة الطول",
        audioPos: "موقع الصوت (اختياري)", useMe: "استخدم موقعي", clearPos: "إزالة",
        save: "حفظ", cancel: "إلغاء", needPos: "حدد المكان أولاً", needTex: "اكتب txd واسم النسيج", needUrl: "اكتب الرابط",
        blackout: "تغطية",
        hide: "إزالة أوبجكت", removeObj: "إزالة أوبجكت (شيل المجلات / الأغراض)", pickObj: "حدد الأوبجكت", noObj: "لم يتم تحديد أوبجكت",
        objInfo: "الموديل", radius: "نصف القطر (متر)", everywhere: "كل نسخ هذا الأوبجكت في الخريطة كلها", needObj: "حدد الأوبجكت أولاً",
        nudge: "تحريك بدقة", step: "الخطوة",
        hintObj: "وجّه الكاميرا على الأوبجكت (يتلون بالأحمر) • <kbd>E</kbd> تأكيد • <kbd>Backspace</kbd> إلغاء",
        h6: "<b>إزالة أوبجكت:</b> وجّه على الشي (مجلة، رف، لوحة مجسمة) واضغط <kbd>E</kbd> يختفي. نصف القطر يحدد كم نسخة من نفس الموديل تنشال حوالين المكان، و«كل النسخ» يشيله من كل الخريطة. احذف العنصر من القائمة عشان يرجع.",
        scan: "فحص المنطقة (كل الأوبجكتات حولك)", scanR: "المسافة", rescan: "فحص", locate: "أرني", removeHere: "شيل هنا", removeAll: "شيل من كل الخريطة",
        flatOnly: "المسطحات فقط (بوسترات / مجلات / صور)", removeFlat: "شيل كل المسطحات هنا", flatTag: "مسطح",
        scanEmpty: "ما لقيت أوبجكتات، قرّب أو كبّر المسافة", scanHint: "قف داخل المكان (بقالة / مرقص) وافحص، بعدها شيل أي موديل مخل. «أرني» يلون كل نسخه بالأحمر 5 ثواني.", count: "عدد",
        remote: "تحكم بالفيديو", rmTitle: "ريموت الفيديو", playPause: "تشغيل / إيقاف", restart: "من البداية", rmSpeed: "السرعة", rmVolume: "الصوت", rmMute: "كتم / تشغيل الصوت",
        rmSeek: "تقديم / تأخير", rmState: "الحالة", rmPlaying: "يشتغل", rmPaused: "موقف", rmMuted: "مكتوم", rmNoCtl: "هذا الفيديو يتحكم فيه الأدمن فقط (Config.VideoControl).",
        rmHint: "تقدر تتحكم فيه من اللعبة بالـ target: قف قدام الفيديو (أقل من 4 متر) وكليك على الشاشة.",
        scale: "الحجم %", pickPoint: "ضع المربع في المكان (العجلة: تكبير / تصغير)",
        texInfo: "النقوش: تستبدل صورة معينة (باسمها) في كل مكان تظهر فيه في الخريطة كلها، مو مكان واحد. تحتاج اسم الـ txd واسم النسيج من OpenIV أو CodeWalker. لو تبي تغطي مكان واحد استخدم تبويب «أماكن».",
        hintAim: "وجّه الكاميرا للمكان ثم اضغط <kbd>E</kbd> لتثبيت الصورة • <kbd>Backspace</kbd> إلغاء",
        hintDrag: "اسحب بالماوس من زاوية لزاوية • كليك يمين / <kbd>Esc</kbd> رجوع",
        hintPick: "وجّه الكاميرا للمكان • <kbd>E</kbd> / <kbd>Enter</kbd> تأكيد • <kbd>Backspace</kbd> إلغاء<br>العجلة: تكبير/تصغير • <kbd>Shift</kbd>+العجلة عرض فقط • <kbd>Ctrl</kbd>+العجلة طول فقط • <kbd>←</kbd><kbd>→</kbd> تدوير",
        h1: "<b>أماكن:</b> تحدد أي مكان في اللعبة (لوحة، ملصق، جدار) وتغطيه بصورة أو فيديو أو أسود. يشتغل على أي شي مهما كان اسمه.",
        h2: "<b>تغطية سريعة بالأسود:</b> اضغطها، وجّه الكاميرا على الصورة المخلة، اضغط <kbd>E</kbd>. تتغطى فوراً ويشوفها كل اللاعبين.",
        h3: "<b>نقوش:</b> استبدال نسيج معروف (txd + اسم النسيج) في كل مكان يظهر فيه. تحتاج الأسماء من OpenIV أو CodeWalker.",
        h4: "<b>رابطك:</b> استخدم رابط مباشر للصورة، أو للفيديو: mp4 / webm أو رابط YouTube أو Vimeo.",
        h5: "الفيديو والصورة تظهر فقط ضمن مسافة العرض، وفيه حد أقصى للعناصر المتحركة بنفس الوقت من الإعدادات.",
    },
    en: {
        kicker: "RA7 DEV", title: "Media control",
        overlay: "Spots (over any picture)", help: "Help",
        exportSql: "Export SQL", expTitle: "SQL export", expHint: "Copy this and run it on the other server database, then: restart ra7-media", expFile: "Also saved as a file in", copy: "Copy", copied: "Copied",
        new: "Add", quick: "Quick black-out", empty: "Nothing here yet",
        edit: "Edit", del: "Delete", goto: "Go", on: "Enabled",
        label: "Name", mode: "Content", url: "Image / video link", urlHint: "https://...",
        black: "Black", white: "White / blank", clear: "Transparent", image: "Image", video: "Video",
        loop: "Loop", muted: "Muted", volume: "Volume", fit: "Fit",
        fill: "Stretch", cover: "Cover", contain: "Contain",
        pick: "Pick spot on screen", picked: "Spot picked", nopos: "No spot picked yet",
        width: "Width", height: "Height", roll: "Rotate", offset: "Offset", dist: "Draw dist.",
        txd: "txd name", txn: "Texture name", preset: "Presets", resW: "Res width", resH: "Res height",
        audioPos: "Audio position (optional)", useMe: "Use my position", clearPos: "Clear",
        save: "Save", cancel: "Cancel", needPos: "Pick a spot first", needTex: "Enter txd and texture name", needUrl: "Enter a link",
        blackout: "Blackout",
        hide: "Remove object", removeObj: "Remove object (magazines / props)", pickObj: "Pick the object", noObj: "No object picked yet",
        objInfo: "Model", radius: "Radius (m)", everywhere: "Every copy of this object on the whole map", needObj: "Pick the object first",
        nudge: "Fine nudge", step: "Step",
        hintObj: "Aim at the object (it turns red) • <kbd>E</kbd> confirm • <kbd>Backspace</kbd> cancel",
        h6: "<b>Remove object:</b> aim at the thing (magazine, rack, solid sign) and press <kbd>E</kbd> to make it disappear. Radius sets how many copies of that model around the spot go; 'every copy' removes it map-wide. Delete the entry to bring it back.",
        scan: "Scan area (every object around you)", scanR: "Range", rescan: "Scan", locate: "Show", removeHere: "Remove here", removeAll: "Remove map-wide",
        flatOnly: "Flat only (posters / magazines / pictures)", removeFlat: "Remove all flat ones here", flatTag: "flat",
        scanEmpty: "No objects found, move closer or raise the range", scanHint: "Stand inside the place (store / club) and scan, then remove any bad model. 'Show' outlines every copy in red for 5 s.", count: "Count",
        remote: "Video control", rmTitle: "Video remote", playPause: "Play / Pause", restart: "Restart", rmSpeed: "Speed", rmVolume: "Volume", rmMute: "Mute / Unmute",
        rmSeek: "Seek", rmState: "State", rmPlaying: "Playing", rmPaused: "Paused", rmMuted: "Muted", rmNoCtl: "Only admins control this video (Config.VideoControl).",
        rmHint: "You can also control it in game with the target: stand in front of the video (under 4 m) and aim at the screen.",
        scale: "Size %", pickPoint: "Place the square (wheel: bigger / smaller)",
        texInfo: "Textures: replaces one specific picture (by name) everywhere it appears on the whole map, not one spot. You need the txd and texture name from OpenIV or CodeWalker. To cover one single spot use the Spots tab.",
        hintAim: "Aim at the spot then press <kbd>E</kbd> to freeze the view • <kbd>Backspace</kbd> cancel",
        hintDrag: "Drag with the mouse from corner to corner • right-click / <kbd>Esc</kbd> back",
        hintPick: "Aim at the spot • <kbd>E</kbd> / <kbd>Enter</kbd> confirm • <kbd>Backspace</kbd> cancel<br>Wheel: scale • <kbd>Shift</kbd>+wheel width • <kbd>Ctrl</kbd>+wheel height • <kbd>←</kbd><kbd>→</kbd> rotate",
        h1: "<b>Spots:</b> point at anything in the world (billboard, poster, wall) and cover it with an image, video or black. Works on anything, whatever its name.",
        h2: "<b>Quick black-out:</b> press it, aim at the bad picture, press <kbd>E</kbd>. A black square appears; resize it with the Size slider and Save.",
        h3: "<b>Textures:</b> replace a known texture (txd + texture name) everywhere it shows. Get names from OpenIV or CodeWalker.",
        h4: "<b>Your link:</b> use a direct image link; for video: mp4 / webm, or a YouTube / Vimeo link.",
        h5: "Images and videos only render inside the draw distance, and the number of live ones is capped in config.",
    },
};

let lang = "ar";
let items = [];
let exportData = null;
let cfg = { maxDist: 250, defDist: 60, off: 0.015 };
let tab = "overlay";
let draft = null;
let quick = false;
let error = "";
let nudgeStep = 0.05;
let scanOpen = false;
let scanR = 15;
let scanRows = [];
let flatOnly = true;
let remoteId = null;
let remoteOnly = false;
let vstates = {};
let volTimer = null;

function runScan() {
    post("scan", { r: scanR }).then((rows) => { scanRows = Array.isArray(rows) ? rows : []; render(); });
}

function renderScan() {
    let h = `<div class="row wrap"><button class="tc-btn ghost btn" data-act="scanback"><i class="fa-solid fa-arrow-right"></i>${t("cancel")}</button>
        <span class="tc-sub">${t("scanR")}</span>
        <select class="tc-input" data-scanr="1" style="width:10rem">${[5, 10, 15, 25, 40, 70].map((v) => `<option value="${v}" ${v === scanR ? "selected" : ""}>${v}m</option>`).join("")}</select>
        <button class="tc-btn primary btn" data-act="rescan"><i class="fa-solid fa-magnifying-glass"></i>${t("rescan")}</button></div>
        <div class="tg"><span class="tc-sub">${t("flatOnly")}</span><div class="tc-toggle ${flatOnly ? "on" : ""}" data-act="flattog"></div></div>
        <div class="row"><button class="tc-btn danger btn grow" data-act="rmflat"><i class="fa-solid fa-eraser"></i>${t("removeFlat")}</button></div>
        <div class="note">${t("scanHint")}</div>`;
    const shown = scanRows.map((r, i) => [r, i]).filter(([r]) => !flatOnly || r.flat);
    if (!shown.length) h += `<div class="empty">${t("scanEmpty")}</div>`;
    shown.forEach(([r, i]) => {
        h += `<div class="item tc-card" data-i="${i}">
            <div class="tc-tile"><i class="fa-solid fa-cube"></i></div>
            <div class="meta"><div class="tc-name">${esc(r.name || r.model)}</div><div class="tc-sub">${r.flat ? `<b>${t("flatTag")}</b> · ` : ""}${t("objInfo")} ${r.model} · ${t("count")} ${r.count} · ${r.dist}m · ${esc(r.size || "")}</div></div>
            <div class="acts">
                <button class="ibtn" data-act="locate" title="${t("locate")}"><i class="fa-solid fa-eye"></i></button>
                <button class="ibtn bad" data-act="hhere" title="${t("removeHere")}"><i class="fa-solid fa-eraser"></i></button>
                <button class="ibtn bad" data-act="hall" title="${t("removeAll")}"><i class="fa-solid fa-earth-asia"></i></button>
            </div></div>`;
    });
    $("#view").innerHTML = h;
}

function scanRemove(row, radius) {
    const here = radius < 5000;
    post("save", {
        kind: "hide",
        data: {
            label: `${t("hide")} ${row.name || row.model}`, enabled: true, mode: "hide", model: row.model,
            x: here ? row.hx : row.x, y: here ? row.hy : row.y, z: here ? row.hz : row.z, radius,
        },
    });
}

function nudge(dx, dy) {
    const d = draft;
    if (d.x === undefined) return;
    const n = [d.nx, d.ny, d.nz];
    const cross = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
    const norm = (a) => { const l = Math.hypot(...a) || 1; return a.map((v) => v / l); };
    const up = Math.abs(n[2]) > 0.95 ? [0, 1, 0] : [0, 0, 1];
    const r = norm(cross(up, n));
    const u = cross(n, r);
    const a = ((d.roll || 0) * Math.PI) / 180;
    const ca = Math.cos(a), sa = Math.sin(a);
    const r2 = r.map((v, i) => v * ca + u[i] * sa);
    const u2 = u.map((v, i) => v * ca - r[i] * sa);
    d.x += (r2[0] * dx + u2[0] * dy) * nudgeStep;
    d.y += (r2[1] * dx + u2[1] * dy) * nudgeStep;
    d.z += (r2[2] * dx + u2[2] * dy) * nudgeStep;
    sendPreview();
}

const t = (k) => (I18N[lang] && I18N[lang][k]) ?? I18N.en[k] ?? k;
const MODE_ICON = { black: "fa-solid fa-square", white: "fa-regular fa-square", clear: "fa-regular fa-eye-slash", image: "fa-solid fa-image", video: "fa-solid fa-film" };

/* ------------------------------------------------------------ shell */
function applyLang() {
    document.documentElement.lang = lang;
    document.documentElement.dir = lang === "ar" ? "rtl" : "ltr";
    $("#kicker").textContent = t("kicker");
    $("#title").textContent = t("title");
}

function renderTabs() {
    const el = $("#tabs");
    if (draft || scanOpen || remoteId || exportData) { el.innerHTML = ""; return; }
    el.innerHTML = ["overlay", "hide", "help"]
        .map((k) => `<button class="tc-pill ${tab === k ? "on" : ""}" data-tab="${k}">${t(k)}</button>`)
        .join("");
}

function renderExport() {
    $("#view").innerHTML = `<div class="row wrap"><button class="tc-btn ghost btn" data-x="back"><i class="fa-solid fa-arrow-right"></i>${t("cancel")}</button>
        <button class="tc-btn primary btn" data-x="copy"><i class="fa-solid fa-copy"></i><span id="cpLabel">${t("copy")}</span></button></div>
        <div class="note">${t("expHint")}</div>
        <textarea id="sqlBox" class="sqlbox" readonly spellcheck="false"></textarea>`;
    $("#sqlBox").value = exportData.sql;
}

function renderRemote() {
    const it = items.find((i) => i.id === remoteId);
    if (!it) { remoteId = null; return render(); }
    const st = vstates[remoteId] || { playing: true, speed: 1, vol: -1, muted: false };
    const vol = st.vol >= 0 ? st.vol : it.volume ?? 50;
    const speeds = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 2, 3, 4];
    const secs = [-30, -10, 10, 30];
    $("#view").innerHTML = `<div class="row wrap"><button class="tc-btn ghost btn" data-v="back"><i class="fa-solid fa-arrow-right"></i>${t("cancel")}</button>
        <span class="tc-name">${esc(it.label)}</span></div>
        <div class="tc-card box">
            <div class="tc-sub">${t("rmState")}: <b>${st.playing ? t("rmPlaying") : t("rmPaused")}</b> · ${t("rmSpeed")} ${Number(st.speed).toFixed(2)}x · ${t("rmVolume")} ${Math.round(vol)}%${st.muted ? " · " + t("rmMuted") : ""}</div>
            <div class="row wrap">
                <button class="tc-btn primary btn grow" data-v="toggle"><i class="fa-solid ${st.playing ? "fa-pause" : "fa-play"}"></i>${t("playPause")}</button>
                <button class="tc-btn ghost btn" data-v="restart"><i class="fa-solid fa-rotate-left"></i>${t("restart")}</button>
            </div>
            <div class="fld"><span class="tc-flabel">${t("rmSeek")}</span><div class="seg">${secs.map((s) => `<button class="tc-pill" data-v="seek" data-n="${s}">${s > 0 ? "+" : ""}${s}s</button>`).join("")}</div></div>
            <div class="fld"><span class="tc-flabel">${t("rmSpeed")}</span><div class="seg">${speeds.map((s) => `<button class="tc-pill ${Math.abs(st.speed - s) < 0.01 ? "on" : ""}" data-v="speed" data-n="${s}">${s}x</button>`).join("")}</div></div>
            <div class="sl"><span class="tc-sub">${t("rmVolume")}</span>
                <input type="range" class="tc-range" data-volr="1" min="0" max="100" step="1" value="${Math.round(vol)}" style="--p:${vol}%">
                <button class="tc-btn ghost btn sm" data-v="mute"><i class="fa-solid ${st.muted ? "fa-volume-xmark" : "fa-volume-high"}"></i>${t("rmMute")}</button></div>
        </div>
        <div class="note">${t("rmHint")}</div>`;
}

function render() {
    applyLang();
    renderTabs();
    if (exportData) renderExport();
    else if (remoteId) renderRemote();
    else if (scanOpen && !draft) renderScan();
    else if (draft) renderEditor();
    else if (tab === "help") renderHelp();
    else renderList();
}

/* ------------------------------------------------------------ list */
function itemSub(it) {
    const bits = [t(it.mode)];
    if (it.kind === "hide") return `${t("objInfo")} ${it.model} · ${it.radius >= 5000 ? "∞" : it.radius + "m"}`;
    bits.push(`${it.w}×${it.h}m`);
    if (it.url) bits.push(it.url);
    return bits.join(" · ");
}

function renderList() {
    const rows = items.filter((i) => i.kind === tab).sort((a, b) => a.id - b.id);
    let html = `<div class="row wrap">
        <button class="tc-btn primary btn" data-act="new"><i class="fa-solid fa-plus"></i>${t("new")}</button>
        ${tab === "hide" ? `<button class="tc-btn ghost btn" data-act="scan"><i class="fa-solid fa-magnifying-glass"></i>${t("scan")}</button>` : ""}
        ${tab === "hide" ? `<button class="tc-btn ghost btn" data-act="quickhide"><i class="fa-solid fa-eraser"></i>${t("removeObj")}</button>` : ""}
        <button class="tc-btn ghost btn" data-act="exportsql"><i class="fa-solid fa-file-export"></i>${t("exportSql")}</button>
        ${tab === "overlay" ? `<button class="tc-btn ghost btn" data-act="quick"><i class="fa-solid fa-square"></i>${t("quick")}</button>` : ""}
    </div>`;
    if (!rows.length) html += `<div class="empty">${t("empty")}</div>`;
    for (const it of rows) {
        const canGo = it.kind === "overlay" || it.x !== undefined;
        html += `<div class="item tc-card ${it.enabled ? "" : "off"}" data-id="${it.id}">
            <div class="tc-tile"><i class="${it.kind === "hide" ? "fa-solid fa-eraser" : MODE_ICON[it.mode] || "fa-solid fa-image"}"></i></div>
            <div class="meta"><div class="tc-name">${esc(it.label)}</div><div class="tc-sub">${esc(itemSub(it))}</div></div>
            <div class="acts">
                <div class="tc-toggle ${it.enabled ? "on" : ""}" data-act="toggle" title="${t("on")}"></div>
                ${it.mode === "video" ? `<button class="ibtn" data-act="remote" title="${t("remote")}"><i class="fa-solid fa-sliders"></i></button>` : ""}
                ${canGo ? `<button class="ibtn" data-act="goto" title="${t("goto")}"><i class="fa-solid fa-location-dot"></i></button>` : ""}
                <button class="ibtn" data-act="edit" title="${t("edit")}"><i class="fa-solid fa-pen"></i></button>
                <button class="ibtn bad" data-act="del" title="${t("del")}"><i class="fa-solid fa-trash"></i></button>
            </div>
        </div>`;
    }
    $("#view").innerHTML = html;
}

function renderHelp() {
    $("#view").innerHTML = `<div class="help tc-card box">${["h1", "h2", "h4", "h6", "h5"].map((k) => `<p>${t(k)}</p>`).join("")}</div>`;
}

/* ------------------------------------------------------------ editor */
function newDraft(kind) {
    if (kind === "hide") return { kind, label: "", enabled: true, mode: "hide", radius: 1, everywhere: false };
    return {
        kind, label: "", enabled: true, mode: "black", url: "", loop: true, muted: false, volume: 50, fit: "fill",
        w: 2, h: 1.2, roll: 0, off: cfg.off, dist: cfg.defDist,
    };
}

function slider(k, label, min, max, step) {
    const v = draft[k] ?? 0;
    const p = ((v - min) / (max - min)) * 100;
    return `<div class="sl"><span class="tc-sub">${label}</span>
        <input type="range" class="tc-range" data-k="${k}" data-num="1" min="${min}" max="${max}" step="${step}" value="${v}" style="--p:${p}%">
        <input type="number" class="tc-input" data-k="${k}" data-num="1" min="${min}" max="${max}" step="${step}" value="${v}"></div>`;
}

function scaleRow() {
    const s = draft._s ?? 100;
    return `<div class="sl"><span class="tc-sub">${t("scale")}</span>
        <input type="range" class="tc-range" data-scale="1" min="10" max="500" step="1" value="${s}" style="--p:${((s - 10) / 490) * 100}%">
        <input type="number" class="tc-input" data-scale="1" min="10" max="500" step="1" value="${s}"></div>`;
}

function toggle(k, label) {
    return `<div class="tg"><span class="tc-sub">${label}</span><div class="tc-toggle ${draft[k] ? "on" : ""}" data-tg="${k}"></div></div>`;
}

function renderHideEditor() {
    const d = draft;
    const has = d.model !== undefined;
    $("#view").innerHTML = `<div class="form">
        <div class="fld"><span class="tc-flabel">${t("label")}</span><input class="tc-input" data-k="label" value="${esc(d.label)}" maxlength="60"></div>
        <div class="tc-card box">
            <div class="row wrap"><button class="tc-btn primary btn grow" data-act="pickobj"><i class="fa-solid fa-crosshairs"></i>${t("pickObj")}</button></div>
            <div class="pos">${has ? `${t("objInfo")}: ${d.model} @ ${d.x.toFixed(1)}, ${d.y.toFixed(1)}, ${d.z.toFixed(1)}` : t("noObj")}</div>
            ${toggle("everywhere", t("everywhere"))}
            ${d.everywhere ? "" : slider("radius", t("radius"), 0.2, 100, 0.1)}
        </div>
        ${error ? `<div class="err">${esc(error)}</div>` : ""}
        <div class="row"><button class="tc-btn primary btn grow" data-act="save"><i class="fa-solid fa-check"></i>${t("save")}</button>
        <button class="tc-btn ghost btn" data-act="cancel">${t("cancel")}</button></div></div>`;
}

function renderEditor() {
    if (draft.kind === "hide") return renderHideEditor();
    const d = draft;
    const media = d.mode === "image" || d.mode === "video";
    const modes = ["black", "white", "image", "video"];
    let h = `<div class="form">
        <div class="fld"><span class="tc-flabel">${t("label")}</span><input class="tc-input" data-k="label" value="${esc(d.label)}" maxlength="60"></div>
        <div class="fld"><span class="tc-flabel">${t("mode")}</span>
            <div class="seg">${modes.map((m) => `<button class="tc-pill ${d.mode === m ? "on" : ""}" data-mode="${m}">${t(m)}</button>`).join("")}</div></div>`;

    if (media) {
        h += `<div class="fld"><span class="tc-flabel">${t("url")}</span><input class="tc-input" data-k="url" dir="ltr" placeholder="${esc(t("urlHint"))}" value="${esc(d.url)}"></div>
            <div class="fld"><span class="tc-flabel">${t("fit")}</span>
                <div class="seg">${["fill", "cover", "contain"].map((m) => `<button class="tc-pill ${d.fit === m ? "on" : ""}" data-fit="${m}">${t(m)}</button>`).join("")}</div></div>`;
        if (d.mode === "video") {
            h += `<div class="tc-card box">${toggle("loop", t("loop"))}${toggle("muted", t("muted"))}${slider("volume", t("volume"), 0, 100, 1)}</div>`;
        }
    }

    if (d.kind === "overlay") {
        const has = d.x !== undefined;
        h += `<div class="tc-card box">
            <div class="row wrap"><button class="tc-btn primary btn grow" data-act="pick"><i class="fa-solid fa-crosshairs"></i>${t("pickPoint")}</button></div>
            <div class="pos">${has ? `${t("picked")}: ${d.x.toFixed(1)}, ${d.y.toFixed(1)}, ${d.z.toFixed(1)}` : t("nopos")}</div>
            ${scaleRow()}
            ${slider("w", t("width"), 0.1, 40, 0.05)}${slider("h", t("height"), 0.1, 40, 0.05)}
            ${slider("roll", t("roll"), -180, 180, 0.5)}${slider("off", t("offset"), 0, 0.3, 0.005)}
            ${slider("dist", t("dist"), 10, cfg.maxDist, 1)}
            <div class="row wrap"><span class="tc-sub">${t("nudge")}</span>
                <button class="ibtn" data-nudge="-1,0"><i class="fa-solid fa-arrow-left"></i></button>
                <button class="ibtn" data-nudge="1,0"><i class="fa-solid fa-arrow-right"></i></button>
                <button class="ibtn" data-nudge="0,1"><i class="fa-solid fa-arrow-up"></i></button>
                <button class="ibtn" data-nudge="0,-1"><i class="fa-solid fa-arrow-down"></i></button>
                <span class="tc-sub">${t("step")}</span>
                <select class="tc-input" data-step="1" style="width:9rem">${[0.01, 0.05, 0.25, 1].map((v) => `<option value="${v}" ${v === nudgeStep ? "selected" : ""}>${v}m</option>`).join("")}</select></div></div>`;
    }

    h += `${error ? `<div class="err">${esc(error)}</div>` : ""}
        <div class="row"><button class="tc-btn primary btn grow" data-act="save"><i class="fa-solid fa-check"></i>${t("save")}</button>
        <button class="tc-btn ghost btn" data-act="cancel">${t("cancel")}</button></div></div>`;
    $("#view").innerHTML = h;
}

function sendPreview() {
    if (draft && draft.kind === "overlay" && draft.x !== undefined) {
        post("preview", { x: draft.x, y: draft.y, z: draft.z, nx: draft.nx, ny: draft.ny, nz: draft.nz, w: draft.w, h: draft.h, roll: draft.roll, off: draft.off });
    } else {
        post("preview", null);
    }
}

function closeEditor() {
    draft = null;
    quick = false;
    error = "";
    post("preview", null);
    render();
}

function save() {
    const d = draft;
    error = "";
    if (d.kind === "hide" && d.model === undefined) error = t("needObj");
    else if (d.kind === "overlay" && d.x === undefined) error = t("needPos");
    else if ((d.mode === "image" || d.mode === "video") && !d.url.trim()) error = t("needUrl");
    if (error) return renderEditor();
    const data = { ...d };
    if (d.kind === "hide") { data.radius = d.everywhere ? 99999 : d.radius; delete data.everywhere; }
    delete data.id;
    delete data.kind;
    delete data._bw; delete data._bh; delete data._s;
    post("save", { kind: d.kind, id: d.id, data });
    closeEditor();
}

/* ------------------------------------------------------------ events */
$("#view").addEventListener("input", (e) => {
    const el = e.target;
    const k = el.dataset.k;
    if (el.dataset.volr !== undefined) {
        const v = Number(el.value);
        el.style.setProperty("--p", v + "%");
        clearTimeout(volTimer);
        volTimer = setTimeout(() => post("vctl", { id: remoteId, action: "vol", value: v }), 150);
        return;
    }
    if (el.dataset.scanr !== undefined) { scanR = parseInt(el.value, 10) || 15; return; }
    if (!draft) return;
    if (el.dataset.scale !== undefined) {
        const sv = parseFloat(el.value);
        if (Number.isNaN(sv) || !draft._bw) return;
        draft._s = sv;
        draft.w = Math.round(draft._bw * sv) / 100;
        draft.h = Math.round(draft._bh * sv) / 100;
        document.querySelectorAll("[data-scale]").forEach((o) => {
            if (o !== el) o.value = sv;
            if (o.type === "range") o.style.setProperty("--p", ((sv - 10) / 490) * 100 + "%");
        });
        ["w", "h"].forEach((kk) => document.querySelectorAll(`[data-k="${kk}"][data-num]`).forEach((o) => {
            o.value = draft[kk];
            if (o.type === "range") o.style.setProperty("--p", ((draft[kk] - o.min) / (o.max - o.min)) * 100 + "%");
        }));
        sendPreview();
        return;
    }
    if (el.dataset.step !== undefined) { nudgeStep = parseFloat(el.value) || 0.05; return; }
    if (!k) return;
    if (el.dataset.num) {
        const v = parseFloat(el.value);
        if (Number.isNaN(v)) return;
        draft[k] = v;
        if (k === "w" || k === "h") { draft._bw = draft.w; draft._bh = draft.h; draft._s = 100; }
        document.querySelectorAll(`[data-k="${k}"][data-num]`).forEach((o) => {
            if (o !== el) o.value = v;
            if (o.type === "range") o.style.setProperty("--p", ((v - o.min) / (o.max - o.min)) * 100 + "%");
        });
        sendPreview();
    } else {
        draft[k] = el.value;
    }
});

$("#view").addEventListener("click", (e) => {
    if (exportData) {
        const b = e.target.closest("[data-x]");
        if (!b) return;
        if (b.dataset.x === "back") { exportData = null; return render(); }
        const box = $("#sqlBox");
        box.removeAttribute("readonly");
        box.focus(); box.select();
        let ok = false;
        try { ok = document.execCommand("copy"); } catch (_) {}
        box.setAttribute("readonly", "");
        const lab = $("#cpLabel");
        if (lab && ok) lab.textContent = t("copied");
        return;
    }
    if (remoteId) {
        const b = e.target.closest("[data-v]");
        if (!b) return;
        const a = b.dataset.v;
        if (a === "back") {
            if (remoteOnly) return post("close");
            remoteId = null; return render();
        }
        const n = b.dataset.n !== undefined ? Number(b.dataset.n) : undefined;
        post("vctl", { id: remoteId, action: a, value: n });
        return;
    }
    if (scanOpen && !draft) {
        const b = e.target.closest("[data-act]");
        if (!b) return;
        const row = scanRows[parseInt((b.closest("[data-i]") || {}).dataset?.i, 10)];
        switch (b.dataset.act) {
            case "scanback": scanOpen = false; return render();
            case "rescan": return runScan();
            case "locate": if (row) post("locate", { model: row.model }); return;
            case "hhere": if (row) scanRemove(row, scanR + 1); return;
            case "flattog": flatOnly = !flatOnly; return renderScan();
            case "rmflat": scanRows.filter((r) => r.flat).forEach((r) => scanRemove(r, scanR + 1)); return;
            case "hall": if (row) scanRemove(row, 99999); return;
        }
        return;
    }
    const target = e.target.closest("[data-act],[data-mode],[data-fit],[data-tg],[data-nudge]");
    if (!target) return;
    const card = target.closest("[data-id]");
    const id = card ? parseInt(card.dataset.id, 10) : null;

    if (target.dataset.nudge) { const [dx, dy] = target.dataset.nudge.split(",").map(Number); return nudge(dx, dy); }
    if (target.dataset.mode) { draft.mode = target.dataset.mode; return renderEditor(); }
    if (target.dataset.fit) { draft.fit = target.dataset.fit; return renderEditor(); }
    if (target.dataset.tg) { draft[target.dataset.tg] = !draft[target.dataset.tg]; return renderEditor(); }

    switch (target.dataset.act) {
        case "new": draft = newDraft(tab); return render();
        case "scan": scanOpen = true; scanRows = []; render(); return runScan();
        case "quick":
            quick = true;
            return post("pick", { w: 2, h: 2, roll: 0, off: cfg.off });
        case "pickobj":
            return post("pick", { mode: "object" });
        case "quickhide":
            quick = true;
            return post("pick", { mode: "object" });
        case "edit": {
            const it = items.find((i) => i.id === id);
            if (it) {
                draft = JSON.parse(JSON.stringify(it));
                if (draft.kind === "hide") { draft.everywhere = draft.radius >= 5000; if (draft.everywhere) draft.radius = 1; }
                render(); sendPreview();
            }
            return;
        }
        case "toggle": {
            const it = items.find((i) => i.id === id);
            if (it) post("toggle", { id, state: !it.enabled });
            return;
        }
        case "goto": return post("goto", { id });
        case "exportsql": return post("export");
        case "remote": remoteId = id; render(); return;
        case "del":
            if (target.classList.contains("armed")) return post("delete", { id });
            target.classList.add("armed");
            setTimeout(() => target.classList.remove("armed"), 3000);
            return;
        case "pick":
            return post("pick", { w: draft.w, h: draft.h, roll: draft.roll, off: draft.off });
        case "save": return save();
        case "cancel": return closeEditor();
    }
});

$("#tabs").addEventListener("click", (e) => {
    const b = e.target.closest("[data-tab]");
    if (b) { tab = b.dataset.tab; render(); }
});

$("#btnClose").addEventListener("click", () => post("close"));
document.addEventListener("keydown", (e) => {
    if (e.key !== "Escape" || $("#panel").classList.contains("hidden")) return;
    if (exportData) { exportData = null; render(); }
    else if (remoteId) {
        if (remoteOnly) post("close");
        else { remoteId = null; render(); }
    } else if (draft) closeEditor();
    else if (scanOpen) { scanOpen = false; render(); }
    else post("close");
});

window.addEventListener("message", (e) => {
    const d = e.data || {};
    if (d.action === "open") {
        items = d.items || [];
        cfg = Object.assign(cfg, d.cfg || {});
        if (d.lang) lang = d.lang;
        draft = null; quick = false; error = ""; scanOpen = false; remoteId = null; remoteOnly = false; exportData = null;
        vstates = d.vs || {};
        $("#panel").classList.remove("hidden");
        render();
    } else if (d.action === "export") {
        exportData = { sql: d.sql || "", file: d.file || null };
        render();
    } else if (d.action === "remote") {
        items = [d.item];
        if (d.lang) lang = d.lang;
        vstates = d.vs || {};
        draft = null; quick = false; error = ""; scanOpen = false;
        remoteId = d.id; remoteOnly = true;
        $("#panel").classList.remove("hidden");
        render();
    } else if (d.action === "close") {
        $("#panel").classList.add("hidden");
        draft = null; remoteId = null; remoteOnly = false;
    } else if (d.action === "items") {
        items = d.items || [];
        if (!draft && !scanOpen && !remoteId && !exportData) render();
        else if (remoteId && remoteOnly) { const m = items.find((i) => i.id === remoteId); if (!m) post("close"); }
    } else if (d.action === "vstate") {
        vstates[d.id] = Object.assign({}, d.st, { pos: d.pos });
        if (remoteId === d.id) renderRemote();
    } else if (d.action === "pick") {
        const on = !!d.on;
        $("#panel").classList.toggle("hidden", on);
        const hint = $("#hint");
        hint.innerHTML = t(d.mode === "aim" ? "hintAim" : d.mode === "drag" ? "hintDrag" : d.mode === "object" ? "hintObj" : "hintPick");
        hint.classList.toggle("hidden", !on);
    } else if (d.action === "pickedObj") {
        const p = d.data;
        const wasQuick = quick;
        quick = false;
        if (!p) { if (draft) renderEditor(); return; }
        if (!draft) draft = newDraft("hide");
        Object.assign(draft, p);
        if (!draft.label) draft.label = `${t("hide")} ${p.name || p.model}`;
        if (wasQuick) { save(); return; }
        renderEditor();

    } else if (d.action === "picked") {
        const p = d.data;
        if (p && quick) {
            quick = false;
            const nd = newDraft("overlay");
            Object.assign(nd, p, { label: `${t("blackout")} ${items.filter((i) => i.kind === "overlay").length + 1}` });
            draft = nd;
            draft._bw = p.w; draft._bh = p.h; draft._s = 100;
            renderEditor(); sendPreview();
            return;
        }
        quick = false;
        if (p && draft) { Object.assign(draft, p); draft._bw = p.w; draft._bh = p.h; draft._s = 100; }
        if (draft) { renderEditor(); sendPreview(); }
    } else if (d.__tc === "settings") {
        applyTc(d.s || {});
    }
});

/* ------------------------------------------------------------ TC settings bridge (qb_settings /trk): accent + language */
function applyTc(s) {
    const ACC = {
        frost: ["#5ad2ff", "#b9f0ff"], ruby: ["#ff5a73", "#ffb3bf"], emerald: ["#2fd07a", "#a8f0c8"], violet: ["#b072f2", "#dcc2fa"],
        amber: ["#ffb347", "#ffe0aa"], rose: ["#ff7ac6", "#ffc2e6"], white: ["#e6eef3", "#ffffff"], sky: ["#4da3ff", "#bcdcff"],
    };
    const mix = (hex, k) => {
        const n = parseInt(hex.slice(1), 16);
        const f = (c) => Math.round(c + (255 - c) * k);
        return "#" + [f(n >> 16), f((n >> 8) & 255), f(n & 255)].map((x) => x.toString(16).padStart(2, "0")).join("");
    };
    const rgba = (hex, a) => {
        const n = parseInt(hex.slice(1), 16);
        return `rgba(${n >> 16}, ${(n >> 8) & 255}, ${n & 255}, ${a})`;
    };
    const a = ACC[s.accent] || (/^#[0-9a-f]{6}$/i.test(s.accent || "") ? [s.accent, mix(s.accent, 0.6)] : ACC.frost);
    const r = document.documentElement.style;
    r.setProperty("--accent", a[0]);
    r.setProperty("--accent-2", a[1]);
    r.setProperty("--accent-txt", mix(a[0], 0.35));
    r.setProperty("--label", a[0]);
    r.setProperty("--edge", rgba(a[0], 0.22));
    r.setProperty("--edge-hi", rgba(a[0], 0.7));
    if (s.lang === "ar" || s.lang === "en") {
        lang = s.lang;
        if (!$("#panel").classList.contains("hidden")) render();
    }
}

applyLang();

/* hold the eye button to see the world through the panel (check a preview quad) */
(function () {
    const b = $("#btnPeek");
    const on = () => $("#panel").classList.add("peek");
    const off = () => $("#panel").classList.remove("peek");
    b.addEventListener("mousedown", on);
    b.addEventListener("mouseup", off);
    b.addEventListener("mouseleave", off);
})();
