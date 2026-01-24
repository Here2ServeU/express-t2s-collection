    #!/usr/bin/env bash
    set -euo pipefail

    # T2S Security: Example AWS IAM policy snippet for enforcing MFA (conceptual).
    # This script prints policy JSON you can apply via Terraform/IAM.
    #
    # Usage:
    #   ./sre/security/mfa-policy-setup.sh

    cat <<'EOF'
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "DenyAllExceptListedIfNoMFA",
          "Effect": "Deny",
          "NotAction": [
            "iam:CreateVirtualMFADevice",
            "iam:EnableMFADevice",
            "iam:GetUser",
            "iam:ListMFADevices",
            "iam:ListVirtualMFADevices",
            "iam:ResyncMFADevice",
            "sts:GetSessionToken"
          ],
          "Resource": "*",
          "Condition": {
            "BoolIfExists": { "aws:MultiFactorAuthPresent": "false" }
          }
        }
      ]
    }
EOF
