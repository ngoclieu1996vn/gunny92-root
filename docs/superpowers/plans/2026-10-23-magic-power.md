# Experimental magic fight power

Goal: retain legacy fight power and HP; add the user's estimated magic contribution only for explicitly allowed test players. User approved this approach. This is not the official Zing formula and does not implement magic combat damage or missing stat-producing systems.

Design: helper in the compatibility assembly, injected immediately before legacy FightPower is assigned to PlayerInfo (after overflow guard). Use the existing computed ST local, never call GetBaseAttack twice. No changes to rewards, combat damage or stat persistence. Default off; explicit test allowlist required. Default supported ST interval 800–1300, reflecting supplied observations. Formula: floor((9.7662e-9*ST^3+0.33)*(max(0,MA)+max(0,MR))); saturate final int. Read current server property totals plus separately stored ExplorerManual magic contributions; absent sources mean zero, never invent stats.

Execution: use executing-plans inline in isolated gameSrc worktree; final independent review as required by requesting-code-review.

- [x] Add failing numerical and gating tests (equal MA/MR, bounded ST, invalid inputs, saturation, baseline preservation).
- [x] Implement helper and runtime source aggregation; add patched-IL hook regression and supported build integration.
- [x] Run full compatibility pipeline, review, address findings.
- [x] Deploy Road DLL/helper with backup; enable only AIProbe ID228. Verify actual Flash login and unchanged zero-magic baseline. Nonzero increments verified by hook fixture; do not edit live stats or spend resources to simulate them.
- [x] Document limitations/config/recovery, merge approved work and push task files; update AI_HANDOFF.md.

Ruling: current user approval authorizes routine worktree/build/deployment already established in handoff; no new permission round. Keep configuration keys local. Rollout remains limited to test account until independent Zing samples validate the formula and supported input sources.

Steering: user reported incorrect HP/MA/MR in bag/character attributes. Packet67 legacy writer lacks king grade, magic totals and long display-power fields; packet164 is severely shorter than the current reader. Fix both protocols before enabling the experimental coefficient. Packet74 other-player equipment inspection remains a separate legacy schema and must not be described as fixed without testing. The experiment stays off for all real players.

Evidence: numerical and public packet tests first failed on absent helpers. Packet164 actual reader first failed at legacy byte152; new response consumes exact810 bytes. Full compatibility pipeline and actual patched public-writer/AI228 source fixture passed. No live stats edited for testing.
