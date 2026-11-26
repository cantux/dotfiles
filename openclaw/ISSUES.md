# Ten issues, with their proposed resolutions

This file holds the ten findings of a review written on 2026-11-06, with the proposed resolution of each; none is applied. Section A introduces every term before it is used, and section B uses them. The measurements come from `~/Projects/ai/cloud_inference_provider/evidence/openclaw_phases.md` and `~/Projects/ai/cloud_inference_provider/OPENCLAW_COST.md`.

## A. Terms

1. **Model.** A model is a program that reads text and writes text in reply. The models used here come from three companies, called providers: Anthropic makes the Claude models, among them Opus 5.5, Sonnet 5.5 and Fable 5.1; Google makes the Gemini models; OpenAI makes the GPT models.
2. **Runtime.** A runtime is the program through which a model is reached. This computer has three: the Claude command-line tool for Anthropic models, the Antigravity command-line tool for Google models, and the Codex tool for OpenAI models. A model works on this computer through tool calls: requests, written in a fixed format, that the runtime run a command, or read or write a file, on the model's behalf and hand the result back.
3. **Token.** A token is the unit in which model text is counted, roughly a short word. Input tokens are the text a model reads; output tokens are the text it writes, including the private reasoning it writes before answering. Cost and rate limits are counted in tokens.
4. **Usage.** Usage is the token count a runtime reports after a model has worked. The Antigravity runtime reports no usage, so work done through it cannot be counted.
5. **OpenClaw.** OpenClaw is the program on this computer that starts models through runtimes, keeps their conversations, and records what they did.
6. **Agent.** An agent is a named role that OpenClaw can start. An agent has one model and a working folder, which is the folder in which it starts.
7. **Role file and workspace.** A role file is a text file, named SOUL.md, that tells an agent its job, its procedure and the files it must produce. Each agent owns a folder, called its workspace, that holds its role file.
8. **Allow-list and fallbacks.** An agent's allow-list is the set of models it is permitted to use. Its fallbacks are an ordered list of models from the allow-list; when the first model fails, OpenClaw retries the same task with the next one. For the agents that run on Opus 5.5, the first fallback is Sonnet 5.5, a smaller Anthropic model.
9. **Session, turn and context.** A session is one conversation of one agent, from its first message to its final reply. A turn is one reply of the model within a session. The context of a turn is all the text the model reads to produce that turn, which is the whole conversation so far; the peak context of a session is the largest context any of its turns reached.
10. **Pipeline.** The pipeline is a fixed sequence of phases that turns one written task into a working software project. The phases are listed in term 16, after the words needed to describe them.
11. **Manager, workers and contract section.** The manager is the agent, named pipeline_manager, that runs the pipeline: it starts the other agents, waits for their replies and records the results. It does no research, design or coding itself. A worker is any agent the manager starts to do one job in one phase. Every worker's role file ends with the same section, called the contract section, which holds the rules that apply to all workers alike.
12. **Spawn and model parameter.** A spawn is the manager starting a worker session with a task message. The manager may name a model in the spawn; that name is the model parameter. Without a model parameter, OpenClaw uses the worker's own model and its fallbacks.
13. **Run, run directory and run root.** A run is one execution of the pipeline for one task. The run directory is the folder that holds every file of one run; workers communicate only by writing files into it and by their final reply to the manager. The run root is the folder that holds all run directories. Four runs took place on 2026-10-18 and 19; run-004 is the only one that reached the last phase, and every number below comes from it. The run root was deleted on 2026-10-27.
14. **State file and state contract.** The state file is the manager's ledger, named state.md, inside the run directory. It has four headings, DONE, WIP, BLOCKED and QUEUE, and the manager updates it after every worker result. The section of the manager's role file that says how the state file is kept is called the state contract.
15. **Family.** A family is the set of worker agents that share one provider. The pipeline has three families, named gemini, fable_5_1 and codex. In every phase where the families work side by side, each family has one agent for that phase's role; a role that only one worker performs has an agent in some families only. In run-004 only the gemini and fable_5_1 families took part, because the codex family could not be started.
16. **Phases and roles.** Stage 0: the manager asks you questions about the goal of the task and writes the clarified task, a document holding the agreed goals, the facts about the computer, and the open decisions left for research. Phase 1: one researcher per family searches the web for existing solutions. Phase 2: one research merger joins the research reports into one document. Phase 3: one designer per family writes several designs, where a design is a document that describes one way to build the solution. Phase 4: one evaluator per family writes objections to the other families' designs and tests them. Phase 5: one implementor per family builds a design and examines the other families' builds. Phase 6: one implementation merger assembles the final project from the builds.
17. **Design.** A design describes its components, its failure modes, which are the ways it can fail, its verification plan, which is how to show on this computer that it works, and its trade-offs. Each family ends phase 4 naming one of its designs its current best.
18. **Critique and experiment.** A critique is a numbered objection to one design, written by an evaluator of another family. It carries a severity, blocking, significant or minor, and evidence: a file and line, a web address, or an experiment. An experiment is a command the evaluator runs on this computer to settle a critique, with its predicted result written down before the run.
19. **Disposition.** A disposition is the designer's recorded answer to one critique: fixed, together with the revised design; rejected, together with evidence; or experiment, naming the experiment that must decide it.
20. **Open, settled and standing.** A critique is open until its disposition is accepted by the evaluator. It is settled when the evaluator accepts the disposition. It is standing when designer and evaluator disagree and both leave the disagreement recorded without further action; a standing critique no longer counts as open.
21. **Round and the end of phase 4.** A round is one cycle of phase 4: every evaluator writes its critiques, then every designer answers with dispositions and revised designs. Rounds are numbered from 1. Phase 4 runs at most four rounds: after the evaluators' step of round 4, phase 4 ends whatever is still open, so no designer answer follows round 4. Phase 4 also ends after any earlier round as soon as no blocking or significant critique is open.
22. **Planning step of phase 4 and of phase 5.** Phase 4 and phase 5 each open with a planning step that the manager runs before the phase's own work. In it each worker of the phase writes a plan of what it will do, then critiques the other families' plans, then revises its own plan if it received a blocking critique. Each of the three parts is one spawn per worker, so a planning step costs three spawns per worker before the phase's own work starts.
23. **Stage 5a, stage 5b, review and defect.** Phase 5 has two stages. In stage 5a each implementor builds its own family's current-best design. In stage 5b each implementor copies the other families' builds, runs them, and writes a review of each. A review lists defects, which are errors the reviewer reproduced by running the build, each with the command that shows it.
24. **Implementation merger.** The implementation merger keeps a part of a build in the final project only if a review executed that part successfully, and it records why each part was kept or rejected.
25. **File gate.** The file gate is the rule that, within one phase, a worker may not read another worker's files until the manager's task message says that the gate is open.
26. **Evidence labels.** Every factual claim a worker makes carries one of two labels: executed, meaning a command was run and its output captured, or read, meaning the claim was taken from a document. Only executed claims count as verified.
27. **Missing-workers rules, stop and operator.** The manager has four rules for a worker that cannot be started or returns nothing. Rule 1: record the exact error, retry once, and do not substitute another model. Rule 2: exclude that worker for the rest of the run. Rule 3: a phase that runs its workers in parallel needs at least two of them; with fewer, stop the run and write a report. Rule 4: a worker that returns no output counts as failed after one recovery attempt. A stop is the halt under rule 3. The operator is you, the person who starts runs; after a stop the operator must intervene before the run continues.
28. **Alternate agent.** An alternate agent is a second agent, in another family, prepared for a role that only one worker performs, so that the role can still run when the first agent's family cannot. The pipeline has one: research_merger_gemini beside research_merger_codex for the phase 2 role. The manager's role file lists the alternate as permitted but names only the codex merger in its procedure.
29. **Host, container, cluster, rootless container runtime, kernel and BPF mount.** The host is this computer. A container is a program packaged together with the files it needs, so that it runs the same way on any machine. The task asked for the software to run on a cluster: a set of machines, real or simulated, managed by Kubernetes, a system that runs containers across machines. A container runtime is the program that starts containers; it is rootless when it runs without administrator rights, as it does on this host. The kernel is the core of the operating system, the part that controls the hardware and decides what programs may do. The BPF mount is a file system that the kernel provides for programs that extend it; the cluster's networking component must attach it, and attaching it needs administrator rights.
30. **Acceptance criteria and line budget.** The acceptance criteria are the conditions, agreed in Stage 0 and written in the clarified task, under which the result counts as finished. The line budget is the limit on authored lines of code that a design promises, because the task asked for the shortest program.
31. **Signals and observability.** Signals are the measurements a running system produces about itself, such as counters, log lines and records of each request's path through the system. Observability is the ability to tell from the signals what the system is doing. The task made observability the most important property of the result.
32. **Hash and completion marker.** A hash is a short fingerprint computed from a file's content; it changes whenever the content changes. A completion marker is a proposed new kind of file that names a worker's output files and gives the hash of each.
33. **Identity probe.** An identity probe is a one-line test message to an agent that asks it to state its name and the model it runs on, without writing any file.
34. **Closure ledger and verification scripts.** The closure ledger is a script that counts, for each design, the critiques raised, fixed, settled, standing and open across all rounds; the manager wrote it during run-004. Verification scripts are scripts that check that a phase's required files exist and are complete.
35. **Partial-run rule.** The partial-run rule is the manager's rule that an existing run directory is resumed at the first phase whose files are incomplete, keeping every existing file.
36. **Generators.** The generators were two scripts in the run root that produced every role file and the list of agents from one table. They were deleted with the run root; the role files themselves survive in the workspaces.
37. **OpenAI route.** The OpenAI route is the connection from OpenClaw to OpenAI's models through the Codex runtime. It needs a login, and the login has expired.

