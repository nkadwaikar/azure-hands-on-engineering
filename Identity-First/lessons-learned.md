# Lessons Learned

> **Why this matters:** Architectural decisions made in Week 1 become the defaults that every future lab inherits — capturing what broke, what simplified, and what surprised means the same mistakes aren't repeated and the same insights don't have to be re-discovered.

Week 1 focused on building a secure, identity-driven foundation with modular Bicep and a VS Code-only workflow. These lessons capture the architectural insights, the mistakes corrected, and the patterns validated during the lab.

Last reviewed on: 2026-06-25

> **Note:** This is a retrospective document, not a hands-on lab. No resources are created here.

---

## Quick Navigation

- [1. Identity-First Design](#1-identity-first-is-simpler-cleaner-and-more-secure)
- [2. Modular Bicep](#2-modular-bicep-makes-everything-easier)
- [3. VS Code Deployment](#3-vs-code-only-deployment-is-fast-and-predictable)
- [4. Governance Early](#4-governance-must-be-applied-early-not-later)
- [5. Validation](#5-validation-is-a-first-class-citizen)
- [6. Architecture Diagrams](#6-architecture-diagrams-clarify-thinking)
- [7. Folder Structure](#7-clean-folder-structure-reduces-friction)
- [8. Momentum](#8-small-wins-compound-into-big-momentum)
- [Summary](#summary)

---

## 1. Identity-First Is Simpler, Cleaner, and More Secure

**Key Insight**  
Using **User Assigned Managed Identity (UAMI)** as the primary authentication mechanism eliminates:

- Secrets  
- Keys  
- Connection strings  
- Manual configuration  

This drastically reduces operational risk and aligns with zero-trust principles.

### What I Learned About Identity-First Design  

- RBAC-mode Key Vault is the modern standard.  
- Access Policies are legacy and should be avoided.  
- Identity-first access forces clean architecture decisions early.

---

## 2. Modular Bicep Makes Everything Easier

**Key Insight**  
Breaking infrastructure into modules (identity, keyvault, rbac, locks) creates:

- Reusable patterns  
- Cleaner code  
- Easier debugging  
- Better documentation  
- Enterprise-grade structure  

### What I Discovered About Modular Bicep  

- Outputs between modules must be explicit and consistent.  
- A single typo in a parameter name can break the entire chain.  
- Module orchestration in `main.bicep` becomes the "source of truth."

---

## 3. VS Code-Only Deployment Is Fast and Predictable

**Key Insight**  
Deploying Bicep files directly from VS Code:

- Removes the need for CLI  
- Removes the need for Portal  
- Keeps the workflow consistent  
- Reduces cognitive load  

### What I Learned About VS Code Deployment  

- Right-click → Deploy Bicep File is reliable and intuitive.  
- Azure Explorer provides everything needed for validation.  
- Staying inside VS Code improves focus and reduces context switching.

---

## 4. Governance Must Be Applied Early, Not Later

**Key Insight**
Governance is not something to add in a later week.  
It needs to be part of the foundation.

### What I Learned

- Resource Locks prevent accidental deletion during experimentation.  
- RBAC assignments must be scoped correctly (resource vs RG).  
- Policies can be added later if the stack needs central enforcement.

---

## 5. Validation Is a First-Class Citizen

**Key Insight**  
A deployment is not "done" until it is validated.

### What I Learned About Validation  

- VS Code Azure Explorer is perfect for visual validation.  
- Screenshots create an audit trail for recruiters and reviewers.  
- Identity-first access tests (UAMI → Key Vault) prove the architecture works.

---

## 6. Architecture Diagrams Clarify Thinking

**Key Insight**  
ASCII diagrams are simple but powerful.  
They force clarity and reveal gaps.

### What I Learned About Architecture Diagrams  

- Visualizing the flow (identity, governance, deployment) exposes mistakes early.  
- Diagrams make documentation more accessible and recruiter-friendly.  
- Architecture is communication — not just code.

---

## 7. Clean Folder Structure Reduces Friction

**Key Insight**  
A well-organized repo is a competitive advantage.

### What I Learned About Folder Structure  

- Separating `bicep/` from the markdown labs keeps everything easier to navigate.  
- Keeping validation evidence near the relevant lab reduces friction.  
- A consistent structure sets the tone for future projects.

---

## 8. Small Wins Compound Into Big Momentum

**Key Insight**
Week 1 was not about complexity — it was about **foundations**.

### What I Learned About Momentum  

- A simple, secure landing zone is better than a complex, fragile one.  
- Identity-first patterns scale into every future capstone.  
- Momentum matters more than perfection.

---

## Summary

Week 1 delivered:

- A secure identity-first landing zone  
- Modular Bicep architecture  
- Governance controls  
- Observability foundations  
- Clean documentation  
- A repeatable VS Code deployment workflow  

These lessons set the stage for Week 2 and beyond.
