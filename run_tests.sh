#!/bin/bash

# ─────────────────────────────────────────
#  ZiCharge - Maestro Test Report Generator
# ─────────────────────────────────────────

PROJECT_DIR="$HOME/Downloads/Maestro/ZiCharge"
SUITE_FILE="$PROJECT_DIR/suites/smoke.yaml"
REPORTS_DIR="$PROJECT_DIR/reports"
MOBILE_NUMBER="${1:-1617539764}"
PASSWORD="${2:-Password100@}"
APP_NAME="ZiCharge"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT_FILE="$REPORTS_DIR/TestReport_${TIMESTAMP}.html"

mkdir -p "$REPORTS_DIR"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║     ZiCharge - Maestro Test Suite    ║"
echo "╚══════════════════════════════════════╝"
echo "📄 Report File: $REPORT_FILE"
echo "⏰ Started    : $(date)"
echo ""

# ── Parse sub-flows from smoke.yaml ─────────────────────────────
mapfile -t RAW_FLOWS < <(grep '^\- runFlow:' "$SUITE_FILE" | sed 's/- runFlow: //')

if [ ${#RAW_FLOWS[@]} -eq 0 ]; then
    echo "❌ No runFlow entries found in $SUITE_FILE"
    exit 1
fi

echo "Found ${#RAW_FLOWS[@]} flow(s) to run."
echo ""

# ── Run each sub-flow individually ──────────────────────────────
declare -a FLOW_NAMES
declare -a FLOW_FILES
declare -a FLOW_RESULTS
declare -a FLOW_DURATIONS
declare -a FLOW_LOGS

TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0
FULL_LOG=""
TOTAL_START=$(date +%s%N)

for REL_PATH in "${RAW_FLOWS[@]}"; do
    # Resolve absolute path relative to suites/
    ABS_PATH="$(realpath "$PROJECT_DIR/suites/$REL_PATH")"
    FLOW_FILE=$(basename "$ABS_PATH")
    FLOW_NAME="${FLOW_FILE%.yaml}"
    TOTAL=$((TOTAL + 1))

    echo -n "  ▶ Running: $FLOW_NAME ... "

    FLOW_START=$(date +%s%N)
    FLOW_OUTPUT=$(maestro test \
        --env Mobile_Number="$MOBILE_NUMBER" \
        --env Password="$PASSWORD" \
        "$ABS_PATH" 2>&1)
    EXIT_CODE=$?
    FLOW_END=$(date +%s%N)

    DURATION_MS=$(( (FLOW_END - FLOW_START) / 1000000 ))
    DURATION_SEC=$(echo "scale=2; $DURATION_MS / 1000" | bc)

    FULL_LOG+="=== $FLOW_NAME ===\n$FLOW_OUTPUT\n\n"

    if [ $EXIT_CODE -eq 0 ]; then
        RESULT="Passed"
        PASSED=$((PASSED + 1))
        echo "✅ PASSED (${DURATION_SEC}s)"
    else
        RESULT="Failed"
        FAILED=$((FAILED + 1))
        echo "❌ FAILED (${DURATION_SEC}s)"
    fi

    FLOW_NAMES+=("$FLOW_NAME")
    FLOW_FILES+=("$FLOW_FILE")
    FLOW_RESULTS+=("$RESULT")
    FLOW_DURATIONS+=("${DURATION_SEC}s")
    FLOW_LOGS+=("$(echo "$FLOW_OUTPUT" | sed 's/</\&lt;/g; s/>/\&gt;/g')")
done

TOTAL_END=$(date +%s%N)
TOTAL_MS=$(( (TOTAL_END - TOTAL_START) / 1000000 ))
TOTAL_DURATION=$(echo "scale=2; $TOTAL_MS / 1000" | bc)

echo ""
echo "────────────────────────────────────────"
echo "  Total: $TOTAL | ✅ Passed: $PASSED | ❌ Failed: $FAILED"
echo "  Duration: ${TOTAL_DURATION}s"
echo "────────────────────────────────────────"
echo ""

# ── Overall status ───────────────────────────────────────────────
if [ $FAILED -eq 0 ]; then
    OVERALL_STATUS="✅ ALL TESTS PASSED"
    STATUS_CLASS="all-passed"
else
    OVERALL_STATUS="❌ $FAILED TEST(S) FAILED"
    STATUS_CLASS="some-failed"
fi

# ── Build HTML table rows ────────────────────────────────────────
TABLE_ROWS=""
for i in "${!FLOW_NAMES[@]}"; do
    NUM=$((i + 1))
    NAME="${FLOW_NAMES[$i]}"
    FILE="${FLOW_FILES[$i]}"
    RESULT="${FLOW_RESULTS[$i]}"
    DURATION="${FLOW_DURATIONS[$i]}"
    LOG="${FLOW_LOGS[$i]}"

    if [ "$RESULT" = "Passed" ]; then
        BADGE='<span class="badge pass">✅ Successful</span>'
        ROW_CLASS="row-pass"
    else
        BADGE='<span class="badge fail">❌ Failed</span>'
        ROW_CLASS="row-fail"
    fi

    TABLE_ROWS+="
    <tr class='$ROW_CLASS'>
      <td>$NUM</td>
      <td>$NAME</td>
      <td>$FILE</td>
      <td>$DURATION</td>
      <td>$BADGE</td>
    </tr>
    <tr class='log-row'>
      <td colspan='5'>
        <details>
          <summary>▶ View Log</summary>
          <pre>$LOG</pre>
        </details>
      </td>
    </tr>"
done

# ── Write HTML ───────────────────────────────────────────────────
cat > "$REPORT_FILE" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>ZiCharge - Test Report</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet"/>
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  :root {
    --bg: #0b0f1a;
    --surface: #111827;
    --surface2: #1a2235;
    --border: #1e2d45;
    --accent: #3b82f6;
    --accent2: #06b6d4;
    --green: #22c55e;
    --red: #ef4444;
    --orange: #f59e0b;
    --text: #e2e8f0;
    --muted: #64748b;
    --font: 'Syne', sans-serif;
    --mono: 'JetBrains Mono', monospace;
  }
  body { background: var(--bg); color: var(--text); font-family: var(--font); min-height: 100vh; padding: 40px 20px; }
  .wrapper { max-width: 1100px; margin: 0 auto; }

  .header {
    background: linear-gradient(135deg, #1a2a4a 0%, #0f1e3a 60%, #0b1628 100%);
    border: 1px solid var(--border);
    border-radius: 16px;
    padding: 36px 40px;
    margin-bottom: 24px;
    position: relative;
    overflow: hidden;
  }
  .header::before {
    content: '';
    position: absolute;
    top: -60px; right: -60px;
    width: 220px; height: 220px;
    border-radius: 50%;
    background: radial-gradient(circle, rgba(59,130,246,0.15) 0%, transparent 70%);
  }
  .header h1 {
    font-size: 2rem; font-weight: 800;
    background: linear-gradient(90deg, #60a5fa, #06b6d4);
    -webkit-background-clip: text; -webkit-text-fill-color: transparent;
    margin-bottom: 8px;
  }
  .header p { color: var(--muted); font-size: 0.85rem; font-family: var(--mono); }

  .status-banner {
    border-radius: 12px; padding: 18px; text-align: center;
    font-size: 1.1rem; font-weight: 700; letter-spacing: 0.05em;
    margin-bottom: 24px; border: 1px solid;
  }
  .all-passed { background: rgba(34,197,94,0.08); border-color: rgba(34,197,94,0.3); color: var(--green); }
  .some-failed { background: rgba(239,68,68,0.08); border-color: rgba(239,68,68,0.3); color: var(--red); }

  .stats { display: grid; grid-template-columns: repeat(5, 1fr); gap: 16px; margin-bottom: 24px; }
  .stat-card { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 24px 16px; text-align: center; }
  .stat-card .number { font-size: 2rem; font-weight: 800; font-family: var(--mono); display: block; margin-bottom: 6px; }
  .stat-card .label { color: var(--muted); font-size: 0.8rem; }
  .c-blue { color: var(--accent); } .c-green { color: var(--green); } .c-red { color: var(--red); }
  .c-orange { color: var(--orange); } .c-purple { color: #a78bfa; }

  .table-wrap { background: var(--surface); border: 1px solid var(--border); border-radius: 16px; overflow: hidden; margin-bottom: 24px; }
  table { width: 100%; border-collapse: collapse; }
  thead tr { background: linear-gradient(90deg, var(--accent) 0%, var(--accent2) 100%); }
  thead th { padding: 14px 20px; text-align: left; font-size: 0.8rem; font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; color: #fff; }
  tbody tr { border-bottom: 1px solid var(--border); transition: background 0.2s; }
  tbody tr:hover { background: var(--surface2); }
  tbody td { padding: 14px 20px; font-size: 0.9rem; font-family: var(--mono); }

  .row-fail td:first-child { border-left: 3px solid var(--red); }
  .row-pass td:first-child { border-left: 3px solid var(--green); }

  .log-row td { padding: 0 20px 12px; background: var(--bg); }
  .log-row:hover { background: var(--bg) !important; }
  details summary { cursor: pointer; color: var(--accent); font-size: 0.8rem; padding: 8px 0 4px; user-select: none; }
  details pre {
    background: #060a12; border: 1px solid var(--border); border-radius: 8px;
    padding: 12px 16px; font-size: 0.75rem; color: #94a3b8;
    overflow-x: auto; white-space: pre-wrap; word-break: break-all;
    max-height: 300px; overflow-y: auto; margin-top: 6px;
  }

  .badge { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 0.8rem; font-weight: 600; font-family: var(--font); }
  .badge.pass { background: rgba(34,197,94,0.12); color: var(--green); border: 1px solid rgba(34,197,94,0.3); }
  .badge.fail { background: rgba(239,68,68,0.12); color: var(--red); border: 1px solid rgba(239,68,68,0.3); }

  .full-log { background: var(--surface); border: 1px solid var(--border); border-radius: 16px; overflow: hidden; }
  .full-log-header { padding: 16px 24px; font-weight: 700; font-size: 0.95rem; border-bottom: 1px solid var(--border); background: var(--surface2); }
  .full-log pre { padding: 20px 24px; font-family: var(--mono); font-size: 0.78rem; color: #64748b; white-space: pre-wrap; word-break: break-all; max-height: 400px; overflow-y: auto; }

  @media (max-width: 700px) {
    .stats { grid-template-columns: repeat(2, 1fr); }
    thead th:nth-child(3), tbody td:nth-child(3) { display: none; }
  }
</style>
</head>
<body>
<div class="wrapper">
  <div class="header">
    <h1>$APP_NAME - Test Report</h1>
    <p>Report Generated: $TIMESTAMP &nbsp;|&nbsp; App ID: com.newroztech.gamewallet</p>
  </div>

  <div class="status-banner $STATUS_CLASS">$OVERALL_STATUS</div>

  <div class="stats">
    <div class="stat-card"><span class="number c-blue">$TOTAL</span><span class="label">Total Flows</span></div>
    <div class="stat-card"><span class="number c-green">$PASSED</span><span class="label">Successful</span></div>
    <div class="stat-card"><span class="number c-red">$FAILED</span><span class="label">Failed</span></div>
    <div class="stat-card"><span class="number c-orange">$SKIPPED</span><span class="label">Skipped</span></div>
    <div class="stat-card"><span class="number c-purple">${TOTAL_DURATION}s</span><span class="label">Total Duration</span></div>
  </div>

  <div class="table-wrap">
    <table>
      <thead>
        <tr><th>#</th><th>Flow Name</th><th>File</th><th>Duration</th><th>Result</th></tr>
      </thead>
      <tbody>
        $TABLE_ROWS
      </tbody>
    </table>
  </div>

  <div class="full-log">
    <div class="full-log-header">📋 Maestro Execution Log</div>
    <pre>$(echo -e "$FULL_LOG" | sed 's/</\&lt;/g; s/>/\&gt;/g')</pre>
  </div>
</div>
</body>
</html>
HTMLEOF

echo "✅ HTML Report saved to:"
echo "   $REPORT_FILE"
echo ""

# ── Generate PDF ─────────────────────────────────────────────────
PDF_FILE="${REPORT_FILE%.html}.pdf"
echo "📄 Generating PDF..."

google-chrome --headless --disable-gpu \
    --print-to-pdf="$PDF_FILE" \
    --print-to-pdf-no-header \
    "file://$REPORT_FILE" 2>/dev/null

if [ -f "$PDF_FILE" ]; then
    echo "✅ PDF Report saved to:"
    echo "   $PDF_FILE"
else
    echo "⚠️  PDF generation failed. Make sure Google Chrome is installed."
    echo "   Try: sudo apt install google-chrome-stable"
fi

echo ""
echo "🌐 Opening HTML report in browser..."
xdg-open "$REPORT_FILE" 2>/dev/null || echo "   Open manually: file://$REPORT_FILE"
