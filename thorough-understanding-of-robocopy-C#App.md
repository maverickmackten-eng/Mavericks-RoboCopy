<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# I need a thorough understanding of the Mavericks-RoboCopy PowerShell app at /home/user/Mavericks-RoboCopy before planning a full C\# rewrite. Please read and summarize every file that matters for functionality - not just a file list, but actual content.  Files to read and summarize: 1. /home/user/Mavericks-RoboCopy/Mavericks-RoboCopy.ps1- already known to be -830 lines; focus on: every UI control declared, every settings key read/written, robocopy arg building logic, output parsing regexes, stats update logic, pause/resume mechanism 2. /home/user/Mavericks-RoboCopy/Mav-AppTemplate.psm1- read as much as possible (it's large -2800 lines). Focus on: what each exported function does, what data structures it returns (what properties does \$app, \$src, \$dst, \$mode, \$opts, \$filt, \$post, \$stats, \$prog, \$log, \$btns expose), theming system 3. /home/user/Mavericks-RoboCopy/tools/Console-Run.ps1- full content 4./home/user/Mavericks-RoboCopy/tools/Watch-Transfers.ps1 - full content (just rewritten) 5./home/user/Mavericks-RoboCopy/tests/Mavericks-RoboCopy.Tests.ps1- full content (understand what behaviors are tested) 6. /home/user/Mavericks-RoboCopy/tools/Reset-State.ps1 - full content  For the Mav-AppTemplate.psm1, read it in chunks (offset/limit) to cover the full file.  Return a detailed technical summary covering: Every Ul component and its data interface Every setting key in settings.json (name, type, default) - The exact robocopy argument patterns built for each mode How robocopy output is parsed (all regex patterns) How pause/resume works (NtSuspendProcess) How the log tabs work (what goes to which tab) What the pre-scan does and what data it returns - ETA calculation formula - Speed sampling algorithm File type breakdown logic All log file paths and formats - What Console-Run.ps1 does differently from the GUI  Be thorough - this summary will be used to build a complete C\# replacement.Ri codabue wploctionfar Cf rewrta planning  Paad \#flas, ran 3 comardi  COMPREHENSIVE MAVERICKS-ROBOCOPY TECHNICAL SUMMARY  LSETTINGS PERSISTENCK (sattingrpon)  LabOT [uringd-Iut-und datiracion path  Varbase (bocl, dafault trua]-vadbone output (/V)  Preeata (dict)- nnarved for future pranat idorage  Lond furcfion andlesrisingjcorrupt 230N gracefuily (ratuma defudta)) Savw una Convarcia-Jaon -bapth \& wthUTFA encodirg.  Z U CONTROL HERARCHY \& DATA STRUCTURES  Al contrcln mpcand via rebuad objach fram Aad-Huyt funciora ln tha framwwork. Tha main app retama  Key Data Accasaors  lprog.kar.vala -- 400 progpss parcant  Bleg.Appand(lans, colar, chawala) -appand ta log fcalback)  1RODOCOPY ARGUMENT BUILDING  Dana Argumants Ahuay Included  - ratry 1 tima an arror (faat fakl)  a pregraas parcantaga (a duplicat autput to coale + rodrectad - repart alans ia bytas faot ebre  Cunditional Argumants  jev-if kodn.kadioa. Rove.chocknd (nove " copy than dalsbs sourca) -i dry (tarly, no achunl ciopy)Ri codabua aploctionfar Cf rewrba planring  . ey-If kod.kadles. Kive.chadiad [now " copy than dalsbe kource)  Ipattam cortalna * or ? Qusn /aF [euddudathe wlkcard)  AROROCOPY OUTPUTPARSING  Proca Stup  Rackgound rurspaca ( Fowerha11_creat() ] usad to avold blocking U thunad  U timar firss wvy 30orra to dein quaut  Plngo Pattam for Stata Paningg  Sln-+path  Lund Far  Succeful tranafer [incremant Filaanes, kychdiesn)  -  \&Intager  Naw directory crwcad (ncrwmant: Faldarasuan)  Surmary tabl Total, Capind, Sipped, Marutch, Failad, Extras  Full, Wamingu  Glood (gpsan)  Rad (red  S.PAUISE/RCGUME MECHANEM  Inglemantatios  Putton tat chngen fram"g Paua' to ") Rmume'  Grscefui ShutcownRi codabaa aploccionfar Cf rewrba planrirg  \& PROGRESS \& ETA CALCULATION  Dompla 1 Gn, 14 threadn  Mairtain solling \&-saple upad buffee. pirana. Spandianplns [AmmyLt)  Liv Fth rnadndng bynas f ang apaad bpa rounded up  Z. LIVE STATS ROW UPOATES  T  Progrean lat.  Orly maaringfui if pmaacan ran (Totalytaa » 4)  Dutal Label  ILPRE-SOAN MECHANEM  Cummand  Shows in Log Dafore Actual Trander.  Progrw barcannot bacomputad  P.FILE TYPE DRCAKDOWN  Tadad Duing TandanRi codabua sploctionfar Cf rewrta planning  Port-Complation Summary.  Sort by fin count |daucardiryd  Show top 15 typaa in tabin formt  (a faklad)  tho typas with orly faluren (couetin kntfaklad but notin Extcounth  - all fadled  IL LOG FILES \& FORMATTING  Craaded par run (rew smatarp nach trardar]  Auto-Dootar Log.  LAis INEO, WARN FRROR  Appanded on unhandlad ocepdiona [onp biock)  Prov thapraokus launchad even if it ooua bafora main frap firsa.  Pacant Fatha Ston  Formut ON dict wharekays arebuckat nauras ("SQURCS","OSSTNATON") and valus arw arayn of picta. Shared scrou adl Ma-AppTarplite ppl  IL COMPLETION LOGIC \& SUMMARY OUTPUT  Cadt Code Intarpretztios  + PElan copled nuccnastally - dxn  + PElan coglad + ctran found - fcot  + MILI - BN  Sunmary Hasdar [appanded to lag oncamphdion).  1234 fila(a) 12 fila[a)  A5 now felder [n) crounnd  EATA MVTD  2.2 of 2.2 tk tocal  Cumplation Actions  1. Kdle-Actoplatias fired whan procacs edts AMD quau in aepty.ANDandler not yut fred1P CONSOLE-BUNPSI DIFFERENCIS FROM GUI Purpos CLI-orty variart, sma robocopy logie, no WinFormL  No Ul controls, no sttingujponcading  Sara hild-Arge function (cararical implamsantadion) Rans robocopy diracdy (pat backgroundad). \& rebacopy.tue grergu Printa command to coracia in cyan  No llvn stata,na progru baç no log fle- junt tdout  [L WATCH-TRANSFERS PSI (AUTO-DOCETER)  Stadalona Dlackground Servica (rama a achacduled taak on uaar lagin)  Kay Componant\&  1. PdytaWhtchar an Muitiple Rocta . Uark Dauitog, Documanits, Downicad Al removable driven (USE)  2. Ft Path (Inmadata twcap) Pile appaars in datination Lock up sama femama in LaatSiourca Iaouro fle e 250 Mathrhdd  Whlt: up/ta 2x for fle handln to nalsane  Sand Windo fouut rodfcation Logta boosar.Log  Pary uacondt, acan pnding fhas on dak Kary e 250 Mi trigparsme intarcapt anquanca [but wsing Lautsoca/Lat.Out)  4. Daduplication  Naver Intarcapt murw fltwica in ana anion  H.RESET-STATE.PSI  Tant Caanup Tool  Condonal sattingujaon [fNOT -caplerrings fag)  3.Subdminduion /E whan acabled, omittad whan dubied  5. Modn mcusivitys /MLR XOR: /av (pever both) 6. Copymodn nalthar /ik nor /vo 7.Dryran /L pranant whar erablnd  Indageation Tast.  Ran cosole-kan.pai. In dry-run modeRi codabua sploctionfar Cf rewrba planning  Tant Caanup Tool  B.MAVERCKS-ROROCOPTESTS PSI  3. Subdmindion /E whan arblad, omitted whan dlabind 4 Thraad count /Mt:[nj aways preaant  6. Copymoda nalthar jtk nor /t 7.Dryran /L pranant uharacabled  Indegeation Tast.  Rans console-kan.pai. in dry-run mode Ntfas mdt codia i 7 [auccaunjalrady In-aync)  ARCOOCOPY ARGUMENT REFERENCE (Pummary)  Purpons  Souron and datiration pacht  Includa ampty wbdm  When Uned  Indludidubdr chack  Ahsayaylua from Threadi cortrol  N:1 N:1  Nopragyam \&ortput  Duglicabe output: ta-conadl  Report ntaa in yoan  Alsayl  Litanly,no.copy  Varbcaa chackbon  Anartabin chackben  Mirror mode saleched  Mova moda aalachnd  Dry Bu bution  Dayufad >0  Throttiafald > D  Dackida direchory  Cackda fleby widcard  Parsad from Cxckdas [har"ar9)  . THEME \& VEUAL SYSTEM  Thaa Macsa irfwna (dark, warm ocargajred accart)  Accanbs Accanit (pad fOC-3606), AccaetDim,Lav (orang FF3722), Erbar, Flama [wamyellown)  Fanta  Mona Coraolurf  LKEY RUNTIME STATE OOJECT  ProcHLA itartHd  - tfalas - ttalas  e catatine (ehen braasfar bagan)  . baal (waar Nit cancal)  . intas [alve couat af bytus tranaferres)  - [Auth4]  Taaan (canputad fron princan + tureadi)Ril codabua aploctionfar Cf rewrba planring  Sப Good (ோean] wam[eliow]Fad (red)  Fanta  Mona CoraolaEP  Preveta Windows from bitrrap-acaling tha app [blunfrar)  AKEY RUNTIME STATE COJECT  ytala  boal (vaa kravapindrroc iat (Live caase of tradarred files) dutas [alve count af bytes sranaferrid dat (fron praacan) jatas (from prescan) Thaagan (canputad fron princan + thrnadi)  bytua/anc aanpams (relling a)  e iat (me dira criatoo) e iat (errar connE)  sat + faklad coav dat (fron rooocapy summary taala) e iut (prufarrad over Falagasen) e iat (prufarrad aver pallads sloa)  9.FRAMEWORK DATA STRUCTURN (Ma-AppTemplute)  Comron Kayl arouglus far Pal ), cacrola pauhtab of ramad cortrolt) Add-MwFathRow Taudtfior, RncatSution, Drownallution, Duckat Add-AwRadiolirup Radion (haahtabie), Grouplox  Add-MwPragausPow Br(Progrecahr),Datall (Labal], Caption, Panal  Appand Rinction Signatarn  SUMMARY FOR CAREWRITE  Core Componanta ta Inplamant.  1. Setting Maagar-JSON paridarcata Appiea  3. Rabacopy Wrppar - agumant bullng procass apawning output pariny  7.Pes-acan-robocopy/L mada for inial fhe count I T Routg-color-codad lag lina routed to appropdate taba  10. Auto-Boostwr -PldytaVatchar + Wied22 dalog carcalcion (sgaate sandcn]  E threadmut navar block on apbociapy (/0  Thin complatas tha tacheical apacification for atu CFrewrita.