## B. Findings

Each finding except the ninth has three parts: the issue, the proposed resolution, and where the change would be written. Measured output tokens of run-004 means the output tokens of the manager and of the fable_5_1 family's workers together; the gemini family's tokens are unknown because its runtime reports no usage.

### 1. Critiques raised in round 4 of phase 4 receive no answer

Issue. In run-004 the evaluators raised 19 new critiques against the gemini family's designs in round 4 of phase 4. Because no designer answer follows round 4, those 19 critiques were never answered; they make up 19 of the 24 critiques that were still open when phase 4 ended. The fable_5_1 family's designs had no open critique after round 3, so for them round 4 produced nothing.

Resolution. Make round 4 of phase 4 a settlement round: in it the evaluators only re-examine existing dispositions and run the experiments still pending, and they raise no new critiques. The early end of phase 4, when no blocking or significant critique is open, stays as it is.

Where. The manager's role file, in the phase 4 procedure; the evaluator's role file, in its round procedure section.

### 2. The planning steps of phases 4 and 5 consume a quarter of the run

Issue. The two planning steps together produced 24.7% of the measured output tokens of run-004. The planning step of phase 5 took 199 turns, more than the 137 turns of stage 5a, which it was meant to prepare. Its critique part also failed twice by timeout, meaning the runtime gave up waiting for the model's reply, and those failures caused one of the three stops of run-004 described in finding 4. The planning step of phase 5 did find blocking critiques in both plans, so it changed what was built. For the planning step of phase 4 the record shows no effect on the rounds that followed.

