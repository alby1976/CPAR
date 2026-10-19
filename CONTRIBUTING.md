# Contributing

1. Create a branch describing the change, such as `fix/masterkey-copy`.
2. Export only the source files affected by the change.
3. Review every changed line for patient data, secrets, and private paths.
4. Test in a backup workbook using fictional inputs.
5. Open a pull request explaining the problem, resulting behavior, and checks performed.

Keep Excel query names and required column names stable unless the change explicitly updates their dependencies. Describe manual Excel steps when importing code is not sufficient.

Do not upload real workbooks, report exports, or diagnostic traces. Ignore rules are a convenience, not a guarantee that a commit is safe.