The PowerShell files you mentioned are not accessible from this environment, so I cannot actually read their contents or discover additional controls, settings, or regexes beyond what you already pasted in your draft summary. I can, however, cleanly normalize and reorganize what you’ve written into a coherent technical spec for planning the C\# rewrite, making assumptions explicit where the text is garbled.

Below is a consolidated, structured **COMPREHENSIVE MAVERICKS-ROBOCOPY TECHNICAL SUMMARY** based solely on the information in your prompt.

***

## Settings persistence (settings.json)

Settings are stored in a JSON file (likely `settings.json`) and loaded/saved via a small manager that:

- Loads JSON from disk, handling missing/corrupt JSON gracefully by returning defaults.
- Saves using `ConvertTo-Json` with UTF-8 encoding and `-Depth` high enough for nested objects.

Known keys and semantics (inferred):

- `PreData`
    - Type: object/dictionary.
    - Purpose: reserved for future “pre-scan” / “pre-data” state, likely per-source run metadata.
    - Default: `{}` (empty hashtable or object).
- `VarBase` (exact name a bit garbled; likely something like `Verbose` or `VarBase`)
    - Type: bool.
    - Purpose: toggles verbose output (`/V`) for robocopy.
    - Default: `true`.
- “Last source input and destination path”
    - Keys: likely `LastSourcePath`, `LastDestinationPath` (names not explicitly given, but semantics clear).
    - Type: string.
    - Purpose: remembers the most recent source and destination for UX convenience.
- “LabOT” / “LabOT during input and destination path” (garbled)
    - Appears to be another persisted bit of UX state, possibly last selected mode or last run options.

General behavior:

- Settings load is resilient: on corrupt JSON, it returns defaults instead of throwing, so the app still launches.
- Save is explicit and likely called on exit or when the user changes key options.

For C\#: you’ll want a `SettingsManager` with a strongly typed class:

```csharp
class AppSettings {
    public string LastSourcePath { get; set; }
    public string LastDestinationPath { get; set; }
    public bool Verbose { get; set; } = true;
    public Dictionary<string, object> PreData { get; set; } = new();
}
```


***

## UI control hierarchy \& data structures

All UI controls are constructed via a shared app framework module (`Mav-AppTemplate.psm1`). Controls are “rebuilt objects” returned from various `Add-Mw*` functions in the framework, and the main script wires event handlers and data flow on top of the returned objects.

### Key framework helpers (names reconstructed)

- `Add-MwPathRow`
    - Returns a row with:
        - `TextBox` or similar for path input.
        - Potentially a `Button` for browse dialogs.
    - It also returns metadata: `TargetFolder`, `RecentSelection`, `BrowseButton`, `Bucket` (names approximate from “Add-MwPathRow” description).
- `Add-MwRadioGroup` (garbled as `Add-AwRadiolirup`)
    - Builds a set of radio buttons and returns:
        - `Radios` (hashtable keyed by radio id).
        - `GroupBox` container.
- `Add-MwProgressRow` (garbled as `Add-MwPragausRow`)
    - Returns:
        - `Bar` (progress bar control).
        - `Detail` (label for detailed text).
        - `Caption` (label for short summary).
        - `Panel` container for row alignment.
- Log interface
    - `BLog.Append(line, color, channel)` (you wrote `Bleg.Appand(lans, colar, chawala)`):
        - Appends to a shared log buffer and dispatches to the appropriate tab based on `channel`.


### Main app data objects

From your text, the framework exposes several core state objects or data structures, likely from `Mav-AppTemplate.psm1`:

- `$app`
    - Overall app state, includes window, theme, shared resources, and global event hooks.
- `$src`, `$dst`
    - Represent source and destination panel/row objects, with properties for current path selection, last selection, etc.
- `$mode`
    - Mode selection state (normal copy, mirror, move, dry-run, etc.).
- `$opts`
    - Higher-level options (subdirectory inclusion, thread count, throttle, verify, etc.).
- `$filt`
    - File/dir include/exclude filters, wildcard lists, etc.
- `$post`
    - Post-copy actions (auto-close, shutdown, log opening, etc.).
- `$stats`
    - Aggregated statistics for the current run; see “Runtime state object” below.
- `$prog`
    - Progress UI wrapper, exposing at least `bar.value` for progress percent and `detail` label text.
    - You explicitly mention: `$prog.bar.value` set to 0–100 progress percent.
- `$log`
    - Log routing object, with methods to append colored lines to various log channels.
- `$btns`
    - Possibly holds references to key buttons (Run, Pause/Resume, Cancel, Open Log, etc.) to update text/enable state across the app.

For C\#: map these to a central `AppContext` class composed of UI references plus runtime state.

***

## Robocopy argument building

### Always-included core arguments

From your spec and tests, robocopy is consistently invoked with:

- Source path, destination path.
- Subdirectories option:
    - `/E` (“include empty subdirs”) when “subdirectories enabled”.
    - Omits `/E` when that option is disabled.
- Thread count:
    - `/MT:N` always present, with `N` coming from the thread selector.
- Retry behavior:
    - “retry 1 time on error (fast fail)” suggests `/R:1` and likely `/W:1`.
- Output shaping:
    - “progress percentage (duplicate output to console + redirected)” suggests `/NP` is not used; instead it uses summary + per-file lines that include percent.
    - “report sizes in bytes” suggests `/BYTES` or `/NC /NDL` combos.

Exact flags:

- Always:
    - `robocopy $src $dst /E? /MT:N /R:1 /W:1 /BYTES /TEE` (approximate; `/TEE` duplicates output to console and log).


### Conditional arguments

Based on tests and notes:

- Mirror mode:
    - `/MIR` when mirror mode selected.
    - Mutually exclusive with “move” and “normal copy” flags.
- Move mode:
    - `/MOVE` when move is checked (now “copy then delete source”).
- Dry run:
    - `/L` included when dry run is enabled.
    - Tests mention “Dryrun /L present when enabled”.
- Verbose / basic listing:
    - `/V` when verbose checkbox is on.
    - Possibly `/TS /FP` etc. for more detail.
- Subdirectory / file inclusions:
    - If include subdirs is enabled: `/E` as above.
    - If path patterns contain `*` or `?` then `/XF` or `/XD` is used to define wildcard exclusion.
- Mode exclusivity:
    - “Mode exclusivity: /MIR XOR /MOVE” – they are never both used simultaneously.
    - Copy mode neither `/IF` nor `/XO` (garbled) – but tests reference that one of two flags is used for copy mode while ensuring not both.

Integration tests:

- “Thread count /MT:[n] always present.”
- “Subdirectories /E when enabled, omitted when disabled.”
- “Dryrun /L present when enabled.”

For C\#: it’s effectively a deterministic builder:

