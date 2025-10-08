# Terraform + GitHub Actions: Auto Scaling Web Infrastructure (Spot + On-Demand)

## Overview

This repository deploys a web application stack on AWS using Terraform and automates runs with GitHub Actions. It captures an AMI from a running EC2 instance, creates an ALB, and deploys an Auto Scaling Group using a mixed instances policy (Spot + On-Demand). The README below includes an embedded SVG architecture diagram that will render on GitHub.

---
## Architecture Diagram

<img width="1024" height="655" alt="test" src="https://github.com/user-attachments/assets/c5052060-e31f-49c6-aed2-65ef5c018482" />

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

File: `.github/workflows/workflow.yml`

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


## Outputs

* ALB DNS name (from `module.alb` outputs)
* New AMI ID (`aws_ami_from_instance.web_ami.id`)
* ASG name and status