Resolution. Remove the planning step of phase 4. Keep the planning step of phase 5 but with two spawns per worker instead of three: write the plan, then critique the other plans. A blocking plan critique is handed into stage 5a as a known defect the implementor must resolve, instead of a third spawn to revise the plan. Expected saving: about 15% of a run's output tokens.

Where. The manager's role file, in the first step of the phase 4 procedure and the first step of the phase 5 procedure; the evaluator's role file, in its evaluation plan section; the implementor's role file, in its implementation plan section.

### 3. A fallback re-ran work that was already finished

Issue. Twice in run-004 a runtime reported a failure after the worker had already written its output files: the Claude runtime reported that it could not read the worker's final reply, and the Antigravity runtime reported a malformed tool call. OpenClaw treated each as a failed session and started the first fallback, Sonnet 5.5, on the same task. The fallback repeated the finished work for 116 turns in total before the manager noticed and cancelled it. Separately, missing-workers rule 1 forbids substituting another model, while the fallbacks do exactly that; the two texts contradict each other.

Resolution. Every worker writes a completion marker as its last action. A worker that starts and finds its own completion marker already present replies "already complete" and stops. The manager counts a step as failed only when the completion marker is absent. Rewrite rule 1 so that a fallback on the same family's allow-list is permitted and is recorded with the model that actually ran, that a model from another family stays forbidden for the roles several families perform in parallel, and that the alternate agent is the permitted substitute for a role a single worker performs.

Where. The contract section shared by every worker role file; the manager's role file, in missing-workers rules 1 and 4.

