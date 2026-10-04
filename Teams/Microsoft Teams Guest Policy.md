# Microsoft Teams Guest Access and Invitation Policy

> **Last reviewed:** 2026-10-03

## Choose the control that matches your goal

| Goal | Control | Scope and effect |
| --- | --- | --- |
| Block all guest access to Teams | Teams admin center > **Users** > **Guest access** | Organization-wide. This is not a per-user Teams policy. |
| Limit who can invite new external users into the tenant | Microsoft Entra admin center > **External Identities** > **External collaboration settings** > **Guest invite settings** | Tenant-wide B2B invitation control. It affects guest invitations beyond Teams. |
| Allow guest access for some teams but not others | Apply an appropriate sensitivity label to the team | Per-team guest-access control. |

**Important:** Do not create or assign a Teams policy to control guest access or invitations. Teams policies do not contain an **Allow guest access** setting and are assigned to users, not teams. The Teams admin center's **Users** > **Guest access** setting controls whether guests can participate across the organization; Microsoft Entra controls who can invite new guest accounts. Use a sensitivity label when the restriction should apply to selected teams.

## Disable guest access across Teams

1. Sign in to the [Microsoft Teams admin center](https://admin.teams.microsoft.com/).
2. Open **Users** > **Guest access**.
3. Turn **Guest access** off and save the change.
4. Review the page's guest permissions as well if guest access remains enabled; those settings control what guests can do, not who may invite them.

This setting is organization-wide. Use it only when the intent is to block guest participation in Teams broadly. Microsoft 365 and Microsoft Entra settings also affect the overall guest collaboration experience, so review the related configuration before changing production access.

## Restrict who can invite new guests

1. In the [Microsoft Entra admin center](https://entra.microsoft.com/), open **External Identities** > **External collaboration settings**.
2. Under **Guest invite settings**, select **Only users assigned to specific admin roles can invite guest users**.
3. Select **Save**. Under this setting, users with either the **User Administrator** or **Guest Inviter** role can invite guests. Assign the **Guest Inviter** role only to approved users or an appropriately governed role-assignable security group, and review existing **User Administrator** assignments because they retain invitation capability.

This restricts invitations that create new Microsoft Entra B2B guest accounts; it is not a Teams-only control. **It does not prevent a team owner from adding an external user who is already a guest in the tenant to a team.** Global Administrators can still invite guests regardless of this setting.

## Limit access for specific teams

Use this option when guest collaboration should remain available generally but be blocked for selected teams. You need a role that can create and publish sensitivity labels in Microsoft Purview, and the tenant must have sensitivity labels enabled for groups and sites. Enabling container labels is a one-time tenant setup; follow Microsoft's [enable and synchronize sensitivity labels for containers](https://learn.microsoft.com/en-us/purview/sensitivity-labels-teams-groups-sites#how-to-enable-sensitivity-labels-for-containers-and-synchronize-labels) procedure if it has not already been done.

### Create and publish the restrictive label

1. Open the [Microsoft Purview portal](https://purview.microsoft.com/) and go to **Solutions** > **Information Protection** > **Sensitivity labels**.
2. Create a label for the intended classification, or edit an existing label. Select **Groups & sites** as its scope.
3. On **Define protection settings for groups and sites**, select **Privacy and external user access settings**.
4. Set **External users access** to disallow adding guests to the group or team. Choose **Private** for **Privacy** if membership should also be restricted to approved internal members. These are separate controls: private by itself does not block guests.
5. Finish the label wizard and save the label.
6. Create or update a sensitivity label policy that publishes this label to the team owners or administrators who need to apply it. For a cautious rollout, publish it to a small test group first.
7. Allow the label settings to replicate before testing: Microsoft documents at least one hour for a new label, and at least 24 hours for changes to an existing label. Shared-channel controls can require 24 hours even for a new label.

### Apply the label to a team

1. For a new team, create the team in Teams and choose the restrictive label from **Sensitivity** during creation.
2. For an existing team, select **More options** next to the team name > **Edit team**, then choose the restrictive label under **Sensitivity**. An administrator can also edit the team in the Teams admin center. If the label isn't offered, confirm it is published to your account and use the SharePoint admin center's **Active sites** page to inspect or set the connected site's **Sensitivity** under **Policies**. See [sensitivity labels for Microsoft Teams](https://learn.microsoft.com/en-us/microsoftteams/sensitivity-labels).
3. Confirm the label is displayed on the team and that the connected Microsoft 365 group and SharePoint site reflect the expected policy.

The label controls whether new guests can be added; it does not necessarily remove access for guests who were already members. Review existing team and site membership separately when tightening access. See Microsoft's [sensitivity-label guidance for collaborative workspaces](https://learn.microsoft.com/en-us/purview/sensitivity-labels-teams-groups-sites) for supported workflows and limitations.

## Verify the policy

1. Record the expected outcome for each control you changed: organization-wide Teams guest access, Entra guest invitations, or the selected team's sensitivity label.
2. Test with a team owner and an external account that is not already in the tenant. Confirm whether the account can be invited and added, as appropriate for the configured controls.
3. Test separately with an external account that already exists as a guest. The Entra guest-invitation restriction alone does not prevent a team owner from adding an existing guest to a team.
4. For a team with the restrictive label, attempt to add a new guest and confirm the operation is blocked. Also review existing members, because changing the label doesn't automatically remove guests who already have access.
5. Allow time for changes to propagate, then repeat the relevant tests in Teams. Review Microsoft Entra audit logs for guest invitations or group membership changes, and use the Microsoft 365 admin center guest-access diagnostic if the tenant-wide Teams setup does not behave as expected.
6. Record the test account, team, result, and time, and resolve any unexpected access before considering the change complete.

## References

- [Guest access in Microsoft Teams](https://learn.microsoft.com/en-us/microsoftteams/guest-access)
- [Configure external collaboration settings in Microsoft Entra](https://learn.microsoft.com/en-us/entra/external-id/external-collaboration-settings-configure)
- [Limit who can invite guests](https://learn.microsoft.com/en-us/microsoft-365/solutions/limit-who-can-invite-guests)
- [Use sensitivity labels to protect collaboration in Teams, Microsoft 365 groups, and SharePoint sites](https://learn.microsoft.com/en-us/microsoft-365/compliance/sensitivity-labels-teams-groups-sites)
