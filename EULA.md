# Skarn End User License Agreement

Version 1.0, 2026-07-12

This End User License Agreement (the "Agreement") is a legal agreement between you (an individual or a legal entity, "you") and company Red Black Tree d.o.o. Čačak, Republic of Serbia (the "Licensor") for the Skarn software. The Licensor intends to incorporate Skarn OU in Estonia and to assign this Agreement and the Software to it as described in Section 15. This Agreement governs your use of the Software under a License Token or as a Free Trial Version; if you use only the Free Features without a License Token or Free Trial Version, your use is governed by the Skarn Free Edition License Agreement (the EULA-FREE document distributed with the Software) instead of this Agreement. By downloading, installing, or using the Software under a License Token or as a Free Trial Version, you agree to this Agreement. If you do not agree, do not install or use the Software. If you accept on behalf of a legal entity, you represent that you are authorized to bind that entity.

## 1. Definitions

"Software" means the Skarn executable program in binary form, together with its embedded detection rules, documentation, and any updates the Licensor makes available under this Agreement. The Software is distributed in binary form only; no source code is licensed under this Agreement.

"Free Features" means the capabilities of the Software that operate without a License Token, as published in the Licensor's editions documentation (https://getskarn.com/editions/ and the EDITIONS document distributed with the Software).

"Free Trial Version" means a fully or partially functional version of the Software, including Paid Features, provided to you exclusively for evaluation and testing purposes for a strictly limited duration without an upfront purchase.

"Paid Features" means the capabilities of the Software designated as Team or Enterprise in the editions documentation, which operate only with a valid License Token covering them.

"License Token" means a cryptographically signed key issued by or on behalf of the Licensor that identifies the holder and unlocks Paid Features for the tier, scope, and term stated in it and in the applicable order.

"Feed Content" means detection-rule updates and related signed content the Licensor makes available to holders of a covering License Token.

## 2. License grant

Subject to this Agreement, the Licensor grants you a non-exclusive, non-transferable license to install and run the Software, in binary form, on machines you own or control, for your personal use or your organization's internal business use.

If the Software is provided to you as a Free Trial Version, the license is granted strictly for a limited period of 10 (ten) working days from the date of installation (the Evaluation Period). The Free Trial Version is intended solely for internal evaluation and testing purposes to determine whether you wish to purchase the Software.

Upon the expiry of the 10 working days Evaluation Period, you must immediately either: (a) purchase a commercial license under a valid License Token at a price and terms separately negotiated and agreed upon in writing with Red Black Tree d.o.o. Čačak, Republic of Serbia (or its authorized successor), or (b) immediately cease all use of the Software and permanently delete and destroy all copies of the Software, its component files, and documentation from all your machines, servers, and storage media.

The Free Features are made available at no charge. Paid Features are licensed only under a valid License Token or a valid Free Trial Version authorization; expiry or invalidity of a License Token or the expiration of the Evaluation Period does not affect the availability of the Free Features, provided that if the entire Software was delivered as a Free Trial Version, the entire copy must be deleted upon expiry. Continued use of the Free Features after the Evaluation Period is governed by the Skarn Free Edition License Agreement.

## 3. Restrictions

Except to the extent a restriction is not permitted by applicable law, you shall not: (a) redistribute, sell, rent, lease, sublicense, or otherwise make the Software available to any third party, other than installing it within your own organization from the Licensor's official distribution channels; (b) offer the Software, or any part of its functionality, to third parties as a hosted or managed service; (c) modify, translate, or create derivative works of the Software; (d) reverse engineer, decompile, or disassemble the Software, except to the extent expressly permitted by mandatory applicable law (including Articles 5 and 6 of Directive 2009/24/EC) and then only after first requesting the needed information from the Licensor; (e) circumvent, disable, or tamper with license enforcement, License Token validation, or signature verification in the Software; (f) remove or alter any proprietary notices; (g) share a License Token outside the holder or organization it names, or use a License Token you are not authorized to hold; (h) extract, republish, or redistribute the embedded detection rules or Feed Content outside the Software; (i) use the Software to develop a product or service that competes with the Software. Official distribution channels are those operated by the Licensor, currently getskarn.com, the skarn-security repositories on GitHub, and ghcr.io/skarn-security.

## 4. Ownership

The Software is licensed, not sold. The Licensor and its licensors retain all right, title, and interest in and to the Software, the source code, the binary executable, the detection rules, the Feed Content, and all associated intellectual property rights, including but not limited to copyrights, trademarks, trade secrets, and patent rights. The Software is protected by the copyright laws of the Republic of Serbia, international copyright treaties, and all other applicable intellectual property laws.

Your possession, installation, or use of the Software, including the use of a Free Trial Version, does not transfer to you any title, ownership, or intellectual property rights in the Software. Any unauthorized copying, redistribution, reverse engineering, or modification of the Software constitutes a material breach of this Agreement and a direct infringement of the Licensor's copyright. All rights not expressly granted under this Agreement are strictly reserved by the Licensor.

## 5. Third-party components

The Software incorporates third-party open-source components (including PCRE2 and SQLite) under their own licenses, listed in the THIRD-PARTY-NOTICES document distributed with the Software. Those licenses govern the respective components; this Agreement governs the Software as a whole.