### 4. One runtime stopped the run three times

Issue. Each time a gemini family worker failed to spawn or returned nothing, rule 3 stopped run-004, three times in all. After each stop you restarted OpenClaw, changed which model an agent was bound to, or re-authorised a spawn by hand. The workers and the manager were busy for 12 of the run's 24 hours; the rest was waiting for you. The role files also hard-code "three implementations" and "six reviews"; when only two families ran, the manager had to correct those numbers in its task message.

Resolution. The manager spawns without a model parameter, so that OpenClaw walks the fallback list itself; this is the change that unblocked run-004 on 2026-10-19. On a spawn failure the manager retries once; for a role a single worker performs it then spawns the alternate agent if one exists; only then does it apply rule 3. Before phase 1 the manager sends an identity probe to every worker and records the answers in the state file. In the role files, "three" and "six" become "every other family".

Where. The manager's role file, in the phase 1 procedure and the missing-workers rules; the implementation merger's and the implementor's role files.

### 5. Executed evidence stops at the host

Issue. No run ever executed its result on a cluster. Every attempt to start the cluster's networking component failed at the BPF mount, because the host's container runtime is rootless. So every claim about behaviour on the cluster carries the label read, never executed. In addition, every role file contains a fixed sentence listing what the host has and lacks; it was written once and is now out of date.

Resolution. Each design states the facilities its own verification plan needs. The facts about the computer in the clarified task are produced by a probe script, which is a script that measures the host and writes down what it finds, replacing the fixed sentence in the role files. Before phase 4 the manager provides the facilities the host can provide, records those it cannot, and asks you only about the ones the host lacks. Which technology to deploy and how to verify it remain decisions of the designs; the pipeline only guarantees that the label executed is attainable for what they chose.

Where. The manager's role file, in the Stage 0 procedure; the designer's role file, in the part of its procedure that lists what a design must contain; the fixed host sentence in every worker role file, replaced by a reference to the probe script's output.

### 6. Nothing checks the agreed outcome

Issue. Phase 6 runs the builds, the tests and the formatting checks of the final project. No step executes the acceptance criteria against the final project. The implementation merger alone decided that observability outranked the line budget, a trade-off that only the acceptance criteria should decide.

Resolution. In Stage 0, each acceptance criterion is written as a command with its expected output. A final acceptance step, run by a worker from a family other than the implementation merger's, executes those commands against the final project and records pass or fail per criterion; it adds no code. Each design already lists its failure modes; the acceptance step causes the failure modes that the chosen design claims to observe and checks that the design's own signals report them.

Where. The manager's role file, in Stage 0 and in a new final section; the implementor's role file of the family that did not merge.

### 7. The manager carries too much

Issue. The manager alone produced 15% of the measured output tokens of run-004. Its single session lasted 24 hours and reached a peak context of 784 thousand tokens. It verified every worker file by hand, and it wrote the closure ledger in the middle of the run.

Resolution. The closure ledger and the verification scripts become part of the pipeline, kept in the run root, with short outputs. Each phase runs as a fresh manager session that resumes from the state file; the partial-run rule already permits this. The manager keeps passing file paths to workers, not file contents.

Where. A tools folder in the run root; the manager's role file, in the partial-run rule.

### 8. The gemini family is unmeasured and was the weakest

Issue. Nothing in the record allows the gemini family's cost to be compared with the fable_5_1 family's. By the record it was the weakest family: its designs drew 150 critiques against 33 for the fable_5_1 family's designs, and its build had 22 defects against 3.

Resolution. Measurement only. Each worker's final reply states the usage its runtime exposes, and the manager records provider, model, runtime and usage for every spawn in the state file. Where a provider is reachable through a runtime that reports usage and through one that does not, a measured run uses the reporting one. Which model the family uses stays your decision; the newer Gemini model, called Argon, that the gemini family received today is a change of capability, not of measurement.

Where. The contract section shared by every worker role file; the manager's role file, in the state contract.

### 9. The parts that must stay as they are

The following parts held up in run-004, and findings 1 to 8 must not alter them. Stage 0 asks about goals only and turns every open technology choice into a research question, so that the models choose the technology where it applies. Evaluators critique only other families' designs, and no scores or rankings are produced, because a design that is graded rather than tested invites anchoring on the grade. The same protection covers the file gate of term 25, the evidence labels of term 26, the experiment disposition of term 19, stage 5b of term 23 and the keep rule of the implementation merger in term 24.

