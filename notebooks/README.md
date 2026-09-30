# XchangeHub AI & Data Science Notebooks — AWS Hackathon Submission

This directory contains the AI, Data Science, and Machine Learning prototypes and AWS serverless infrastructure for **XchangeHub** submitted for the **AWS Hackathon**.

---

## 📌 Main Notebook

### [`XchangeHub_AI_Skill_Matching.ipynb`](./XchangeHub_AI_Skill_Matching.ipynb)
**Title:** XchangeHub — AI-Powered Skill & Mentor Matching Engine

### What the Notebook Demonstrates:
1. **Explainable Skill & Mentor Matching Engine:** Combines TF-IDF text vectorization on skills and user bios with cosine similarity matching.
2. **Multi-Signal Ranking Score:** Blends skill similarity ($60\%$), mentor trust/accountability score ($20\%$), and average user rating ($20\%$) to rank mentors.
3. **Amazon Bedrock AI Integration (`boto3`):** Demonstrates real-time invoke of Amazon Bedrock LLM foundation models (`bedrock-runtime`) for natural language match reasoning.
4. **AWS Lambda REST API Execution:** Demonstrates serverless HTTP request payload processing and structured recommendation output via [`functions/aws_lambda_matcher.py`](../functions/aws_lambda_matcher.py).
5. **Exploratory Data Analysis (EDA):** Visualizes domain distribution, mentor rating spreads, accountability metrics, and top requested/taught skills.
6. **Persona-Based Evaluation:** Evaluates matching performance across 3 distinct learner personas (Data Science/ML, Modern Web Frontend, DevOps & AWS Infrastructure).
7. **Score & Similarity Breakdown:** Renders composite contribution charts and similarity matrices for complete algorithm explainability.
8. **AWS Architecture & Cloud Blueprint:** Outlines the architecture for scaling this prototype on AWS using **API Gateway, AWS Lambda, Amazon Bedrock, Amazon SageMaker Serverless Inference, Amazon DynamoDB, and Amazon ElastiCache**.

---

## 🛠️ Implemented AWS Components vs. Proposed Blueprint

| Feature / Component | Implemented (In Repository) | Proposed Production Target |
| :--- | :--- | :--- |
| **AWS Bedrock Client** | [`scripts/aws_bedrock_service.py`](../scripts/aws_bedrock_service.py) via Boto3 SDK | Fine-tuned Amazon Bedrock Titan Text Embeddings |
| **AWS Serverless API** | [`functions/aws_lambda_matcher.py`](../functions/aws_lambda_matcher.py) Lambda Handler | Production AWS Lambda with custom VPC & ElastiCache |
| **Infrastructure as Code** | [`aws_sam_template.yaml`](../aws_sam_template.yaml) CloudFormation/SAM Template | Automated CI/CD Deployment pipeline via AWS CodePipeline |
| **Matching Algorithm** | Hybrid TF-IDF + Cosine Similarity + Multi-Signal Ranking | Amazon OpenSearch Service k-NN Vector Search |
| **Dataset** | Synthetic profiles ($60$ users) modeled on XchangeHub `UserModel` schema | Live Cloud Firestore / Amazon DynamoDB user collections |

---

## 🔒 Security & Credentials Policy

* **Zero Hardcoded Credentials:** NO AWS access keys, secret keys, tokens, or credentials are hardcoded anywhere in the codebase or committed to version control.
* **Environment & IAM Authentication:** Credentials are read dynamically from standard environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`) or IAM Execution Roles.
* **Graceful Local Fallback:** If AWS credentials are absent in local environment, the client safely logs a diagnostic message and falls back to local execution without throwing uncaught errors.

---

## ☁️ Current Stack vs. AWS Services Implemented

### 🟢 Currently Deployed App Stack:
* **Frontend:** Flutter Mobile Application & Web Interface (Vercel Web Deployment)
* **Authentication:** Firebase Authentication
* **Database & Storage:** Cloud Firestore (`users`, `skill_exchanges`, `freelance_projects`, `portfolio`, `notifications`) & Firebase Storage

### 🚀 AWS Services Implemented for Hackathon:
* **Amazon Bedrock (`boto3`):** Foundational LLM recommendation reasoning
* **AWS Lambda:** Serverless match inference API handler (`/v1/recommendations`)
* **AWS SAM / CloudFormation:** Infrastructure as Code deployment specification

---

## 🚀 How to Run the Notebook

### Prerequisites
Make sure Python 3.8+ is installed on your system.

### 1. Install Required Packages
```bash
pip install pandas numpy scikit-learn matplotlib seaborn jupyter nbformat nbconvert boto3
```

### 2. (Optional) Configure AWS Credentials for Bedrock
```bash
export AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_ACCESS_KEY"
export AWS_REGION="us-east-1"
```
*(If no AWS credentials are provided, the notebook automatically falls back to local match explanation).*

### 3. Launch Jupyter Notebook
```bash
jupyter notebook notebooks/XchangeHub_AI_Skill_Matching.ipynb
```

### 4. Run All Cells
In Jupyter Notebook:
* Click **Kernel** -> **Restart & Run All**

---

## 📝 GitHub Submission Details

* **Notebook File Path:** [`notebooks/XchangeHub_AI_Skill_Matching.ipynb`](./XchangeHub_AI_Skill_Matching.ipynb)
* **Documentation File Path:** [`notebooks/README.md`](./README.md)
* **Submission URL:** `https://github.com/tejasbargujepatil/X-ChangeHub/blob/nirupam-work/notebooks/XchangeHub_AI_Skill_Matching.ipynb`
