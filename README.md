# Terraform + GitHub Actions: Auto Scaling Web Infrastructure (Spot + On-Demand)

## Overview

This repository deploys a web application stack on AWS using Terraform and automates runs with GitHub Actions. It captures an AMI from a running EC2 instance, creates an ALB, and deploys an Auto Scaling Group using a mixed instances policy (Spot + On-Demand). The README below includes an embedded SVG architecture diagram that will render on GitHub.

---

## Architecture Diagram

<!-- Inline SVG diagram — this renders on GitHub and other markdown viewers that allow inline HTML -->

<div align="center">

<svg xmlns="http://www.w3.org/2000/svg" width="900" height="420" viewBox="0 0 900 420" style="max-width:100%;height:auto;border:1px solid #e1e4e8;padding:12px;background:#fff;">
  <defs>
    <marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="5" orient="auto">
      <path d="M0,0 L10,5 L0,10 z" fill="#333" />
    </marker>
    <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="2" stdDeviation="3" flood-color="#000" flood-opacity="0.08" />
    </filter>
  </defs>

  <!-- GitHub Actions box -->

  <rect x="20" y="24" width="220" height="80" rx="8" fill="#f6f8fa" stroke="#d0d7de" />
  <text x="130" y="52" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#111" text-anchor="middle">GitHub Actions</text>
  <text x="130" y="72" font-family="Arial" font-size="11" fill="#444" text-anchor="middle">workflow: deploy.yml</text>

  <!-- Terraform box -->

  <rect x="260" y="24" width="200" height="80" rx="8" fill="#fff" stroke="#d0d7de" filter="url(#shadow)" />
  <text x="360" y="50" font-family="Arial" font-size="14" fill="#111" text-anchor="middle">Terraform</text>
  <text x="360" y="70" font-family="Arial" font-size="11" fill="#444" text-anchor="middle">init → plan → apply</text>

  <!-- Arrow GitHub -> Terraform -->

  <line x1="240" y1="64" x2="260" y2="64" stroke="#333" stroke-width="2" marker-end="url(#arrow)" />

  <!-- AWS cloud group -->

  <g>
    <rect x="500" y="10" width="360" height="380" rx="12" fill="#f8fafc" stroke="#cbd5e1" />
    <text x="680" y="32" font-family="Arial" font-size="13" fill="#0f172a" font-weight="600" text-anchor="middle">AWS</text>

```
<!-- AMI -->
<rect x="540" y="58" width="140" height="60" rx="8" fill="#ffffff" stroke="#cbd5e1"/>
<text x="610" y="86" font-family="Arial" font-size="12" fill="#111" text-anchor="middle">AMI from Instance</text>
<text x="610" y="102" font-family="Arial" font-size="11" fill="#475569" text-anchor="middle">aws_ami_from_instance</text>

<!-- Security Group -->
<rect x="710" y="58" width="140" height="60" rx="8" fill="#ffffff" stroke="#cbd5e1"/>
<text x="780" y="86" font-family="Arial" font-size="12" fill="#111" text-anchor="middle">Security Group</text>
<text x="780" y="102" font-family="Arial" font-size="11" fill="#475569" text-anchor="middle">SSH(22), HTTP(80)</text>

<!-- ALB -->
<rect x="560" y="150" width="240" height="64" rx="8" fill="#ffffff" stroke="#cbd5e1"/>
<text x="680" y="178" font-family="Arial" font-size="12" fill="#111" text-anchor="middle">Application Load Balancer (ALB)</text>
<text x="680" y="196" font-family="Arial" font-size="11" fill="#475569" text-anchor="middle">Target Group → Health Checks</text>

<!-- ASG -->
<rect x="540" y="240" width="320" height="120" rx="10" fill="#ffffff" stroke="#cbd5e1"/>
<text x="700" y="264" font-family="Arial" font-size="12" fill="#111" text-anchor="middle">Auto Scaling Group (Mixed Instances)</text>
<text x="700" y="282" font-family="Arial" font-size="11" fill="#475569" text-anchor="middle">Spot + On-Demand, Launch Template</text>

<!-- Instances inside ASG -->
<rect x="580" y="300" width="80" height="56" rx="6" fill="#f8fafc" stroke="#cbd5e1"/>
<text x="620" y="332" font-family="Arial" font-size="11" fill="#111" text-anchor="middle">EC2 (On-Demand)</text>

<rect x="680" y="300" width="80" height="56" rx="6" fill="#f8fafc" stroke="#cbd5e1"/>
<text x="720" y="332" font-family="Arial" font-size="11" fill="#111" text-anchor="middle">EC2 (Spot)</text>

<rect x="780" y="300" width="80" height="56" rx="6" fill="#f8fafc" stroke="#cbd5e1"/>
<text x="820" y="332" font-family="Arial" font-size="11" fill="#111" text-anchor="middle">EC2 (Spot)</text>

<!-- Arrows inside AWS -->
<line x1="680" y1="118" x2="680" y2="150" stroke="#333" stroke-width="2" marker-end="url(#arrow)" />
<line x1="680" y1="214" x2="680" y2="240" stroke="#333" stroke-width="2" marker-end="url(#arrow)" />
<line x1="620" y1="190" x2="620" y2="300" stroke="#333" stroke-width="2" marker-end="url(#arrow)" />

<!-- Connections from Terraform to AWS resources -->
<line x1="460" y1="64" x2="540" y2="88" stroke="#333" stroke-width="2" marker-end="url(#arrow)" />
<line x1="460" y1="64" x2="710" y2="88" stroke="#333" stroke-width="2" marker-end="url(#arrow)" />
<line x1="460" y1="64" x2="720" y2="190" stroke="#333" stroke-width="2" marker-end="url(#arrow)" />
```

  </g>

  <!-- Legend -->

  <rect x="20" y="120" width="220" height="160" rx="8" fill="#fff" stroke="#e6edf3" />
  <text x="130" y="144" font-family="Arial" font-size="13" fill="#0f172a" text-anchor="middle" font-weight="600">Resources & Flow</text>
  <text x="36" y="168" font-family="Arial" font-size="11" fill="#374151">• GitHub Actions triggers Terraform</text>
  <text x="36" y="188" font-family="Arial" font-size="11" fill="#374151">• Terraform creates AMI, ALB, ASG, Security Group</text>
  <text x="36" y="208" font-family="Arial" font-size="11" fill="#374151">• ASG runs mixed instances (Spot + On-Demand)</text>
  <text x="36" y="228" font-family="Arial" font-size="11" fill="#374151">• ALB routes HTTP traffic to ASG instances</text>

