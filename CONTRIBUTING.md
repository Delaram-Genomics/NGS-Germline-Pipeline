# Contributing

Thank you for helping improve this educational germline WES workflow.

## Before opening a change

- Open an issue for substantial changes in scope or analytical behaviour.
- Use only public, broadly consented or synthetic data.
- Never include patient data, identifiers, local confidential paths or derived
  patient reports in issues, commits, screenshots or test fixtures.
- State whether a proposed threshold is a demonstration default, literature
  recommendation or locally validated acceptance criterion.

## Development workflow

1. Create a focused branch.
2. Make the smallest coherent change.
3. Add or update tests and documentation.
4. Run:

```bash
python3 -m unittest discover -s tests -v
python3 -m py_compile scripts/*.py tests/*.py
bash -n scripts/*.sh scripts/lib/*.sh
python3 -m json.tool nextflow_schema.json >/dev/null
git diff --check
```

5. Inspect `git status` and the staged diff for accidental data or outputs.
6. Open a pull request using the repository template.

## Pull-request expectations

Explain:

- what changed and why;
- analytical or user impact;
- inputs and reference build used for testing;
- commands and test results;
- limitations and any unvalidated assumptions.

Passing automated tests does not establish clinical validity.