### 10. Operational prerequisite

Issue. The run root no longer exists, so no pipeline agent's working folder exists. Without the generators, a change to a role must now be made by hand in every workspace. The OpenAI route is not logged in, so the codex family and the phase 2 research merger cannot run.

Resolution. Create a new run root and point the working folder of every pipeline agent at it. Recreate a generator from the role files that survive in the workspaces, and keep it in the new run root. Log in to the OpenAI route. Where the new run root goes is your decision.

Where. The working-folder fields of OpenClaw's configuration file; the new run root.

## C. Suggested fixes

Every role-file edit goes into the dotfiles copy under `openclaw/workspaces/<agent>/SOUL.md`, then `./sync.sh`; every configuration edit goes through per-path `openclaw config set`.

- **1. Round 4 of phase 4 receives no answer**
  - Manager, procedure step 6.2: run the raise-and-answer loop for rounds 1 to 3 only, with the early end unchanged.
  - Manager, new step 6.3: spawn the evaluators once for round 4 with "settle only": re-examine every disposition and run every pending experiment, raise nothing new. Closure follows as before.
  - Evaluator, round procedure: on "round 4" perform only items 3 and 4 of the section.
- **2. The planning steps consume a quarter of the run**
  - Manager, step 6.1: delete. Evaluator, section "Evaluation plan (before round 1)": delete; the intended experiments already belong to the round 1 critiques, each with its predicted result.
  - Manager, step 7.1: keep two spawns, "write your implementation plan" and "critique the peer plans"; delete the "revise your plan" spawn.
  - Implementor, plan section item 3: delete. Stage 5a item 2: add "and every blocking critique of your plan" to the defects to resolve or document.
- **3. A fallback re-ran finished work**
  - Contract shared by every worker, new item: as the last action write a completion marker, `COMPLETE.md` in the role's output folder, listing each output file with its hash. If the marker exists at start, reply "already complete" and stop.
  - Manager, missing-workers rule 4: a timeout or empty reply counts as failure only when the marker is absent; with the marker present, record the step as done.
  - Manager, rule 1: a model from the worker's own fallback list is permitted and is recorded with the model that ran; a model of another family stays forbidden for parallel roles; the alternate agent is the permitted substitute for a single-worker role.
- **4. One runtime stopped the run three times**
  - Manager, communication contract item 1: spawn with the agent identifier and no model parameter, so that the fallbacks apply.
  - Manager, rule 1: retry once, then spawn the alternate agent for a single-worker role, then rule 3. List `research_merger_gemini` as the phase 2 alternate in the agents section.
  - Manager, new step before phase 1: send every worker an identity probe and record name and model in the state file; a worker that fails the probe is excluded before any phase work.
  - Manager steps 3, 5, 6, 7 and the merger's role file: replace "the three" and "six reviews" with "every family" and "every review".
- **5. Executed evidence stops at the host**
  - New script in the run root, `tools/probe_host.sh`: records tool versions, kernel version, whether the container runtime is rootless, whether the BPF mount can be attached, whether a cluster is reachable, GPU presence and free disk, into `0_host.md`. Stage 0 runs it; contract item 9 becomes "read `0_host.md`".
  - Designer, required sections of a design: add "verification needs", the facilities the verification plan requires, each marked present or absent per `0_host.md`.
  - Manager, new step after phase 3: provide the facilities the host can provide, record the rest under BLOCKED, ask the operator only about the absent ones. This is the one place after Stage 0 where the run may wait for the operator; the role file says so.
- **6. Nothing checks the agreed outcome**
  - Manager, Stage 0: write each acceptance criterion as a command with its expected output into `0_acceptance/criteria.md`; a criterion that cannot be a command is marked "judged by reading".
  - Manager, new step after phase 6: spawn the implementor of a family other than the merger's with "acceptance": run every criterion against the final project, record pass or fail with captured output in `7_acceptance/results.md`, add no code, induce each failure mode the chosen design lists and record whether the design's own signals report it.
  - Implementor, new section "Stage 7: acceptance" with those rules. Merger: when two kept parts conflict, the acceptance criteria decide, and the chosen criterion is recorded.