</svg>

</div>

---

## Infrastructure Components

| Component              | Description                                       |
| ---------------------- | ------------------------------------------------- |
| **Provider**           | AWS Provider for Terraform                        |
| **Security Group**     | Allows SSH (22) & HTTP (80)                       |
| **AMI Creation**       | Captures AMI from an existing EC2 instance        |
| **ALB**                | Distributes incoming traffic across EC2 instances |
| **Auto Scaling Group** | Uses mixed instances (Spot + On-Demand)           |
| **Scaling Policy**     | Scales based on average CPU utilization           |
| **Rolling Refresh**    | Gradually replaces instances during AMI update    |
| **GitHub Actions**     | Automates Terraform init/plan/apply               |

---

## GitHub Actions Workflow

File: `.github/workflows/deploy.yml`

```yaml
name: Terraform Deploy with Custom AMI

on:
  workflow_dispatch:
    inputs:
      running_instance_id:
        description: "Enter the ID of the running instance to create an AMI"
        required: true
        default: ""

jobs:
  deploy-terraform:
    runs-on: ubuntu-latest
    env:
      AWS_REGION: ${{ secrets.AWS_REGION }}
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    outputs:
      running_instance_id: ${{ github.event.inputs.running_instance_id }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Install Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: "1.9.0"

      - name: Terraform Init
        run: terraform init
        working-directory: terraform

      - name: Terraform Plan
        run: terraform plan -var "running_instance_id=${{ github.event.inputs.running_instance_id }}"
        working-directory: terraform

      - name: Terraform Apply
        run: terraform apply -auto-approve -var "running_instance_id=${{ github.event.inputs.running_instance_id }}"
        working-directory: terraform
```

---

## Required GitHub Secrets

| Secret Name             | Description                                    |
| ----------------------- | ---------------------------------------------- |
| `AWS_REGION`            | AWS region for deployment (e.g., `us-east-1`)  |
| `AWS_ACCESS_KEY_ID`     | IAM user access key with Terraform permissions |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key                            |
                   |

---

## How the Workflow Operates

1. **Trigger Manually**
   Go to GitHub → Actions → *Terraform Deploy with Custom AMI* → click **Run workflow**.

2. **Enter Running Instance ID**
   Input your existing EC2 instance ID (e.g., `i-0abcd123456789xyz`).

3. **GitHub Actions Executes**

   * Runs Terraform `init`, `plan`, and `apply`.
   * Captures AMI from the given instance.
   * Deploys ALB + ASG + scaling setup automatically.

4. **Output**

   * AMI ID
   * ALB DNS Name
   * ASG Name

---

## Terraform Variable Highlights

| Variable                                   |                        Description | 
| ------------------------------------------ | ---------------------------------: | 
| `aws_region`                               |                         AWS region | 
| `environment`                              |             Deployment environment | 
| `key_name`                                 |                       SSH key name | 
| `asg_min_size`                             |             Minimum instance count |
| `asg_max_size`                             |             Maximum instance count |
| `asg_desired_capacity`                     |             Desired instance count |
| `cpu_target_value`                         | Target CPU utilization for scaling |
| `on_demand_percentage_above_base_capacity` |           % of On-Demand instances |

---

## Rolling Updates

Whenever a new AMI is captured from your running instance, Terraform will:

* Create a new Launch Template version
* Gradually replace EC2 instances (e.g., `min_healthy_percentage = 50`)
* Maintain application uptime during deployment

---

## Usage

1. Push this repo to GitHub.
2. Add the required secrets to the repository settings (Settings → Secrets & variables → Actions).
3. Go to the *Actions* tab, select **Terraform Deploy with Custom AMI**, and click **Run workflow**.
4. Enter the running EC2 instance ID to snapshot as AMI.

---

## Notes & Future Improvements

* Use S3 + DynamoDB for remote state and locking.
* Place ASG in private subnets with a NAT Gateway for production security.
* Add Karpenter or EKS-based autoscaling if you migrate to Kubernetes.
* Add CI checks: `terraform validate`, `tflint`, `checkov`, and pre-commit hooks.

---

## Outputs

* ALB DNS name (from `module.alb` outputs)
* New AMI ID (`aws_ami_from_instance.web_ami.id`)
* ASG name and status