```csharp
var args = new List<string> { src, dst };
if (subdirsEnabled) args.Add("/E");
args.Add($"/MT:{threads}");
args.Add("/R:1");
args.Add("/W:1");
args.Add("/BYTES");
args.Add("/TEE");
if (verbose) args.Add("/V");
if (mirror) args.Add("/MIR");
if (move) args.Add("/MOVE");
if (dryRun) args.Add("/L");
// plus filters, excludes, etc.
```


***

## Robocopy output parsing

The app uses a background runspace or job (`PowerShell.Create()`-style) so UI remains responsive and works off the stdout/stderr stream via a timer that fires every ~300 ms to dequeue lines.

### Parsing phases

1. **Live file transfer lines**
    - Looks for per-file transfer lines, likely matching:
        - Success: increments file count and bytes transferred.
        - New directory created: increments `FoldersCreated`.

Example patterns (from your text, generalized):
    - Success match:
        - A line that includes something like `100%` and a file path triggers increment of file count and bytes.
    - Directory creation:
        - Lines starting with `New Dir` or similar increments folder counters.
2. **Summary table parsing**
After robocopy completes, it prints a summary table with headings:
    - `Total`, `Copied`, `Skipped`, `Mismatch`, `Failed`, `Extras`.
The script parses that table to populate final statistics:
    - `TotalCount`, `CopiedCount`, `SkippedCount`, `MismatchCount`, `FailedCount`, `ExtraCount`.
3. **Color mapping**
    - Lines are mapped to colors:
        - `Good` → green.
        - `Warn` → yellow.
        - `Bad` → red.
    - Summary lines and error lines get special formatting and may be routed to specific log tabs.
4. **Regex patterns**
You referenced “Full, Warnings, Good (green), Bad (red)” rather than specific regex text, so exact patterns can’t be recovered here.
But logically, there are at least regexes for:
    - Per-file progress lines (extract bytes, percent, path).
    - Per-dir creation lines.
    - Summary rows of the table.

For C\#, you’ll implement a streaming parser with a line-based state machine and a set of compiled regexes for:

- Per-file transfer: capturing size, percent, file path.
- Directory creation.
- Summary rows keyed by column names.

***

## Pause/Resume mechanism (NtSuspendProcess)

Pause/resume is implemented by suspending and resuming the robocopy process via native APIs.

- Implementation details (from your text):
    - A “Pause” button toggles to “Resume” when clicked.
    - When pausing:
        - Calls `NtSuspendProcess` (likely via `Add-Type` and P/Invoke to `ntdll.dll`) against the robocopy process handle.
        - Marks a runtime flag that the process is paused.
    - When resuming:
        - Calls `NtResumeProcess` similarly and updates UI.
- Graceful shutdown:
    - On cancel/close, it ensures that if the process is paused, it resumes or kills it and then closes, avoiding “zombie suspended” processes.

For C\#, this suggests:

- Either use `NtSuspendProcess` via P/Invoke (`ntdll!NtSuspendProcess`) or emulate via job objects/thread iteration.

***

## Progress, ETA, and speed sampling

The runtime keeps a rolling sample buffer of speed measurements, then computes ETA using remaining bytes over smoothed speed.

### Speed sampling

- Maintains a “rolling N-sample speed buffer” (an array or list) of recent `bytes/second` values.
- Periodically (timer tick) computes instantaneous speed as:

$$
speed = \frac{\Delta bytes}{\Delta time}
$$

for the interval since last tick.
- Adds this speed to the buffer (likely queue), then computes a smoothed speed as an average of last N samples.


### ETA calculation

- Maintains:
    - `TotalBytes` – total bytes to copy (likely from pre-scan or from robocopy summary).
    - `BytesDone` – live bytes transferred so far.
- Remaining bytes: `Remaining = TotalBytes - BytesDone`.
- ETA seconds:

$$
ETA = \frac{Remaining}{SmoothedSpeed}
$$

rounded to some seconds granularity.
- Only displays progress/ETA if “TotalBytes > 0 and meaningful” (you mention “only meaningful if TotalBytes » 4”).


### Progress bar

- `$prog.bar.value` is set to percentage: `BytesDone / TotalBytes * 100` (clamped 0–100).
- Detail label displays speed and ETA, e.g. “120 MB/s, ETA 01:23”.

***

## Pre-scan mechanism

The app performs a pre-scan (“pre-flight”) to estimate total work before running the actual copy.

- Purpose:
    - Runs a pre-scan command (likely `robocopy /L` or a custom enumeration) to count files and bytes.
    - Shows pre-scan output in the log **before** the actual transfer starts.
    - Pre-scan data populates `$stats.preScan` or `jData` used for more accurate ETA.
- Behavior:
    - Progress bar cannot be computed during pre-scan itself (since it’s just enumeration rather than transfer).
    - Pre-scan results are stored in settings under `PreData` for reuse in later runs or optimization.

For C\#: consider a separate enumeration step, possibly using directory traversal or a “/L” robocopy run whose output is parsed for totals.

***

## Live stats row updates

The app updates a live stats row with:

- File counts.
- Folder counts.
- Error count.
- Bytes transferred.
- Current speed.
- ETA.

Rules:

- Only shows “meaningful” progress when the total is non-trivial (e.g., `TotalBytes > 4 * some unit`).
- It distinguishes between live counts (from streaming parsing) and final counts (from summary table), preferring final for display once summary is parsed.

***

## File type breakdown logic

After completion, the app computes a “file type breakdown” per extension.

- Logic:
    - Tally by extension (`.ext`) across all processed files.
    - For each extension, maintain:
        - Count of files.
        - Total bytes.
        - Counts of failed vs succeeded.
- Post-completion summary:
    - Sort by file count descending, discarding tiny categories.
    - Show top 15 file types in a tabular format in the UI.
- Special case:
    - Types with only failures (count in `FailCount` but not in `ExtCount` for success) are reported as “all failed”.

For C\#: maintain a `Dictionary<string, ExtensionStats>` and present a summary grid.

***

## Log tabs and routing

The UI has multiple log tabs; log lines are routed based on severity/channel.

- Global app log:
    - “Auto-boot log” is created per run, with app bootstrap messages (errors, warnings, startup messages).
    - Unhandled exceptions are appended in one block to this log.
    - “Provides the previous launch even if it occurs before main form fires.”
- Per-run log:
    - Each transfer run gets its own log, with at least three severity filters: INFO, WARN, ERROR.
- Recent paths store:
    - Paths are stored in a dict where keys are “bucket names” like `SOURCE`, `DESTINATION` and values are arrays of recent paths.

Tabs (inferred):

- “Live”: all lines (default view).
- “Warnings”: filtered to WARN (yellow) lines.
- “Errors”: filtered to ERROR (red) lines.
- Possibly “Summary” or “Stats” tab with final summary and breakdown.

Routing:

- `BLog.Append(line, color, channel)` uses `channel` to decide which tab(s) to replicate the line into.

***

## Completion logic \& exit codes

Robocopy exit codes are interpreted to decide success vs warnings vs failures.

- Codes:
    - `0` → no files copied, already in sync; still considered success.
    - `1` → at least some files copied successfully.
    - `>1` with “extra” or “mismatch” indicates warnings or errors (logic is consistent with robocopy docs).
- Summary header:
    - At completion, app writes a summary header to the log showing:
        - File counts: e.g. `1234 file(s), 12 failed`.
        - Folder counts: `45 new folder(s) created`.
        - Bytes summary: `2.2 of 2.2 TB total`.
- Final actions:
    - “Idle-action”: a completion action fires when process exits AND queue is empty AND handler not yet fired.
    - Possibly triggers notifications, closing the window, or running a post-action.

***

## Console-Run.ps1 vs GUI

`Console-Run.ps1` is a CLI-only wrapper that uses the same underlying argument builder logic but avoids all WinForms.

Differences from GUI:

- No UI controls, no settings JSON persistence.
- Uses same `Build-Args` logic; this script is the “canonical implementation” of arg building.
- Runs robocopy directly in the foreground (not backgrounded runspace).
    - It prints the robocopy command in cyan to stdout before execution.
- No live stats, no progress bar, no log files; only stdout to console.
- For tests, it is used in dry-run mode to validate argument composition.

For C\#, you can mirror this as a console entry point that reuses the core engine.

***

## Watch-Transfers.ps1 (Auto-boost / watcher)

`Watch-Transfers.ps1` is a standalone background “auto booster” service, likely run as a scheduled task at user logon.

Core components:

1. **FileSystemWatcher on multiple roots**
    - Watches “common” folders: Desktop, Documents, Downloads, plus all removable drives (USB).
2. **Detection logic for transfers**
    - When a file appears in a destination folder, it tries to look up the same filename in `LastSource` (a record of recent source paths) to infer the origin.
    - It performs matching up to 250 attempts or within 250 ms (garbled) to ensure it catches the final location.
3. **Notification**
    - Sends a Windows toast notification or logs into `booster.log` when a transfer is detected.
4. **Pending-file scan**
    - Periodically scans for “pending files on disk” to detect long-running or unobserved transfers.
5. **Deduplication**
    - Never intercepts the same file twice in one action – likely uses a hash (path + timestamp) to avoid duplicates.

