# Lakehouse Shortcut Audit Samples

This folder contains scripts to detect lakehouse table shortcuts that point to Delta tables with multipart checkpoints (`_last_checkpoint.parts > 1`).

## Why

Multipart Delta checkpoints are deprecated. Use this audit to identify existing shortcut usage that may require remediation.

## Files

- `find-multipart-shortcut-checkpoints.ipynb`

## Output

The notebook prints:

- number of scanned table shortcuts,
- number of unique target tables checked,
- shortcuts that point to multipart checkpoints.

Provided as-is, with no warranty or support commitments.
