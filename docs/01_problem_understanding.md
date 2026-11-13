# Problem Understanding – Netflix Streaming Database

## 1. Business Problems and Stakeholders

| ID | Business Need | Affected Stakeholders | Workload Classification |
|---|---|---|---|
| P1 | Improve homepage loading speed for Continue Watching, Top 10, My List and genre-based recommendations by retrieving personalized content efficiently. | Members, Personalization / UI team | Customer-facing / Real-time |
| P2 | Reduce delays in loading title details, searching the catalogue and automatically playing the next episode. | Members, Playback / Search team | Customer-facing / Real-time |
| P3 | Support case-insensitive email identification during sign-in and faster switching between profiles within an account. | Account holders, Profile users, Identity team | Customer-facing / Real-time |
| P4 | Identify episodes with zero recorded views to help the content team evaluate content engagement and make content decisions. | Content strategy team | Reporting / Analytics |
| P5 | Improve monthly invoice processing, failed-payment retries, handling of on-hold accounts and payment recovery operations. | Members, Payments & Billing team | Customer-facing / Operational |
| P6 | Enforce maturity restrictions for kids profiles and identify suspicious account-sharing patterns to meet compliance requirements. | Children, Parents, Compliance / Trust team | Mixed: Real-time + Analytics |
| P7 | Generate efficient analytics on binge sessions, completion rates, device usage, Netflix Originals, ratings and My List additions. | Content analytics team | Reporting / Analytics |
| P8 | Generate accurate plan revenue and churn reports while providing support teams with a fast customer activity console. | Finance and Customer Support teams | Mixed: Analytics + Real-time |

## 2. Assumptions

1. Each account can have a maximum of five profiles, and kids profiles must follow their assigned maturity limits.
2. Email addresses should be treated case-insensitively for account identification.
3. Viewing activity is the primary source for measuring content consumption, episode views and engagement.
4. An episode with no corresponding viewing activity is considered unwatched.
5. Account-sharing detection will be based on viewing patterns, timestamps and device information; these indicate suspicious activity but do not conclusively prove sharing.
6. Invoice status represents the recorded payment state. Individual payment retry attempts are not available in the current seed data.
7. Account status and invoice history will be used for subscription and churn analysis, with clearly defined reporting periods.
8. Performance improvements must preserve the original query results and business logic.

## 3. Overall Objective

Rebuild a properly structured, reliable and scalable Netflix streaming database from the available data exports. Establish a performance baseline for the 30 important queries, optimize them without changing their results, and validate that the database can handle future growth in users, content and viewing activity.