- **7. The manager carries too much**
  - Run root, `tools/closure_ledger.py` and `tools/verify_phase.sh`: the manager runs them and pastes their short output instead of reading every file.
  - Manager, partial-run rule: each phase runs as a fresh manager session whose message names the run directory and the phase; a driver script in the run root starts the manager once per phase and stops on BLOCKED.
- **8. The gemini family is unmeasured and was the weakest**
  - Contract item 10, final reply: add the usage the runtime reports, or "usage not reported by <runtime>".
  - Manager, state contract: record provider, model, runtime and usage for every spawn under DONE.
  - Configuration: for a measured run, bind the gemini family to a route that records usage, after one test spawn shows that it does; the direct Google API route is the candidate, with Antigravity as fallback.
- **9. The parts that must stay** need no edit; fixes 1 to 8 are written not to touch them.
- **10. Operational prerequisite**
  - Create the run root and set `cwd` of the 16 active pipeline agents to it; change the hard-coded run path in manager step 1 and the working-directory line of each IDENTITY.md in dotfiles.
  - Recreate the generator as `openclaw/gen_roles.py` in dotfiles, producing the role files from one table; this supersedes "keep it in the run root" in finding 10, since the files now live in dotfiles.
  - Log in to the OpenAI route with `openclaw models auth login --provider openai`; if the codex family still cannot start, rebasing it is the operator's decision.
- **Order**: 10, then 3 and 4, then 7, then 2 and 1, then 5 and 6, then 8. After the edits, a partial run of Stage 0 and phase 1 alone tests the probe script, the identity probe and the completion marker before a full run.

## D. Implementation in the second pipeline (2026-11-06)

The fixes of section C are implemented in a parallel pipeline whose agents carry the suffix `_v2`; the first pipeline is unchanged.

- Agents: `pipeline_manager_v2` and fifteen workers in the same three families, configured in `openclaw.json` with workspaces under `~/.openclaw/workspaces/<agent>/` and the working folder `~/Projects/openclaw_pipeline/`. Their role files are generated by `openclaw/gen_roles.py` into `openclaw/workspaces/` and synced to the live workspaces.
- Run root and tools: `~/Projects/openclaw_pipeline/` holds `runs/`, `tools/probe_host.sh`, `tools/verify_phase.sh`, `tools/closure_ledger.py` and `tools/run_pipeline.sh`, with its own README, MAP, ARCH, INSTR, WORKLOG and evidence files.
- Implemented: fix 1 (round 4 settles only), fix 2 (one planning step, before phase 5, with two spawns), fix 3 (completion markers; a fallback of the same family permitted and recorded), fix 4 (identity probe, spawn without model parameter, "every active family", the alternate research merger), fix 5 (host probe, verification needs per design, one operator question after phase 3), fix 6 (acceptance criteria as commands, phase 7 run by another family, the merger decides conflicts by the criteria), fix 7 (ledger, verifier, one manager session per phase, driver script), fix 8 (usage in every final reply and in `state.md`), fix 10 (run root, generator).
- Not done, the operator's decision: fix 8's route change for the gemini family. Fix 10's OpenAI login was done by the operator on 2026-11-06 (`openclaw models auth login --agent main --provider openai --force`; the shared profile expires 2026-11-17); an identity probe of `researcher_codex_v2` then answered on `openai/gpt-6-astra` with no fallback event.
- Beyond section C: the role files of the second pipeline name no technology. Where the first pipeline's texts carried the run-004 task (inference servers, Kubernetes, Cilium, Helm, C++ and Python), the second refers to the goals, priorities and deferred decisions of the clarified task. The research merger takes its input list from the task message; the first pipeline's merger read `1_research/claude.md` while the researcher wrote `1_research/fable_5_1.md`.
- Verification: the sixteen live configuration entries equal the generator's output; `openclaw config validate` passes; `openclaw agents list` shows the sixteen; an identity probe of `pipeline_manager_v2` answered `claude-cli/claude-opus-5-5 claude-cli`; the ledger's two unit tests pass; the probe and verifier scripts ran against a scratch run directory. No pipeline run has been started.
- Incident: during the first pass of configuration writes the gateway slowed from 41 s to 161 s per write and refused every entry holding an `antigravity/` model reference as unresolvable; `openclaw models list` then timed out. After `openclaw gateway restart`, the eleven refused entries were accepted unchanged in 194 s.
- Dry run (2026-11-06, run directory `~/Projects/ai/job_scheduling_collab`): the five gemini workers failed the identity probe with `AGY callback failed`. The cause, recorded in each worker's transcript, is `ANTIGRAVITY invocation workspace is outside the qualified configured project roots`: the plugin binds every run to the Antigravity project `openclaw-pipeline`, whose resource roots are `~/Projects/llm_serving` and `~/.openclaw/workspaces`, and the second pipeline's agents run from `~/Projects/openclaw_pipeline`. Resolution, the operator's: add that folder and the parent of the run directory to the project's roots (`~/.gemini/config/projects/<id>.json`) and restart the gateway, which reads the roots once at start. The run continued with the two other families.
- Dry run, second finding: the manager, on the Claude runtime, wrote two notes into Claude Code's auto-memory of its working folder (`~/.claude/projects/-home-ctuk-Projects-openclaw-pipeline/memory/`); every Claude-runtime worker with the same folder loads that memory at the start of its session, whatever its role or run, which breaks the separation of roles and of runs that findings 5 and 9 protect. The notes were moved out; the gateway's drop-in `openclaw-gateway.service.d/override.conf` in dotfiles sets `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` from the next restart.
- Pre-compaction memory flush (found 2026-11-07, 11:48 PST): when an embedded session (OpenAI or Antigravity runs; the Claude runtime is exempt) comes within about 24 000 tokens of its context window, OpenClaw runs a silent extra turn on the same paid model over the whole context, uncached, to write `memory/YYYY-MM-DD.md` in the agent workspace (`agents.defaults.compaction.memoryFlush`, default enabled; docs `reference/session-management-compaction/housekeeping.md`). The `codex` round-2 evaluator peaked at 265 278 context tokens, and its flush (hidden session key `agent:<agent>:internal-session-effects:<run>`) read 262 528 uncached input tokens: 9 points of the OpenAI 5-hour window, in addition to the 89 points of the step itself. The hidden session is deleted after the run, so no ledger records it; the pipeline also forbids writes outside RUN, and the read of the memory file failed on the sandbox root. Resolution: `openclaw config set agents.defaults.compaction.memoryFlush.enabled false --strict-json` (hot reload, 11:55 PST), snapshot refreshed. Side effect: no agent on this host writes pre-compaction memory notes until the setting returns to `true`.

