# Microsoft Teams Guest Access and Invitation Policy

> **Last reviewed:** 2026-10-03

## Choose the control that matches your goal

| Goal | Control | Scope and effect |
| --- | --- | --- |
| Block all guest access to Teams | Teams admin center > **Users** > **Guest access** | Organization-wide. This is not a per-user Teams policy. |
| Limit who can invite new external users into the tenant | Microsoft Entra admin center > **External Identities** > **External collaboration settings** > **Guest invite settings** | Tenant-wide B2B invitation control. It affects guest invitations beyond Teams. |
| Allow guest access for some teams but not others | Apply an appropriate sensitivity label to the team | Per-team guest-access control. |

## Disable guest access across Teams

1. Sign in to the [Microsoft Teams admin center](https://admin.teams.microsoft.com/).
2. Open **Users** > **Guest access**.
3. Turn **Guest access** off and save the change.
4. Review the page's guest permissions as well if guest access remains enabled; those settings control what guests can do, not who may invite them.

This setting is organization-wide. Use it only when the intent is to block guest participation in Teams broadly. Microsoft 365 and Microsoft Entra settings also affect the overall guest collaboration experience, so review the related configuration before changing production access.

## Restrict who can invite new guests

1. In the [Microsoft Entra admin center](https://entra.microsoft.com/), open **External Identities** > **External collaboration settings**.
2. Under **Guest invite settings**, select **Only users assigned to specific admin roles can invite guest users**.
3. Select **Save**. Assign the **Guest Inviter** role only to approved users or an appropriately governed role-assignable security group.

This restricts invitations that create new Microsoft Entra B2B guest accounts; it is not a Teams-only control. **It does not prevent a team owner from adding an external user who is already a guest in the tenant to a team.** Global Administrators can still invite guests regardless of this setting.

## Limit access for specific teams

If guest collaboration should remain available in the tenant but be blocked for selected teams, use Microsoft 365 sensitivity labels configured to control external user access. Apply the label when creating or updating the team, and verify that its setting matches the team's data classification and collaboration requirements.

## Verify the policy

- Test with an approved team owner and an external account that is not already in the tenant.
- Test separately with an external account that already exists as a guest; the Entra invitation restriction alone does not block adding that account to a team.
- Confirm guest access to a team marked with the restrictive sensitivity label is blocked as intended.
- Allow time for changes to propagate, then verify both the Teams experience and the Microsoft Entra audit logs.

## References

- [Guest access in Microsoft Teams](https://learn.microsoft.com/en-us/microsoftteams/guest-access)
- [Configure external collaboration settings in Microsoft Entra](https://learn.microsoft.com/en-us/entra/external-id/external-collaboration-settings-configure)
- [Limit who can invite guests](https://learn.microsoft.com/en-us/microsoft-365/solutions/limit-who-can-invite-guests)
- [Use sensitivity labels to protect collaboration in Teams, Microsoft 365 groups, and SharePoint sites](https://learn.microsoft.com/en-us/microsoft-365/compliance/sensitivity-labels-teams-groups-sites)