## 6. Data handling and network features

The Software runs on your machines and processes data locally. It does not transmit scanned session content, scan results, personal data, or usage telemetry to the Licensor or to third parties, and it does not require an account. The Software's only network feature is the rule-feed update: when you explicitly invoke it, the Software downloads signed Feed Content from the configured feed channel, and the request carries at most the feed subscriber token that authenticates your subscription; it transmits no session content and no scan results. The feature is disabled by default, and the offline flag disables it. You are responsible for compliance with your organization's policies when you enable a network feature.

## 7. Your responsibilities

The Software reads AI coding-assistant session data and related files present on the machines where you run it. You are responsible for ensuring that you are authorized to access and process that data, and for complying with the laws and internal policies that apply to it.

## 8. Security-tool disclaimer

The Software performs pattern-based detection. The Licensor does not warrant that the Software will detect every credential, secret, attack pattern, or security issue, nor that reported findings are free of false positives. The Software surfaces findings; it does not remediate them. You remain responsible for verifying findings, rotating exposed credentials, incident response, and the security of your systems. The Software and its output are not legal, compliance, or security advice, and use of the Software does not by itself establish compliance with any law or standard. The Software is not designed or licensed for use in safety-critical systems.

## 9. Feed Content and updates

Feed Content is available to holders of a covering License Token for use within the Software during the subscription term stated in the applicable order. The Licensor may make Software updates available; this Agreement applies to updates unless the update is accompanied by different terms.

## 10. Support

The Free Features are provided without a support commitment. Support for Paid Features, if any, is as stated in the applicable order.

## 11. Warranty disclaimer

THE SOFTWARE IS PROVIDED "AS IS" AND "AS AVAILABLE", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT, EXCEPT TO THE EXTENT A WARRANTY CANNOT BE DISCLAIMED UNDER APPLICABLE LAW.

## 12. Limitation of liability

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE LICENSOR SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR FOR LOSS OF PROFITS, REVENUE, DATA, OR GOODWILL, ARISING OUT OF OR RELATING TO THIS AGREEMENT OR THE SOFTWARE. THE LICENSOR'S AGGREGATE LIABILITY UNDER THIS AGREEMENT SHALL NOT EXCEED THE AMOUNTS YOU PAID FOR THE SOFTWARE IN THE TWELVE MONTHS PRECEDING THE EVENT GIVING RISE TO THE CLAIM. NOTWITHSTANDING ANYTHING TO THE CONTRARY IN THIS AGREEMENT, IF YOU ARE USING A FREE TRIAL VERSION, THE SOFTWARE IS PROVIDED ENTIRELY AS IS AND THE LICENSOR'S AGGREGATE LIABILITY FOR ANY DAMAGES, LOSSES, OR CLAIMS ARISING OUT OF OR IN CONNECTION WITH THE FREE TRIAL VERSION DURING THE EVALUATION PERIOD SHALL BE EXACTLY EUR 0, OR, IN CASE OF PURCHASED VERSION OF THE SOFTWARE, SHALL BE STRICTLY LIMITED TO THE ACTUAL AMOUNTS RECEIVED BY THE LICENSOR FROM YOU IN THE TWELVE (12) MONTHS PRECEDING THE EVENT GIVING RISE TO SUCH CLAIM, WHETHER PAID AS A LUMP SUM OR AS THE SUM OF ALL INSTALLMENTS DUE AND PAID WITHIN THAT SPECIFIC TWELVE-MONTH PERIOD. NOTHING IN THIS AGREEMENT EXCLUDES OR LIMITS LIABILITY THAT CANNOT BE EXCLUDED OR LIMITED UNDER APPLICABLE LAW, INCLUDING LIABILITY FOR INTENT OR GROSS NEGLIGENCE WHERE SO PROVIDED.

## 13. Term and termination

This Agreement is effective until terminated. It terminates automatically if you materially breach it. Upon termination you must stop using the Software and destroy your copies. Paid entitlements end per the applicable order. Sections 3 through 8 and 11 through 16 survive termination.

## 14. Export and sanctions

You shall comply with applicable export-control and sanctions laws in your use of the Software and represent that you are not a person or entity to whom supply of the Software is prohibited under those laws.

## 15. General

This Agreement is the entire agreement between you and the Licensor regarding the Software and supersedes prior discussions on that subject; where you hold a separately negotiated written agreement with the Licensor covering the Software, that agreement prevails to the extent of any conflict. If a provision is held unenforceable, the remainder stays in effect. A failure to enforce a provision is not a waiver. You may not assign this Agreement without the Licensor's written consent; the Licensor may assign this Agreement, in whole, to a successor of the business, including to Skarn OU upon its incorporation, with the assignment taking effect on notice published at https://getskarn.com/terms/. This Agreement does not limit any rights you hold as a consumer that cannot be limited under applicable law.

## 16. Governing law and venue

This Agreement is governed by the laws of the Republic of Serbia, excluding its conflict-of-law rules and the United Nations Convention on Contracts for the International Sale of Goods. The competent court in Belgrade, Serbia has exclusive jurisdiction, subject to any mandatory consumer venue rules.

## 17. Contact

Licensing questions: hello@getskarn.com