## E. Planned: fallbacks for Astra and Fable (2026-11-06, not applied)

Facts behind the plan, from OpenClaw 2026.10.4's `docs/concepts/model-failover.md` and the live configuration:

- An agent whose entry names a primary model without `model.fallbacks` is strict: no fallback at all. `main` uses `agents.defaults.model`, which has no fallbacks either. Strict today: `main`, `orchestrator`, `coolguy`, `mouse`, `hoddard` (all on `openai/gpt-6-astra`) and `engineer_fable` (on `claude-cli/claude-fable-5`).
- Rate limits, billing limits and authentication failures are failover-worthy: OpenClaw first retries the same model within bounds, then rotates authentication profiles, then moves to the next model of the chain. A fallback holds for the current turn only; the next turn starts from the primary again, and a profile in cooldown is skipped quickly.
- The gateway logs of this host record only `401` authentication failures for the OpenAI route (the login expired), so the observation that Astra runs out quickly at `max` comes from outside OpenClaw. After the login, the same log (`model_fallback_decision` events in `/tmp/openclaw/openclaw-<date>.log`) will show the reason OpenClaw sees.

Changes, each one `openclaw config set <path> '<json>' --strict-json [--replace]`:

1. `agents.defaults.model`: `{"primary":"openai/gpt-6-astra"}` becomes `{"primary":"openai/gpt-6-astra","fallbacks":["openai/gpt-6-luna","openai/gpt-5.6-terra","openai/gpt-5.6-luna"]}`. Covers `main` and every agent without its own model.
2. `agents.defaults.modelPolicy.allow`: add `openai/gpt-5.6-terra` and `openai/gpt-5.6-luna`.
3. `agents.entries.<id>.model.fallbacks` for `orchestrator`, `coolguy`, `mouse`, `hoddard`: `["openai/gpt-6-luna","openai/gpt-5.6-terra","openai/gpt-5.6-luna"]`; `orchestrator.modelPolicy.allow` gains the two 5.6 ids (the other three inherit the defaults).
4. `agents.entries.reviewer_openai.model.fallbacks`: `["openai/gpt-6-luna"]` becomes the same three-model chain; its allow-list gains the two 5.6 ids.
5. The codex family of both pipelines already runs that chain; unchanged. A model of another provider stays out of the pipeline chains, because a family must not answer for another.
6. Optional, the operator's choice: append `claude-cli/claude-opus-5-5` as a last resort to the chains of items 1, 3 and 4, for the case that the whole OpenAI allowance is exhausted; `reviewer_openai` would then review with the provider it was meant to check.
7. `agents.entries.engineer_fable.model`: `{"primary":"claude-cli/claude-fable-5"}` becomes `{"primary":"claude-cli/claude-fable-5-1","fallbacks":["claude-cli/claude-opus-5-5","claude-cli/claude-sonnet-5-5","antigravity/claude-opus-5-5-high","antigravity/claude-sonnet-5-5-high"]}`, with `modelPolicy.allow` set to those five ids: the chain the six Fable pipeline agents already have. Those six, and the three Opus-first agents of the fable family whose chain ends in Fable, are unchanged.
8. Thinking stays `max` on every model (`agents.defaults.thinkingDefault`, `agents.defaults.models.*.params.thinking`), as the baseline requires. If the allowance itself, not single responses, is what empties, `agents.defaults.models["openai/gpt-6-luna"].params.thinking` set to `high` makes the fallback cheaper; the operator decides.
9. Per-spawn run timeouts in the second manager (generator edit, then sync): the communication contract gains "pass `runTimeoutSeconds` with every spawn: identity probe 300, research 3600, merge 1800, design 5400, round 5400, revise 3600, plan 1800, plan_critique 1800, stage_5a 14400, stage_5b 7200, merge_final 7200, acceptance 3600". The default `agents.defaults.subagents.runTimeoutSeconds` is 3600, and run-004's planning step timed out twice.
10. After applying: `openclaw config validate`; `bin/snapshot-openclaw`; the IDENTITY.md Model and Fallbacks lines of `engineer_fable`, `orchestrator`, `coolguy`, `mouse`, `hoddard` and `reviewer_openai` in `openclaw/workspaces/`, then `./sync.sh`.

