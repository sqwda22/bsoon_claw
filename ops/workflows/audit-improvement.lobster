name: audit-improvement
steps:
  - id: collect
    command: python3 ops/scripts/lobster_extract_candidates.py
  - id: approve
    command: python3 ops/scripts/lobster_prepare_approval.py
    stdin: $collect.stdout
    approval: required
  - id: apply
    command: python3 ops/scripts/lobster_apply_candidates.py
    stdin: $collect.stdout
    condition: $approve.approved
