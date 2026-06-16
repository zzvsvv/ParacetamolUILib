Always write Luau using:

--!strict

Requirements:

Use typed Luau.
Use PascalCase for modules.
Use camelCase for variables.
Prefer task.wait() over wait().
Never use deprecated Roblox APIs.
Always annotate function parameters and return types.
Use Roblox best practices for memory cleanup.
Avoid infinite loops.
Prefer local functions where possible.
Prefer explicit types over type inference when clarity improves readability.
Code Quality
Write maintainable and production-ready code.
Avoid code duplication.
Prefer modular architecture.
Validate RemoteEvent and RemoteFunction inputs.
Consider mobile and console compatibility.
Optimize for performance when handling large numbers of instances.
GUI Requirements

Create modern Roblox interfaces.

Requirements:

Use UICorner on major frames and buttons.
Use UIStroke where appropriate.
Use UIPadding for spacing.
Use UIListLayout or UIGridLayout for organization.
Mobile friendly.
Scale-based sizing whenever practical.
Responsive layouts.
Dark theme by default.
Consistent spacing throughout the interface.
Premium simulator-style appearance.
Clear visual hierarchy.
Use AutomaticSize where appropriate.
GUI Design Style

Aim for:

Clean modern Roblox UI.
Professional game-quality presentation.
Rounded corners.
Subtle gradients when appropriate.
Readable typography.
Consistent margins and padding.
Good contrast and accessibility.


Tool Usage Rules

Before writing or modifying Roblox code:

Use Context7 to verify Roblox APIs.
Use available Lua LSP tools to inspect diagnostics.
Read all related files before editing.
Never assume API signatures.
Verify all service names.
Verify all event names.
Verify all property names.

When fixing code:

Gather diagnostics first.
Explain root cause.
Apply fix.
Re-check diagnostics.

Do not generate code before checking available tools.