## F. Unsupervised operation (2026-11-07)

1. Observed: the dry run of the second pipeline stopped three times on account limits (OpenAI usage window at 22:34 and 04:36, Antigravity quota at 03:57), each time because the missing-workers rules excluded the family and the two-family floor then stopped the phase; the operator had to re-admit and rerun by hand.
2. Measured: the OpenAI 5-hour window holds about 6.25 M total tokens and the weekly window about 40 M, cached input counted; a `codex` evaluation round costs about 5.5 M, a `codex` research step more than 6.1 M; the pre-compaction memory flush added a hidden 262 528-token turn (section D).
3. Changed, in `gen_roles.py` (manager template and worker contract) and `~/Projects/openclaw_pipeline/tools/`: limit errors suspend a family until the provider's reset time (`# WAITING` in `state.md`, driver sleeps and reruns the phase); a window check before every metered spawn skips steps larger than a full window; one remaining family continues in degraded mode within a wait bound; partial outputs resume through `RESUME:`; facility questions take defaults from `RUN/0_operator_defaults.md`; `RUN/STOP` halts a run; `tools/preflight.sh` runs the readiness checks; `tools/report.py` writes `RUN/REPORT.md` after every phase. Details: `~/Projects/openclaw_pipeline/ARCH.md` (terms 7 to 11, invariants 8 to 10) and `INSTR.md` ("A run" items 6 to 8).
4. Automations on the OpenAI account (2026-11-07): OpenClaw declares a weekly `skill-collection-review-<agent>` job per agent (52 here), `heartbeat-main` and `Memory Dreaming Promotion`; the reviews of the eighteen OpenAI-backed agents spend that account's windows and compete with the pipeline. System-owned jobs ignore `openclaw cron disable`. Resolution: `skills.workshop.autonomous.mode` set to `propose` (18:20 PST, hot reload; every review job disabled); `~/Projects/openclaw_pipeline/tools/openai_automations.sh disable|enable|list` flips it. Side effect: no autonomous skill reviews for any agent until the mode returns to `auto`. Since 23:40 PST the pipeline driver flips the switch itself: `propose` at start, `auto` restored at exit.