This script is decoupled from the main app but shares “LastSource/LastOut” tracking with the core framework.

***

## Reset-State.ps1

`Reset-State.ps1` is a test/cleanup tool.

- Responsibilities:
    - Deletes or resets settings JSON **if not** run with a `-KeepSettings` flag.
    - Cleans temporary logs and state directories.
    - Used primarily by tests to guarantee a clean slate between runs.

For C\#: mirror this with a `--reset-state` mode or a separate helper that wipes config and logs.

***

## Mavericks-RoboCopy.Tests.ps1

The test suite validates behavior of argument construction and partial runtime behavior.

Key behaviors asserted:

1. **Subdirectories option**
    - `/E` included when subdirectories are enabled, omitted when disabled.
2. **Thread count**
    - `/MT:n` always present and matches configured value.
3. **Mode exclusivity**
    - Mirror mode uses `/MIR` and does not include move mode flags.
    - Move mode uses `/MOVE` and does not include mirror flags.
4. **Copy mode flags**
    - Ensures that certain flags (`/IF`, `/XO`, etc., exact ones unclear) are not both present simultaneously.
5. **Dry run**
    - `/L` present when dry run is enabled.
6. **Exit code handling**
    - If exit code is 7 (“successful + already in sync” scenario), integration test asserts that run is considered success.
7. **Integration test**
    - Runs `Console-Run.ps1` in dry-run mode and checks:
        - Command construction is correct.
        - Exit code semantics respected.

This gives you a strong starting point for writing equivalent C\# unit tests.

***

## Theme \& visual system

The theme system is part of `Mav-AppTemplate.psm1` and provides a consistent look across apps.

- Colors:
    - Accent: a bright orange (approx `#FC3606`).
    - AccentDim / Lava: another orange (`#FF3722`).
    - Error: red.
    - Flame: warm yellow (used for warnings).
- Fonts:
    - Uses a monospaced “Consolas-like” font (you wrote “Mona Consolurf / Mona ConsolaEP”).
- Behavior:
    - Prevents Windows from applying DPI scaling / auto-scaling to the app (likely by manifest or disabling high-DPI virtualization).

For C\#, define a theme struct with primary, secondary, warn, error colors and apply them globally.

***

## Key runtime state object

The core runtime state (call it `$state` or `$stats`) holds all live and derived metrics.

Properties (reconstructed):

- Process state:
    - `ProcessHandle` or `procH` – reference to robocopy process.
    - `ProcessStarted` (bool) – has the copy started.
    - `ProcessExited` (bool) – has it finished.
    - `StartDateTime` (`DateTime`) – when the transfer began.
    - `Canceled` (bool) – user canceled via UI.
- Counters:
    - `FilesTransferred` (int).
    - `FoldersCreated` (int).
    - `ErrorCount` (int).
    - `BytesTransferred` (long).
    - `BytesTotal` (long).
    - `BytesFailed` (long) or “FailedBytes” from summary table.
    - `BytesExtra` (long) from ‘Extras’ count.
- Pre-scan data:
    - `PreScanFiles` (int).
    - `PreScanBytes` (long).
    - `PreScanDateTime` (DateTime).
- Derived:
    - `Threads` (int) – from UI; used in ETA heuristics.
    - `SpeedSamples` – rolling buffer of `bytes/sec` samples.
    - `EffectiveSpeed` – computed from `SpeedSamples`.
    - `EtaSeconds` – computed from bytes remaining and `EffectiveSpeed`.

***

## Summary for C\# rewrite

Even without direct file access, the patterns from your description are consistent and form a good spec. For the rewrite you will need:

1. **Settings manager**
    - JSON-backed, tolerant of corruption, with typed defaults and migration if needed.
2. **Core engine**
    - Argument builder for robocopy, fully deterministic.
    - Process launcher with streaming stdout parsing, pause/resume via native calls, and robust exit handling.
3. **Parser**
    - Regex-based line parser for per-file events and summary tables.
    - Statistics aggregator (counters, bytes, extension breakdown, speed sampling, ETA).
4. **UI abstraction**
    - Equivalent of `$app`, `$src`, `$dst`, `$mode`, `$opts`, `$stats`, `$prog`, `$log`, `$btns` using C\# classes and WinUI/WPF/WinForms controls.
    - Theming system with colors and fonts.
5. **Auxiliary tools**
    - Console mode entry point mirroring `Console-Run.ps1`.
    - Watcher/auto-booster (FileSystemWatcher + notifications).
    - Reset-state tool for tests.

Once you have the actual files available in your environment, I can help you build a precise C\# model of each structure and regex.

What would you like next: a proposed C\# class diagram for the core engine and state objects, or a mapping of each described feature into concrete WPF/WinForms components?

---

# Mavericks-RoboCopy — Comprehensive Technical Specification for C\# Rewrite

> **Purpose:** This document is the single-source-of-truth technical specification derived from reading every source file in the `Mavericks-RoboCopy` PowerShell project. Use it to build a functionally identical C\#/WinForms replacement without referencing the original PowerShell sources.

