# 📝 Week 1 — Lessons Learned  
*Identity-First, Governance-Ready Landing Zone*

Week 1 focused on building a secure, identity-driven foundation using modular Bicep and a VS Code-only workflow.  
These lessons capture the architectural insights, mistakes corrected, and patterns validated during the capstone.

---

## 🔐 1. Identity-First Is Simpler, Cleaner, and More Secure

**Key Insight**  
Using **User Assigned Managed Identity (UAMI)** as the primary authentication mechanism eliminates:
- Secrets  
- Keys  
- Connection strings  
- Manual configuration  

This drastically reduces operational risk and aligns with zero-trust principles.

**What I learned**  
- RBAC-mode Key Vault is the modern standard.  
- Access Policies are legacy and should be avoided.  
- Identity-first access forces clean architecture decisions early.

---

## 🧩 2. Modular Bicep Makes Everything Easier

**Key Insight**  
Breaking infrastructure into modules (identity, keyvault, rbac, locks) creates:
- Reusable patterns  
- Cleaner code  
- Easier debugging  
- Better documentation  
- Enterprise-grade structure  

**What I learned**  
- Outputs between modules must be explicit and consistent.  
- A single typo in a parameter name can break the entire chain.  
- Module orchestration in `main.bicep` becomes the "source of truth."

---

## 🖥️ 3. VS Code-Only Deployment Is Fast and Predictable

**Key Insight**  
Deploying Bicep files directly from VS Code:
- Removes the need for CLI  
- Removes the need for Portal  
- Keeps the workflow consistent  
- Reduces cognitive load  

**What I learned**  
- Right-click → Deploy Bicep File is reliable and intuitive.  
- Azure Explorer provides everything needed for validation.  
- Staying inside VS Code improves focus and reduces context switching.

---

## 🛡️ 4. Governance Must Be Applied Early, Not Later

**Key Insight**  
Governance is not a "Week 8 thing."  
It must be part of the foundation.

**What I learned**  
- Resource Locks prevent accidental deletion during experimentation.  
- RBAC assignments must be scoped correctly (resource vs RG).  
- Policies should be introduced early to enforce consistency.

---

## 🧪 5. Validation Is a First-Class Citizen

**Key Insight**  
A deployment is not "done" until it is validated.

**What I learned**  
- VS Code Azure Explorer is perfect for visual validation.  
- Screenshots create an audit trail for recruiters and reviewers.  
- Identity-first access tests (UAMI → Key Vault) prove the architecture works.

---

## 🧭 6. Architecture Diagrams Clarify Thinking

**Key Insight**  
ASCII diagrams are simple but powerful.  
They force clarity and reveal gaps.

**What I learned**  
- Visualizing the flow (identity, governance, deployment) exposes mistakes early.  
- Diagrams make documentation more accessible and recruiter-friendly.  
- Architecture is communication — not just code.

---

## 🧹 7. Clean Folder Structure Reduces Friction

**Key Insight**  
A well-organized repo is a competitive advantage.

**What I learned**  
- Separating `bicep/`, `docs/`, `validation/`, `governance/`, and `observability/` keeps everything clean.  
- Validation screenshots deserve their own folder hierarchy.  
- A consistent structure sets the tone for future capstones.

---

## 🚀 8. Small Wins Compound Into Big Momentum

**Key Insight**  
Week 1 wasn't about complexity — it was about **foundations**.

**What I learned**  
- A simple, secure landing zone is better than a complex, fragile one.  
- Identity-first patterns scale into every future capstone.  
- Momentum matters more than perfection.

---

## 🎉 Summary

Week 1 delivered:
- A secure identity-first landing zone  
- Modular Bicep architecture  
- Governance controls  
- Observability foundations  
- Clean documentation  
- A repeatable VS Code deployment workflow  

These lessons set the stage for Week 2 and beyond.