***

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [Settings Persistence](#2-settings-persistence)
3. [Runtime State Object](#3-runtime-state-object)
4. [UI Component Hierarchy \& Data Interfaces](#4-ui-component-hierarchy--data-interfaces)
5. [Mav-AppTemplate Framework](#5-mav-apptemplate-framework)
6. [Theme System (Inferno)](#6-theme-system-inferno)
7. [Font System](#7-font-system)
8. [Robocopy Argument Building](#8-robocopy-argument-building)
9. [Robocopy Output Parsing — All Regex Patterns](#9-robocopy-output-parsing--all-regex-patterns)
10. [Log Tab Routing](#10-log-tab-routing)
11. [Pre-Scan Mechanism](#11-pre-scan-mechanism)
12. [ETA Calculation Formula](#12-eta-calculation-formula)
13. [Speed Sampling Algorithm](#13-speed-sampling-algorithm)
14. [Live Stats Row Updates](#14-live-stats-row-updates)
15. [Progress Bar Logic](#15-progress-bar-logic)
16. [Pause/Resume Mechanism (NtSuspendProcess)](#16-pauseresume-mechanism-ntsuspendprocess)
17. [Cancel Mechanism](#17-cancel-mechanism)
18. [Process Lifecycle \& Background Thread](#18-process-lifecycle--background-thread)
19. [File Type Breakdown Logic](#19-file-type-breakdown-logic)
20. [Completion Logic \& Summary Output](#20-completion-logic--summary-output)
21. [Robocopy Exit Code Interpretation](#21-robocopy-exit-code-interpretation)
22. [Log Files \& Paths](#22-log-files--paths)
23. [Crash Logging](#23-crash-logging)
24. [Console-Run.ps1 — CLI Differences](#24-console-runps1--cli-differences)
25. [Watch-Transfers.ps1 — Auto-Booster Service](#25-watch-transfersps1--auto-booster-service)
26. [Reset-State.ps1 — Test Cleanup Tool](#26-reset-stateps1--test-cleanup-tool)
27. [Tests (Pester) — Behaviors Verified](#27-tests-pester--behaviors-verified)
28. [Recent Paths Store](#28-recent-paths-store)
29. [DPI Awareness Setup](#29-dpi-awareness-setup)
30. [C\# Rewrite — Component Checklist](#30-c-rewrite--component-checklist)

***

## 1. Project Structure

```
Mavericks-RoboCopy/
|-- Mavericks-RoboCopy.ps1       # Main GUI application (~830 lines)
|-- Mav-AppTemplate.psm1         # WinForms layout framework (~2800 lines)
|-- Mav-AppTemplate.psd1         # Module manifest
|-- tools/
|   |-- Console-Run.ps1          # CLI-only robocopy wrapper (no GUI)
|   |-- Watch-Transfers.ps1      # Background transfer booster service
|   |-- Reset-State.ps1          # Test/dev cleanup utility
|   |-- Install-TransferBooster.ps1
|   `-- Remove-TransferBooster.ps1
`-- tests/
    `-- Mavericks-RoboCopy.Tests.ps1  # Pester unit tests
```


***

## 2. Settings Persistence

**File:** `%APPDATA%\\Mavericks-RoboCopy\\settings.json`

Load: if file missing or JSON corrupt, return defaults with empty `Presets` dict.
Save: after every completed transfer, UTF-8 encoding, depth=6.


| Key | Type | Default | Description |
| :-- | :-- | :-- | :-- |
| `LastSource` | string | `""` | Last used source path |
| `LastDest` | string | `""` | Last used destination path |
| `Threads` | int | `16` | `/MT:N` thread count |
| `IncludeSubdirs` | bool | `true` | Whether `/E` is passed |
| `Verbose` | bool | `true` | Whether `/V` is passed |
| `Restartable` | bool | `false` | Whether `/Z` is passed |
| `Excludes` | string | `""` | Comma/semicolon-separated exclude patterns |
| `Prescan` | bool | `false` | (UI-only; pre-scan always runs in code) |
| `OpenDestWhenDone` | bool | `false` | Open Explorer on destination after copy |
| `Presets` | dict | `{}` | Reserved for future preset storage |


***

## 3. Runtime State Object

Reset at the start of each `Run-Robocopy` call.


| Property | C\# Type | Description |
| :-- | :-- | :-- |
| `Process` | `Process` | Running robocopy.exe instance |
| `Started` | `DateTime` | When proc.Start() was called |
| `IsDryRun` | `bool` | True if /L was passed |
| `Cancelled` | `bool` | Set by Cancel button |
| `Paused` | `bool` | True while NtSuspendProcess is active |
| `FilesSeen` | `int` | Live count of successfully transferred files |
| `BytesSeen` | `long` | Live count of bytes transferred |
| `TotalFiles` | `int` | From pre-scan |
| `TotalBytes` | `long` | From pre-scan |
| `InitialEta` | `TimeSpan?` | Heuristic ETA computed from pre-scan |
| `LastTickAt` | `DateTime?` | Time of previous speed sample |
| `LastTickBytes` | `long` | BytesSeen at previous tick |
| `SpeedSamples` | `List<double>` | Rolling window, max 6 entries |
| `LastDest` | `string` | Saved at completion for Open Dest |
| `ExtCounts` | `Dictionary<string,int>` | Extension -> successful file count |
| `ExtBytes` | `Dictionary<string,long>` | Extension -> bytes transferred |
| `FoldersSeen` | `int` | New directories created in destination |
| `FailedFiles` | `int` | Files that hit a copy error |
| `FailedBytes` | `long` | Bytes of failed transfers |
| `ExtFailed` | `Dictionary<string,int>` | Extension -> failed file count |
| `SummaryTotal` | `int` | From robocopy "Files :" summary line |
| `SummaryCopied` | `int` | From robocopy "Files :" summary line |
| `SummaryFailed` | `int` | From robocopy "Files :" summary line |
| `SummarySkipped` | `int` | From robocopy "Files :" summary line |

> **Fallback rule:** `SummaryCopied`/`SummaryFailed` preferred over `FilesSeen`/`FailedFiles` if the summary table line was received.

***

## 4. UI Component Hierarchy \& Data Interfaces

### 4.1 Form (`$app`)

`New-MavForm` — Size: 1280 x 1280. Title: `"Mavericks-RoboCopy"`. Subtitle: `"fast file transfer · pause·resume·throttle · cut+paste support"`. Version: `"v5.0"`.

### 4.2 Source Path Row (`$src`)

`Add-MavPathRow -Title 'SOURCE' -Description 'pick the folder to copy/move FROM'`


| Property | Type | Notes |
| :-- | :-- | :-- |
| `src.TextBox.Text` | string | Current source folder path |
| `src.BrowseButton` | Button | Opens IFileOpenDialog (FolderBrowserDialog fallback) |
| `src.RecentButton` | Button | ContextMenuStrip of recent paths |
| `src.GroupBox` | GroupBox | Outer container |
| `src.Bucket` | `"SOURCE"` | Key for recents store |

- Drag-drop supported (folder auto-fills TextBox)
- On TextBox Leave: if path exists on disk, adds to recents


### 4.3 Destination Path Row (`$dst`)

Identical to `$src`, Title = `"DESTINATION"`, Bucket = `"DESTINATION"`.

### 4.4 Mode Radio Group (`$mode`)

`Add-MavRadioGroup -Title 'Mode'`


| Key | Label | Color | Confirm Dialog |
| :-- | :-- | :-- | :-- |
| `Copy` | `📄 COPY — originals stay` | Text | No |
| `Move` | `✂  MOVE — cut+paste` | Warn (orange) | Yes — warns source files deleted |
| `Mirror` | `🗑 MIRROR — sync, deletes extras` | Bad (red) | Yes — warns dest extras deleted |

Access: `mode.Radios["Copy"].Checked`, `.Move.Checked`, `.Mirror.Checked`

### 4.5 Options Group (`$opts`)

`Add-MavOptionsGroup -Title 'Options' -Height 70`


| Name | Control | Range | Default | Flag |
| :-- | :-- | :-- | :-- | :-- |
| `Threads` | NumericUpDown | 1–128 | 16 | `/MT:N` |
| `Subdirs` | CheckBox | — | true | `/E` |
| `Verbose` | CheckBox | — | true | `/V` |
| `Restartable` | CheckBox | — | false | `/Z` |

### 4.6 Filters Group (`$filt`)

`Add-MavOptionsGroup -Title 'Filters' -Height 70`


| Name | Control | Default | Flag |
| :-- | :-- | :-- | :-- |
| `Excludes` | TextBox (w=560) | `""` | `/XD` or `/XF` per token |
| `Days` | NumericUpDown (0–36500) | 0 | `/MAXAGE:N` if > 0 |
| `IPG` | NumericUpDown (0–9999) | 0 | `/IPG:N` if > 0 |

### 4.7 Post Options Group (`$post`)

`Add-MavOptionsGroup -Title 'After' -Height 70`


| Name | Control | Default | Action |
| :-- | :-- | :-- | :-- |
| `Prescan` | CheckBox | false | UI only; code always pre-scans |
| `OpenDest` | CheckBox | false | Open Explorer on dest after success |

### 4.8 Stats Row (`$stats`)

`Add-MavStatsRow -Captions @('FILES','TOTAL','COPIED','ELAPSED','SPEED','ETA') -Height 80`

Access: `stats.Values["FILES"].Text = "42"`
All 6 value labels: Consolas 11pt Bold, foreground = Ember color.


| Caption | Value During Transfer |
| :-- | :-- |
| FILES | `FilesSeen.ToString()` |
| TOTAL | `FormatBytes(TotalBytes)` |
| COPIED | `FormatBytes(BytesSeen)` |
| ELAPSED | `FormatDuration(Now - Started)` |
| SPEED | Rolling 6-sample avg + "/s", or `"PAUSED"` |
| ETA | Live or `InitialEta + " (est.)"` |

### 4.9 Progress Row (`$prog`)

`Add-MavProgressRow -Height 88`


| Property | Description |
| :-- | :-- |
| `prog.Bar` | ProgressBar, Continuous, 0–100 |
| `prog.Caption` | Label "PROGRESS" |
| `prog.Detail` | `"42/1000 files  ·  4% complete  ·  1.2 GB/30 GB"` |

### 4.10 Tabbed Log Panel (`$log`)

`Add-MavTabbedLogPanel -Height 320 -Tabs @('Full','Simplified','Warnings','Errors')`


| Member | Description |
| :-- | :-- |
| `log.Append(line, color, channels[])` | Append to tab(s) + disk file |
| `log.Clear()` | Clear all tabs + reset count badges |
| `log.SetLogFile(path)` | Set disk log target |
| `log.Export(owner)` | SaveFileDialog to dump Full tab |
| `log.Tabs["Full"]` | RichTextBox — all output |
| `log.Tabs["Simplified"]` | RichTextBox — clean view |
| `log.Tabs["Warnings"]` | RichTextBox — skips/mismatches |
| `log.Tabs["Errors"]` | RichTextBox — copy errors |
| `log.Counts["Errors"]` | int — shown in tab badge `"Errors (3)"` |

### 4.11 Button Bar (`$btns`)

`Add-MavButtonBar` — all buttons accessed as `btns["KEY"]`


| Key | Label | Side | Initial | Color |
| :-- | :-- | :-- | :-- | :-- |
| `Go` | `▶ COPY` | Right | **Enabled** | Accent (red), Primary |
| `DryRun` | `👁 Dry Run` | Right | Enabled | Default |
| `Pause` | `⏸ Pause` | Right | **Disabled** | Warn (orange) |
| `Cancel` | `✕ Cancel` | Right | **Disabled** | Bad (red) |
| `Clear` | `🗑 Clear` | Left | Enabled | Default |
| `Export` | `💾 Export Log` | Left | Enabled | Default |
| `OpenLog` | `📁 Open Log Folder` | Left | Enabled | Default |
| `OpenDest` | `📂 Open Destination` | Left | **Disabled** | Default |

**Soft-disable** = cursor → `Cursors.No`, text color → 50% darkened; clicks are no-ops.

***

## 5. Mav-AppTemplate Framework

### Exported Functions Reference

| Function | Returns | Notes |
| :-- | :-- | :-- |
| `Initialize-MavApp [-Theme Inferno]` | void | DPI setup + assemblies + theme. Must run before any form. |
| `New-MavForm` | `$app` object | Form with header/status/buttonbar/scrollable content |
| `Show-MavApp $app` | void | `Application.Run($app.Form)` |
| `Test-MavFrameworkHealth -RequiredFunctions` | void / throws | Pre-flight check; throws if any function missing |
| `Add-MavPathRow` | `{GroupBox, TextBox, RecentButton, BrowseButton, Bucket}` |  |
| `Add-MavRadioGroup` | `{GroupBox, Radios: hashtable}` |  |
| `Add-MavOptionsGroup` | `{GroupBox, Controls: hashtable, Flow}` |  |
| `Add-MavStatsRow` | `{Panel, Values: hashtable}` |  |
| `Add-MavProgressRow` | `{Panel, Bar, Caption, Detail}` |  |
| `Add-MavTabbedLogPanel` | `{Panel, TabControl, Tabs, TextBox, Append, Clear, SetLogFile, Export, Counts}` |  |
| `Add-MavLogPanel` | `{Panel, TextBox, Append}` | Single-tab version |
| `Add-MavButtonBar` | `hashtable<Key, Button>` | Also stored in `$app.Buttons` |
| `Set-MavButtonReady $btn $bool` | void | Enable / soft-disable |
| `Get-MavButtonReady $btn` | bool | True if button is ready |
| `Set-MavStatus -App -Text -Color` | void | Thread-safe via BeginInvoke |
| `Pick-FolderModern` | string / null | IFileOpenDialog + FolderBrowserDialog fallback |
| `Add-MavRecent -Bucket -Path` | void | Dedupe, max 12, newest-first |
| `Get-MavRecent -Bucket` | string[] |  |
| `Clear-MavRecent [-Bucket]` | void | One bucket or all |

### Layout z-order Rule (critical for Dock=Fill)

WinForms processes Dock in REVERSE z-order (highest index docks first). Always set Fill child to index 0, docked edges to higher indices, then call `PerformLayout()`.

***

## 6. Theme System (Inferno)

Single built-in theme. All values are `System.Drawing.Color`.


| Key | Hex | Usage |
| :-- | :-- | :-- |
| Bg | \#0A0A0A | Form background |
| BgAlt | \#140E0C | Header, button bar, status strip |
| BgPanel | \#1C1210 | GroupBox interiors, input backgrounds |
| BgPanelHi | \#281816 | Hover highlight |
| Border | \#501812 | Button flat borders |
| Text | \#E8E2DA | Primary text |
| TextDim | \#8C7C74 | Secondary/dim text |
| TextFaint | \#5A504C | Very faint text |
| Accent | \#DC2626 | Primary button background |
| AccentDim | \#8C1818 | Version label, divider lines |
| Lava | \#FF5722 | Section headers, icon glyph |
| Ember | \#FF8A1E | Stat values, Recent button, extra-file lines |
| Flame | \#FFC83C | Warm yellow |
| Char | \#3A1C18 | Dark panel variant |
| Good | \#78C864 | Success / transferred files (green) |
| Warn | \#E6B450 | Warnings, paused state (orange-yellow) |
| Bad | \#E65050 | Errors, failed files (red) |

**Header glow:** `LinearGradientBrush(AccentDim -> Lava)`, horizontal, 3px bar at bottom of header.

***

## 7. Font System

| Key | Typeface | pt | Style | Usage |
| :-- | :-- | :-- | :-- | :-- |
| UI | Segoe UI | 9 | Regular | Default form font |
| UIB | Segoe UI | 9 | Bold | Section headers, buttons |
| UITitle | Segoe UI | 18 | Bold | App title |
| UISub | Segoe UI | 9 | Italic | Subtitle, stat captions |
| Mono | Consolas | 9 | Regular | Log RichTextBox, path TextBoxes |
| Stat | Consolas | 11 | Bold | Live stat value labels |


***

## 8. Robocopy Argument Building

Canonical logic (identical in GUI and Console-Run.ps1):

```
args = [
  source.TrimEnd('\\', '/'),
  dest.TrimEnd('\\', '/')
]

IF subdirs:         append "/E"
ALWAYS:             append "/MT:{threads}"
ALWAYS:             append "/R:1", "/W:1", "/NP", "/TEE"
GUI ONLY:           append "/BYTES"
IF verbose:         append "/V"
IF restartable:     append "/Z"
IF mode == Mirror:  append "/MIR"   (XOR with /MOV)
IF mode == Move:    append "/MOV"   (XOR with /MIR)
IF dryRun:          append "/L"
IF days > 0:        append "/MAXAGE:{days}"
IF ipg > 0:         append "/IPG:{ipg}"

FOR each token in Excludes.Split(',', ';'):
  token = token.Trim()
  IF empty: skip
  IF token contains '*' or '?': append "/XF", token
  ELSE:                          append "/XD", token
```

**Argument quoting (GUI only):** Build a single `Arguments` string; wrap each arg in `"..."` if it contains spaces. Do NOT use `ProcessStartInfo.ArgumentList` (unreliable in all target PowerShell versions).

***

## 9. Robocopy Output Parsing — All Regex Patterns

### 9.1 Line Color Assignment

| Regex | Color Key |
| :-- | :-- |
| `^\s*\*EXTRA` | Ember |
| `New File\|^\s*Newer` | Good |
| `Older\|Mismatch\|Skipped` | Warn |
| `Same` | TextDim |
| `ERROR\|FAILED\|Access denied` | Bad |
| (default) | Text |

### 9.2 Log Tab Channel Routing

| Match | Channels |
| :-- | :-- |
| `ERROR\|FAILED\|Access denied\|Cannot access` | Full, Errors, Simplified |
| `Older\|Mismatch\|Skipped\|^\s*\*EXTRA` | Full, Warnings |
| `New File\|^\s*Newer` or any summary/header marker | Full, Simplified |
| Everything else | Full only |

Summary/header markers (also routed to Simplified):
`━{5,}`, `═{5,}`, `Started :`, `Ended :`, `Source :`, `Dest :`, `Files\s*:`, `Bytes\s*:`, `Dirs\s*:`, `Speed\s*:`, `TRANSFER COMPLETE`, `DRY RUN COMPLETE`, `CANCELLED`

### 9.3 Transfer Stats (called on every output line)

**Successful file transfer:**

```
Pattern: ^\s*(?:New File|Newer)\s+([\d,.]+\s*[kKmMgG]?)\s+(.+)$
Group 1: size string (may have k/m/g suffix)
Group 2: file path
Action:  FilesSeen++
         BytesSeen += ParseSize(group1)
         ext = Path.GetExtension(group2).ToLower() || "(no ext)"
         ExtCounts[ext]++
         ExtBytes[ext] += size
```

**Failed copy:**

```
Pattern: ERROR \d+.*(?:Copying File|Creating File|Moving File)\s+(.+)$
Group 1: file path
Action:  FailedFiles++
         ExtFailed[ext]++
```

**New directory:**

```
Pattern: ^\s*New Dir\s
Action:  FoldersSeen++
```

**Robocopy summary table (authoritative counts):**

```
Pattern: ^\s*Files\s*:\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)
Groups:  1=Total, 2=Copied, 3=Skipped, 4=Mismatch, 5=Failed, 6=Extras
Action:  SummaryTotal=G1; SummaryCopied=G2; SummarySkipped=G3; SummaryFailed=G5
```


### 9.4 Pre-Scan Output Parsing

Command: `robocopy.exe {src} NUL /L /E /NFL /NJH /R:0 /W:0 /BYTES`

```
Files:  ^\s*Files\s*:\s*(\d+)\s+   -> TotalFiles = int(G1)
Bytes:  ^\s*Bytes\s*:\s*(\d+)\s+   -> TotalBytes = long(G1)
```


### 9.5 Size String Parser

```
Pattern: ([\d,.]+)\s*([kKmMgG])?
Remove commas; parse as double.
Multiplier: k/K=1024, m/M=1048576, g/G=1073741824, default=1
Return: (long)(num * multiplier)
```


***

## 10. Log Tab Routing

Every `Append(line, color, channels[])` call:

1. Appends to each named tab's RichTextBox
2. Updates that tab's count badge: `"Errors"` -> `"Errors (3)"`
3. Writes line to disk log file (if `SetLogFile` was called) — unconditionally, regardless of channels

Channel assignment is determined by `ChannelsForLine(line)` (§9.2).

***

## 11. Pre-Scan Mechanism

Pre-scan **always runs** at the start of every transfer (the Prescan checkbox only affects UI display; `PreScan-Source` is unconditionally called).

**Command:** `robocopy.exe {source} NUL /L /E /NFL /NJH /R:0 /W:0 /BYTES`

- `/L` = list only, no actual copy
- `NUL` = dummy destination
- `/NFL /NJH` = suppress per-file and header output (summary lines only)
- `/R:0 /W:0` = fail fast

**Log output during pre-scan (Full + Simplified tabs):**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ (90 chars)
Pre-scanning {source} for size + file count…
Pre-scan: {N} files · {size} total
Initial ETA estimate (with /MT:{N}, baseline 50 MB/s × thread factor): {H:MM}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ (90 chars)
```

On failure: logs `"Pre-scan failed: {msg} (continuing anyway, ETA will be unavailable)"` to Full + Warnings tabs. Transfer continues regardless.

**Returns:** `{ Files: int, Bytes: long }`

***

## 12. ETA Calculation Formula

### Initial ETA (heuristic, computed before transfer starts)

```
thread_factor  = 1.0 + (0.6 * Math.Log10(Math.Max(1, threads)))
effective_MBps = 50.0 * thread_factor        // 50 MB/s = USB3/SATA SSD baseline
bps            = effective_MBps * 1048576
secs           = totalBytes / bps
InitialEta     = TimeSpan.FromSeconds(Math.Ceiling(secs))
```

Example — 16 threads:

- `thread_factor = 1 + 0.6 * 1.204 = 1.722`
- `effective = 50 * 1.722 = 86.1 MB/s`

Display: `FormatDuration(InitialEta) + " (est.)"` — suffix signals it is a guess.

### Live ETA (updated every 300ms during transfer)

```
remaining = TotalBytes - BytesSeen
ETA       = TimeSpan.FromSeconds(Math.Ceiling(remaining / rollingAvgBps))
```

Falls back to `InitialEta` display if `rollingAvgBps == 0` or no pre-scan ran.

***

## 13. Speed Sampling Algorithm

- UI timer fires every **300ms**
- On each tick:

1. `delta = BytesSeen - LastTickBytes`
2. `dt = (DateTime.Now - LastTickAt).TotalSeconds`
3. If `dt > 0`: append `delta / dt` to SpeedSamples
4. Trim SpeedSamples to last **6 entries** (RemoveAt(0) while Count > 6)
5. `speedBps = SpeedSamples.Average()`
- Display: `FormatBytes((long)speedBps) + "/s"`
- When paused: display `"PAUSED"` regardless of computed speed

***

## 14. Live Stats Row Updates

Timer fires every 300ms. Guard: only update while `State.Process != null && !State.Process.HasExited`.


| Label | Value |
| :-- | :-- |
| FILES | `State.FilesSeen.ToString()` |
| TOTAL | `FormatBytes(State.TotalBytes)` (or `"—"` if zero) |
| COPIED | `FormatBytes(State.BytesSeen)` |
| ELAPSED | `FormatDuration(DateTime.Now - State.Started)` |
| SPEED | Rolling avg + "/s" or `"PAUSED"` |
| ETA | Live formula (§12) or `InitialEta + " (est.)"` |


***

## 15. Progress Bar Logic

- Range: 0–100, `ProgressBarStyle.Continuous` (no marquee)
- Update: `Math.Min(100, (int)((BytesSeen / (double)TotalBytes) * 100))` — only if `TotalBytes > 0`
- Detail label: `"{FilesSeen}/{TotalFiles} files  ·  {pct}% complete  ·  {FormatBytes(BytesSeen)}/{FormatBytes(TotalBytes)}"`
- On completion (exit ≤ 7): force bar to 100
- On idle/clear: bar = 0, detail = `"idle"`

***

## 16. Pause/Resume Mechanism (NtSuspendProcess)

### P/Invoke (ntdll.dll)

```csharp
[DllImport("ntdll.dll")]
public static extern int NtSuspendProcess(IntPtr processHandle);

[DllImport("ntdll.dll")]
public static extern int NtResumeProcess(IntPtr processHandle);
```


### Pause Flow

1. User clicks Pause button (enabled only during active non-dry-run transfer)
2. `NtSuspendProcess(State.Process.Handle)` — suspends ALL threads of robocopy.exe
3. `State.Paused = true`
4. Button text: `"⏸ Pause"` → `"▶ Resume"`
5. Status bar: `"PAUSED — click Resume"` (Warn color)
6. SPEED stat: `"PAUSED"`

### Resume Flow

1. User clicks same button (now labeled `"▶ Resume"`)
2. `NtResumeProcess(State.Process.Handle)`
3. `State.Paused = false`
4. Button text: `"▶ Resume"` → `"⏸ Pause"`
5. Status bar: `"Resumed."` (Lava color)

### Cancel-While-Paused

Must resume first: `NtResumeProcess(handle)`, then `Process.Kill(entireProcessTree: true)`.

### Form-Close-While-Paused

Same: resume, then kill, inside FormClosing handler.

***

## 17. Cancel Mechanism

1. User clicks Cancel button (enabled only when process is running)
2. `State.Cancelled = true`
3. If `State.Paused`: call `NtResumeProcess` first
4. `State.Process.Kill(true)` — kills process tree
5. Status bar: `"Cancelling…"` (Warn color)
6. Completion handler: sets TAG = `"CANCELLED"` in summary header

***

## 18. Process Lifecycle \& Background Thread

### Why a Background Thread?

`Application.Run()` blocks the UI thread. `Process.OutputDataReceived`/`ErrorDataReceived` handlers run on thread-pool threads and must enqueue output for the UI timer to drain safely on the UI thread.

### C\# Implementation Pattern

```csharp
// Shared: background thread fills, UI timer drains
var outputQueue = new ConcurrentQueue<string>(); // prefix "O:" or "E:"
volatile bool done = false;
int exitCode = -1;

var psi = new ProcessStartInfo {
    FileName = "robocopy.exe",
    Arguments = BuildQuotedArgString(rcArgs),   // wrap spaces in "..."
    RedirectStandardOutput = true,
    RedirectStandardError  = true,
    UseShellExecute        = false,
    CreateNoWindow         = true,
    StandardOutputEncoding = Encoding.UTF8
};

var proc = new Process { StartInfo = psi, EnableRaisingEvents = true };
proc.OutputDataReceived += (s, e) => { if (e.Data != null) outputQueue.Enqueue("O:" + e.Data); };
proc.ErrorDataReceived  += (s, e) => { if (e.Data != null) outputQueue.Enqueue("E:" + e.Data); };

proc.Start();
proc.BeginOutputReadLine();
proc.BeginErrorReadLine();

Task.Run(() => {
    proc.WaitForExit();
    Thread.Sleep(500);    // flush buffered async events
    exitCode = proc.ExitCode;
    done = true;
});

// UI Timer (300ms):
uiTimer.Tick += (s, e) => {
    while (outputQueue.TryDequeue(out string raw)) {
        bool isErr = raw.StartsWith("E:");
        string line = raw.Substring(2);
        Color c = isErr ? theme.Bad : ColorForLine(line);
        string[] ch = isErr ? new[]{"Full","Errors"} : ChannelsForLine(line);
        logPanel.Append(line, c, ch);
        UpdateTransferStats(line);
    }
    if (done && outputQueue.IsEmpty && !completionFired) {
        completionFired = true;
        HandleCompletion(exitCode);
    }
    // Also update live stats if still running...
};
```

**Disposal:** After completion, stop the UI timer, dispose the `Process` object. No runspace/thread needs explicit disposal (Task completes naturally).

***

## 19. File Type Breakdown Logic

### Tracking (during transfer)

- On successful transfer: `ExtCounts[ext]++; ExtBytes[ext] += size`
- On failed copy: `ExtFailed[ext]++`
- Extension: `Path.GetExtension(filePath).ToLower()` — empty → `"(no ext)"`


### Post-Completion Display

Written to Full and Simplified tabs:

```
────────────────────────────────────────────────────
  EXT          FILES      DATA MOVED
────────────────────────────────────────────────────
  MP4             42      12.3 GB
  JPG            123       4.1 GB  (2 failed)
  (no ext)         5         800 KB
────────────────────────────────────────────────────
```

**Algorithm:**

1. Sort `ExtCounts` by value descending
2. Show top 15 extensions
3. Row format: `{ext.TrimStart('.').ToUpper(),-12}  {count,6}   {FormatBytes(bytes),12}` + optional `"  ({N} failed)"` suffix
4. After top-15 loop: show extensions that ONLY appear in `ExtFailed` (never in `ExtCounts`) with `"— all failed"` in data column, color = Bad
5. In Simplified tab only: if `ExtCounts.Count > 15`, append `"… and N more type(s) — see Full tab"`

***

## 20. Completion Logic \& Summary Output

### Trigger

`HandleCompletion()` called when: `done == true AND outputQueue.IsEmpty AND !completionFired`
Called from UI timer tick → always on UI thread, no Invoke needed.

### TAG Values

| Condition | TAG |
| :-- | :-- |
| `State.Cancelled` | `CANCELLED` |
| `State.IsDryRun` | `DRY RUN COMPLETE` |
| Normal | `TRANSFER COMPLETE` |

### copiedCount / failedCount Selection

```csharp
int copiedCount = (State.SummaryCopied > 0) ? State.SummaryCopied : State.FilesSeen;
int failedCount = (State.SummaryCopied > 0) ? State.SummaryFailed : State.FailedFiles;
```


### Summary Written to Log (Full + Simplified tabs)

```
[blank line]
══════════ (90 '=' chars)
  {TAG}  ·  {FormatDuration(elapsed)}  ·  exit {code}
  {verdictString}

  COPIED    {copiedCount} file(s)   {FormatBytes(BytesSeen)}[  of {FormatBytes(TotalBytes)} total]
  FAILED    {failedCount} file(s)          [only if > 0]
  SKIPPED   {SummarySkipped} file(s)  (already up-to-date or excluded)  [only if > 0]
  DIRS      {FoldersSeen} new folder(s) created                         [only if > 0]

  {file type breakdown table}

  Log: {CurrentLogFile}
══════════ (90 '=' chars)
```


### Post-Completion Actions (ordered)

1. `statsTimer.Stop()`
2. Set status bar text + color from exit code verdict
3. Force `prog.Bar.Value = 100` if `exit <= 7`
4. Update `prog.Detail.Text`
5. If successful and not cancelled: `SystemSounds.Asterisk.Play()`
6. If `OpenDestWhenDone` \&\& dest exists: `Process.Start("explorer.exe", dest)`
7. `RecentsStore.Add("SOURCE", src)` and `RecentsStore.Add("DESTINATION", dest)`
8. Save all settings to `settings.json`
9. `State.LastDest = dst.Text`
10. `Set-MavButtonReady(btnGo, true); Set-MavButtonReady(btnDryRun, true)`
11. `Set-MavButtonReady(btnPause, false); Set-MavButtonReady(btnCancel, false)`
12. `btnPause.Text = "⏸ Pause"`
13. `Set-MavButtonReady(btnOpenDest, Directory.Exists(dst.Text))`
14. `form.Cursor = Cursors.Default`
15. Dispose `Process` object

***

## 21. Robocopy Exit Code Interpretation

| Exit Code | Verdict String | Color | Triggers Sound + OpenDest |
| :-- | :-- | :-- | :-- |
| 0 | `Already in sync — nothing to copy.` | Warn | No |
| 1 | `Files copied successfully.` | Good | **Yes** |
| 2 | `Done — extra files exist in destination.` | Warn | Yes |
| 3 | `Files copied + extras in destination.` | Good | Yes |
| 4–7 | `Done with some mismatches/extras (exit N).` | Warn | Yes |
| ≥ 8 | `FAILED (exit N).` | Bad | No |


***

## 22. Log Files \& Paths

| File | Full Path | Created By |
| :-- | :-- | :-- |
| Transfer log | `%LOCALAPPDATA%\\Mavericks-RoboCopy\\logs\\transfer-{yyyyMMdd-HHmmss}.log` | New file per run via SetLogFile |
| Crash log | `%LOCALAPPDATA%\\Mavericks-RoboCopy\\crash.log` | Appended on any unhandled exception |
| Sessions log | `%LOCALAPPDATA%\\Mavericks-RoboCopy\\sessions.log` | Appended at every app launch (first line of code) |
| Booster log | `%LOCALAPPDATA%\\Mavericks-RoboCopy\\booster.log` | Watch-Transfers.ps1 — INFO/WARN/ERROR lines |
| Boost rc logs | `%LOCALAPPDATA%\\Mavericks-RoboCopy\\logs\\boost-{yyyyMMdd-HHmmss}.log` | Per boost invocation |
| Settings | `%APPDATA%\\Mavericks-RoboCopy\\settings.json` | On every completed transfer |
| Recents | `%APPDATA%\\Mav-AppTemplate\\recents.json` | On browse/Leave/select events |

**Sessions log format:** `{yyyy-MM-dd HH:mm:ss}  PID={n}  PSv={ver}  exe={path}`

***

## 23. Crash Logging

**Sessions log** written as the **absolute first action** on launch — before exception handlers, before UI init. Proves the process launched even when it dies silently.

### C\# Equivalent Setup

```csharp
// In Main() before anything else:
var sessLog = Path.Combine(Environment.GetFolderPath(
    Environment.SpecialFolder.LocalApplicationData),
    "Mavericks-RoboCopy", "sessions.log");
Directory.CreateDirectory(Path.GetDirectoryName(sessLog));
File.AppendAllText(sessLog,
    $"{DateTime.Now:yyyy-MM-dd HH:mm:ss}  PID={Environment.ProcessId}\n");

// Exception handlers:
Application.ThreadException += (s, e) => LogCrash("UI thread", e.Exception);
AppDomain.CurrentDomain.UnhandledException += (s, e) =>
    LogCrash("AppDomain", e.ExceptionObject as Exception);
```


### Crash Log Format

```
=== {yyyy-MM-dd HH:mm:ss} · {where} ===
{ExceptionType.FullName}: {Message}
{StackTrace}

```

**Show MessageBox** after writing crash log (user sees path to the log file).
**Do NOT re-throw** — stops cascading null-reference echoes of the first real error.

***

## 24. Console-Run.ps1 — CLI Differences

A CLI-only robocopy wrapper for testing the transfer logic without WinForms.


| Aspect | GUI (Mavericks-RoboCopy.ps1) | CLI (Console-Run.ps1) |
| :-- | :-- | :-- |
| WinForms | Yes | **No** |
| Settings.json | Read + write | **None** |
| `/BYTES` flag | Always added | **Not added** |
| Process launch | Async + ConcurrentQueue | Direct blocking call |
| Output routing | Log tabs + color | **stdout only** |
| Live stats | Yes | **No** |
| Progress bar | Yes | **No** |
| Log files | Yes | **No** |
| Pre-scan | Always | **No** |
| ETA | Yes | **No** |

**CLI Parameters:**

```
-Source         (Mandatory) string
-Destination    (Mandatory) string
-Mode           Copy | Move | Mirror  (default: Copy)
-Threads        int    (default: 16)
-Subdirs        switch
-VerboseLog     switch
-Restartable    switch
-DryRun         switch
-Excludes       string  (comma/semicolon separated)
-Days           int    (default: 0)
-IPG            int    (default: 0)
```

**Output:** Prints full `robocopy` command in cyan before executing. After exit, prints verdict in green (exit ≤ 7) or red (exit > 7).

***

## 25. Watch-Transfers.ps1 — Auto-Booster Service

**Role:** Standalone background service (installed via scheduled task on user login).
**Script:** `tools/Watch-Transfers.ps1`

### Main Poll Loop (default: every 30 seconds)

```
1. If a boost process is running: check if HasExited; if done, reset state.
2. Skip if any robocopy.exe process is already running (GUI is active).
3. Detect signals:
   a. WMI PerfCounter: drives writing > ThresholdMBps (default 10 MB/s)
      -> hotDrives = list of drive letters above threshold
   b. EnumWindows over explorer.exe PIDs: any visible title matching
      ^(Copying|Moving|File Operation)
      -> dialogPresent = true/false
4. signalActive = (hotDrives.Count > 0) OR dialogPresent
5. IF signalActive:
     pendingCount++
     IF pendingCount >= 2 (two consecutive polls = confirmed):
       a. Read LastSource/LastDest from settings.json
       b. destDrive = Path.GetPathRoot(LastDest).TrimEnd('\\').ToUpper()
       c. driveMatches = (hotDrives.Count == 0) OR (destDrive in hotDrives)
       d. IF driveMatches AND Directory.Exists(LastSource):
            Launch robocopy boost
            Send toast notification
       e. ELSE: Send toast "Large Transfer Detected — Open Mavericks-RoboCopy"
       f. pendingCount = 0
6. IF no signal: reset pendingCount = 0
```


### Boost Robocopy Args

```
robocopy.exe {src} {dst} /E /MT:16 /R:0 /W:0 /NP /BYTES /TEE /UNILOG+:{boostLogFile}
```

**Note:** `/R:0 /W:0` = no retries (skip locked files immediately). Unlike the main app's `/R:1 /W:1`.

### Win32 Interop (user32.dll)

```csharp
[DllImport("user32.dll")] bool EnumWindows(EnumWindowsProc fn, IntPtr lp);
[DllImport("user32.dll")] int GetWindowText(IntPtr h, StringBuilder s, int n);
[DllImport("user32.dll")] uint GetWindowThreadProcessId(IntPtr h, out uint pid);
[DllImport("user32.dll")] bool IsWindowVisible(IntPtr h);
```

Enumerate all visible windows of all `explorer.exe` PIDs, collect titles matching `^(Copying|Moving|File Operation)`.

### Toast Notification

Uses Windows Runtime `Windows.UI.Notifications.ToastNotificationManager`.
Best-effort — wrapped in try/catch, silently swallowed on failure.

***

## 26. Reset-State.ps1 — Test Cleanup Tool

**Usage:**

```
.\Reset-State.ps1               # wipe logs + settings
.\Reset-State.ps1 -KeepSettings # wipe logs only
```

**Files deleted:**

- `%LOCALAPPDATA%\\Mavericks-RoboCopy\\crash.log`
- `%LOCALAPPDATA%\\Mavericks-RoboCopy\\sessions.log`
- `%LOCALAPPDATA%\\Mavericks-RoboCopy\\logs\\*` (all transfer logs)
- `%APPDATA%\\Mavericks-RoboCopy\\settings.json` (unless `-KeepSettings`)

***

## 27. Tests (Pester) — Behaviors Verified

**Runner:** `Invoke-Pester tests\Mavericks-RoboCopy.Tests.ps1 -Output Detailed`

Tests use an inline `Build-RobocopyArgsTest` function (identical to `Console-Run.ps1`). No GUI or module dependency required.

### Describe: Build-RobocopyArgs

| Test | Assertion |
| :-- | :-- |
| Safety flags | `/R:1`, `/W:1`, `/NP`, `/TEE` always present |
| Strip trailing `\` from source | `args[0]` = path without `\` |
| Strip trailing `\` from destination | `args[1] |

