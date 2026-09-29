# -*- coding: utf-8 -*-
"""Replace Terms & Conditions in policies JSON from Terms & Conditions.pdf."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POLICIES_DIR = ROOT / "assets" / "policies"

EFFECTIVE = "28 September 2026"

# GemWorld placeholders filled from existing marketplace policies.
TERMS_EN: dict = {
    "id": "terms",
    "title": "Terms & Conditions",
    "subtitle": "B2B diamond marketplace use, KYC/AML, escrow, and liability",
    "eyebrow": "GemWorld Marketplace",
    "effectiveDate": EFFECTIVE,
    "intro": (
        'These Terms and Conditions ("Terms") are a legally binding agreement between you '
        '("User," "you," "your," which includes both Buyers and Sellers as defined below) and '
        "GemWorld, a company operating under the laws of India "
        '("Company," "we," "us," "our," "Platform"), governing your access to and use of the '
        "GemWorld mobile application, associated website, and related services "
        '(collectively, the "Platform").'
    ),
    "secondaryIntro": (
        "By downloading, installing, registering on, accessing, or using the Platform in any "
        "manner, you unconditionally agree to be bound by these Terms, our Privacy Policy, our "
        "AML/KYC requirements, and any other policies referenced herein (together, the "
        '"Agreement"). If you do not agree, you must not access or use the Platform.'
    ),
    "sections": [
        {
            "number": "1",
            "title": "Introduction and Acceptance of Terms",
            "paragraphs": [
                "If you use the Platform on behalf of a company, partnership, or other legal entity, you represent and warrant that you have the authority to bind that entity, and \"you\" refers to that entity as well as you personally.",
                "We may modify these Terms at any time in accordance with Section 23. Continued use of the Platform after modifications constitutes acceptance of the revised Terms.",
            ],
        },
        {
            "number": "2",
            "title": "Definitions",
            "paragraphs": ["In these Terms:"],
            "bullets": [
                '"Buyer" means a registered User who uses the Platform to purchase Diamonds.',
                '"Seller" means a registered User, including manufacturers, miners, laboratories, wholesalers, and traders, who lists Diamonds for sale on the Platform.',
                '"Diamond(s)" means natural diamonds and/or laboratory-grown/CVD (Chemical Vapour Deposition) or HPHT diamonds, whether loose or set, listed for sale on the Platform.',
                "\"Listing\" means a Seller's offer to sell a specific Diamond or parcel of Diamonds on the Platform, including all accompanying descriptions, images, certificates, and pricing.",
                '"Certifying Body" means an independent gemological grading laboratory (including but not limited to GIA, IGI, HRD, GCAL, or such other laboratory as we may recognize from time to time) that issues a Certificate for a Diamond.',
                '"Certificate" or "Grading Report" means the report issued by a Certifying Body describing a Diamond\'s characteristics (carat, cut, color, clarity, origin — natural or lab-grown — and other attributes).',
                '"Transaction" means any offer, order, sale, purchase, or exchange of Diamonds initiated, negotiated, or concluded using the Platform.',
                '"Facilitation Services" means the payment facilitation, escrow, and logistics/shipping coordination services described in Sections 7 and 8, which we may provide directly or through Third-Party Providers.',
                '"Third-Party Provider" means any independent payment processor, escrow agent, logistics carrier, insurer, customs broker, KYC/AML verification vendor, or Certifying Body engaged to support Transactions.',
                '"Content" means all text, images, certificates, data, and other material uploaded, submitted, or transmitted by a User through the Platform.',
                '"Vulnerability" means any bug, defect, exploit, security flaw, or unintended behavior of the Platform.',
            ],
        },
        {
            "number": "3",
            "title": "Eligibility, Registration and Account Verification (KYC/AML)",
            "paragraphs": [
                "Eligibility. You must be at least 18 years of age (or the age of majority in your jurisdiction, if higher) and have the legal capacity to enter into binding contracts to register on the Platform. The Platform is intended for use by businesses (manufacturers, wholesalers, traders, laboratories, and professional buyers) and is a business-to-business (B2B) marketplace unless expressly stated otherwise.",
                "KYC/AML Verification. Prior to activating trading privileges, every User must complete identity verification (\"KYC\") and, where applicable, business/entity verification, which may include government-issued identification, business registration documents, tax identification, beneficial ownership information, and bank/payment account verification. We reserve the right to engage Third-Party Providers to conduct KYC, sanctions screening (including against OFAC, UN, EU, and other applicable sanctions/watch lists), and anti-money-laundering (\"AML\") checks.",
                "Ongoing Screening. We may re-verify Users periodically or on a risk basis and may suspend an account pending verification without liability to you.",
                "Accuracy of Information. You represent that all information provided during registration and KYC is true, current, and complete, and you agree to promptly update it. Providing false, misleading, or incomplete information is a material breach of these Terms and may result in immediate suspension, forfeiture of pending Transactions, and reporting to relevant authorities.",
                "Account Security. You are solely responsible for maintaining the confidentiality of your login credentials, API keys, and two-factor authentication devices, and for all activities that occur under your account, whether or not authorized by you, except to the extent such activity results solely from our gross negligence or willful misconduct. You must notify us immediately of any unauthorized use or suspected security breach.",
                "One Account per User; No Impersonation. You may not create more than one account without our written permission, impersonate any person or entity, or misrepresent your affiliation with any person or entity.",
            ],
        },
        {
            "number": "4",
            "title": "Nature of the Platform — Marketplace Intermediary, Not a Party to the Trade",
            "paragraphs": [
                "The Platform is a technology marketplace that connects Buyers and Sellers of Diamonds and, where opted into by both parties, provides Facilitation Services. UNLESS EXPRESSLY STATED IN A SEPARATE WRITTEN AGREEMENT, THE COMPANY IS NOT A SELLER, BUYER, BROKER, AUCTIONEER, DEALER, APPRAISER, GRADER, OR AGENT OF ANY DIAMOND AND DOES NOT TAKE TITLE TO, POSSESSION OF (except as a logistics intermediary under Section 8), OR ANY OWNERSHIP INTEREST IN ANY DIAMOND LISTED OR TRADED ON THE PLATFORM.",
                "Every Transaction is a direct contract of sale between the relevant Buyer and Seller. The Company is not a party to, and assumes no liability arising from, the underlying contract of sale, including its formation, performance, breach, quality, description, authenticity, delivery, or any dispute arising from it, except to the limited extent expressly set out in these Terms regarding our own Facilitation Services.",
                "Nothing in these Terms creates a partnership, joint venture, agency, franchise, or employment relationship between the Company and any User.",
            ],
        },
        {
            "number": "5",
            "title": "Listings, Certification Requirements and Diamond-Specific Representations",
            "paragraphs": [
                "Seller Responsibility for Listings. Sellers are solely and exclusively responsible for the accuracy, completeness, and legality of every Listing, including carat weight, cut, color, clarity, treatment status, origin (natural or laboratory-grown/CVD/HPHT), provenance, and all Content uploaded.",
                "Mandatory Independent Certification. Save where we expressly permit uncertified goods in a clearly labelled category, every Diamond (above such minimum carat weight as we specify from time to time) must be listed together with a valid, current Certificate from a Certifying Body recognized by the Platform. Sellers must disclose, prominently and unambiguously, whether a Diamond is natural or laboratory-grown, and any known treatments (e.g., HPHT annealing, irradiation, fracture filling, coating).",
                "Kimberley Process and Conflict-Free Sourcing (Natural Diamonds). Sellers listing natural diamonds warrant that such diamonds are sourced, processed, and exported in compliance with the Kimberley Process Certification Scheme and applicable national implementing legislation, and where required, are accompanied by a valid Kimberley Process certificate and comply with the World Diamond Council System of Warranties. The Company does not independently verify Kimberley Process compliance and relies entirely on Seller warranties and Certifying Body/customs documentation.",
                "Lab-Grown/CVD Disclosure. Sellers of laboratory-grown diamonds warrant compliance with all applicable disclosure laws in both the Seller's and (to the extent known) the Buyer's jurisdiction (for example, disclosure requirements comparable to the U.S. FTC Guides for the Jewelry Industry), including clear, unambiguous labelling of a Diamond's man-made origin at every stage — Listing, invoice, packaging, and accompanying Certificate.",
                "No Independent Grading by the Company. THE COMPANY DOES NOT GRADE, APPRAISE, INSPECT, TEST, OR AUTHENTICATE ANY DIAMOND. We do not verify that a Certificate uploaded by a Seller is genuine, current, or actually corresponds to the physical Diamond offered, except where we expressly state that a specific verification step (e.g., certificate-number lookup with the Certifying Body's public database, where available) has been performed for a given Listing, and even then such verification is limited to what that lookup discloses.",
                "Buyer Diligence. Buyers are responsible for reviewing the Certificate, Listing description, and (where offered) requesting independent verification, physical inspection, or a hold-for-inspection period before completing a Transaction. We strongly recommend Buyers independently verify any Certificate directly with the issuing Certifying Body prior to purchase.",
                "Removal of Listings. We may, at our sole discretion and without liability, remove, suspend, or refuse any Listing that we reasonably believe is inaccurate, fraudulent, non-compliant with law, or in breach of these Terms, without any obligation to do so and without this creating any duty to monitor Listings generally.",
            ],
        },
        {
            "number": "6",
            "title": "No Guarantee of Quality, Authenticity, or Payment",
            "paragraphs": [
                'THE PLATFORM, ALL LISTINGS, AND ALL CONTENT ARE PROVIDED ON AN "AS IS," "AS AVAILABLE," AND "AS DESCRIBED BY THE SELLER" BASIS. EXCEPT AS EXPRESSLY SET OUT IN A SEPARATE WRITTEN GUARANTEE PROGRAM (IF ANY) THAT WE MAY OFFER FROM TIME TO TIME, THE COMPANY MAKES NO REPRESENTATION OR WARRANTY, EXPRESS OR IMPLIED, REGARDING:',
            ],
            "bullets": [
                "The quality, authenticity, grade, weight, origin, treatment status, or value of any Diamond;",
                "The accuracy of any Certificate, Listing description, image, or other Content supplied by a Seller;",
                "The creditworthiness, solvency, identity, or ability to perform of any Buyer or Seller;",
                "The completion, timing, or successful settlement of any payment between Buyer and Seller;",
                "Merchantability, fitness for a particular purpose, title, or non-infringement of any Diamond or Content.",
            ],
            "closing": "Reliance on Professional Verification. Where the Platform indicates that a Transaction has been reviewed by our professional/compliance team (e.g., document verification, sanctions screening, or facilitation of an independent inspection), that review is limited strictly to the specific matters we state were reviewed (such as KYC completion or document consistency checks) and is not, and must not be treated as, a certification, guarantee, or warranty of the Diamond's quality or of successful payment. Any statement by Company personnel regarding a Listing or User is for informational convenience only and does not modify these Terms unless made in a signed written amendment by an authorized officer of the Company. Payment Facilitation Is Not a Payment Guarantee. Provision of Facilitation Services (Section 7) does not constitute a guarantee by the Company that payment will be made, received, or cleared, nor a guarantee against chargebacks, reversals, insolvency of a User, or fraud by a counterparty, except to the extent we expressly agree to bear such risk under a specific, separately documented Escrow Protection Program. No Valuation Advice. Nothing on the Platform constitutes investment, valuation, or financial advice. Diamond prices are volatile and set solely by Sellers or by negotiation between Users.",
        },
        {
            "number": "7",
            "title": "Payments, Fees and Escrow",
            "paragraphs": [
                "Facilitation Role. Where a Transaction is routed through our payment Facilitation Services, funds are held and disbursed by us or by a licensed Third-Party Provider (e.g., a regulated escrow agent or payment institution) strictly as a limited-purpose paying agent for the Buyer and Seller, subject to the release conditions set out in the applicable Transaction flow (e.g., confirmed delivery, inspection period expiry, or dispute resolution outcome under Section 16).",
                "Fees. We charge the fees disclosed in our then-current fee schedule (transaction fees, payment processing fees, currency conversion fees, and logistics fees where applicable), which are non-refundable except as expressly stated. We may change fees prospectively on notice.",
                "Currency and FX. Cross-border Transactions may involve currency conversion performed by a Third-Party Provider at rates we do not control; we are not liable for FX losses, spreads, or delays caused by banking or payment intermediaries.",
                "Taxes and Duties. Each User is solely responsible for determining, collecting, reporting, and remitting all taxes, duties, tariffs, and levies (including GST/VAT, customs duty, and income tax) arising from their Transactions. The Company is not responsible for tax withholding or filing on behalf of Users except where required by applicable law.",
                "Chargebacks, Reversals and Fraud Losses. If a payment is reversed, charged back, or found to be fraudulent after funds have been disbursed to a Seller, the Seller agrees to promptly repay such amount to us on demand, and we may set off such amount against any other funds owed to that Seller.",
                "No Client Money Trust Obligations Beyond Law. Where local law imposes safeguarding obligations on funds we hold (e.g., segregation requirements for licensed payment institutions), we will comply with those specific statutory obligations; nothing else in these Terms should be read as us assuming fiduciary duties beyond what is legally mandated.",
            ],
        },
        {
            "number": "8",
            "title": "Logistics, Shipping, Customs, and Risk of Loss",
            "paragraphs": [
                "Where the Platform coordinates shipping through Third-Party Providers (couriers, secure freight/vault-to-vault carriers, customs brokers, and insurers), we act solely as a coordination intermediary. Risk of loss or damage to a Diamond passes according to the shipping terms selected at checkout (e.g., Incoterms such as EXW, FOB, or CIF, as configured), and in the absence of a selection, risk passes to the Buyer upon handover to the first carrier.",
                "Insurance. Sellers and Buyers are responsible for ensuring adequate transit insurance is purchased for the full declared value of a shipment. Where we offer an optional insurance add-on underwritten by a Third-Party Provider, our role is limited to facilitating the purchase of that policy; claims are made against, and paid by, the underwriter, not the Company.",
                "Export/Import Compliance. Users are solely responsible for complying with export control laws, import restrictions, customs declarations, and Kimberley Process export/import documentation applicable to cross-border shipment of Diamonds. The Company is not responsible for shipments seized, delayed, or destroyed by customs or regulatory authorities.",
                "Loss, Damage or Theft in Transit. Claims for loss, damage, or theft during transit must be pursued against the carrier and/or insurer in accordance with their respective terms; the Company's liability, if any, for coordination failures is capped as set out in Section 14.",
            ],
        },
        {
            "number": "9",
            "title": "Acceptable Use, Prohibited Conduct and Platform Security (Anti-Abuse)",
            "paragraphs": [
                "You agree that you will not, and will not permit or assist any third party to:",
            ],
            "bullets": [
                "Access or attempt to access any part of the Platform, another User's account, or any data, in a manner not expressly permitted, including by circumventing authentication, rate limits, or access controls;",
                "Probe, scan, or test the vulnerability of the Platform or any related system or network, or breach or circumvent any security or authentication measures, except under our formal Responsible Disclosure Program described in Section 10;",
                'Exploit any bug, error, misconfiguration, race condition, pricing/inventory error, or unintended functionality (a "Loophole") for financial gain, to obtain goods, services, discounts, or data not properly authorized, or to cause harm to the Platform, the Company, or any User;',
                "Use bots, scrapers, crawlers, or other automated means to access, extract data from, or transact on the Platform without our prior written consent;",
                "Reverse engineer, decompile, disassemble, or otherwise attempt to derive source code, algorithms, or underlying data structures of the Platform, except to the extent such restriction is prohibited by applicable law;",
                "Introduce viruses, malware, ransomware, or any other harmful code, or engage in denial-of-service or similar attacks;",
                "Use the Platform for money laundering, terrorist financing, sanctions evasion, trade-based fraud, or any other unlawful purpose, or to trade in conflict diamonds or Diamonds lacking legitimate provenance;",
                "Engage in price manipulation, shill bidding, collusive Transactions, wash trading, or any conduct intended to artificially inflate or manipulate ratings, rankings, or prices;",
                "Upload false, fraudulent, or misleading Listings, Certificates, or identity documents;",
                "Circumvent the Platform to complete a Transaction off-platform in order to avoid fees, after having connected with a counterparty through the Platform, where doing so is prohibited by our then-current anti-circumvention policy;",
                "Harass, defraud, threaten, or discriminate against another User.",
            ],
            "closing": "Consequences of Breach. Any violation of Section 9 is a material breach entitling us, without notice and without liability to you, to: (a) immediately suspend or terminate your account and any pending Transactions; (b) withhold, freeze, reverse, or claw back any funds, fees, or benefits obtained through the violation; (c) pursue civil recovery of any resulting loss, and where a Loophole was exploited for financial gain, recovery of the full amount improperly obtained plus our investigation costs; (d) report the conduct to law enforcement, regulators, and financial-crime authorities; and (e) permanently bar you and any related entities from the Platform. Unjust Enrichment. Any benefit, discount, Diamond, or sum obtained through exploitation of a Loophole is deemed held on trust for the Company (or the affected User, as applicable) and must be returned or repaid immediately on demand, regardless of whether the exploited Loophole was known to us at the time.",
        },
        {
            "number": "10",
            "title": "Responsible Disclosure of Vulnerabilities",
            "paragraphs": [
                "We encourage good-faith security researchers to report Vulnerabilities to m.gemworld@gmail.com before exploiting, publicly disclosing, or otherwise using them. A report made in good faith, without accessing, modifying, or exfiltrating other Users' data beyond what is minimally necessary to demonstrate the issue, and without seeking to profit from the Vulnerability, will not be treated as a violation of Section 9, and we will not pursue legal action against a researcher who complies with this Section and our published disclosure policy (if any).",
                "Any other discovery, use, or exploitation of a Vulnerability — including using it to complete Transactions, obtain funds or Diamonds, alter data, or access accounts — is a breach of Section 9 regardless of the discoverer's original intent, and will be pursued accordingly.",
            ],
        },
        {
            "number": "11",
            "title": "Suspension and Termination",
            "paragraphs": [
                "We may suspend or terminate your account or restrict access to the Platform, at our sole discretion and without liability, immediately and without notice, where we reasonably suspect: breach of these Terms; fraudulent, unlawful, or abusive conduct; a KYC/AML/sanctions concern; a chargeback or payment dispute; or where required by law, a regulator, or a Third-Party Provider.",
                "You may close your account at any time, subject to settlement of all pending Transactions, outstanding fees, and any open disputes.",
                "Sections that by their nature should survive termination (including Sections 4, 6, 9, 12–20) survive termination of your account or these Terms.",
            ],
        },
        {
            "number": "12",
            "title": "Intellectual Property",
            "paragraphs": [
                "The Platform, including its software, design, trademarks, logos, and all underlying technology, is owned by the Company or its licensors and is protected by intellectual property laws. Nothing in these Terms grants you any right or license to use our trademarks, branding, or proprietary technology except as necessary to use the Platform as intended.",
                "By uploading Content (including Listing images, descriptions, and Certificates), you grant the Company a worldwide, royalty-free, non-exclusive, sublicensable license to host, store, reproduce, display, and distribute that Content solely for the purposes of operating, promoting, and improving the Platform. You represent that you own or have the necessary rights to all Content you upload and that it does not infringe any third party's rights.",
            ],
        },
        {
            "number": "13",
            "title": "Disclaimer of Warranties",
            "paragraphs": [
                'TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE PLATFORM IS PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS, WITHOUT WARRANTIES OF ANY KIND, WHETHER EXPRESS, IMPLIED, OR STATUTORY, INCLUDING WITHOUT LIMITATION IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT, ACCURACY, OR UNINTERRUPTED/ERROR-FREE OPERATION.',
                "We do not warrant that the Platform will be uninterrupted, secure, or free of errors, bugs, or Vulnerabilities, and we do not warrant that any defect will be corrected, notwithstanding our reasonable efforts to maintain and secure the Platform.",
            ],
        },
        {
            "number": "14",
            "title": "Limitation of Liability",
            "paragraphs": [
                "TO THE MAXIMUM EXTENT PERMITTED BY LAW, IN NO EVENT SHALL THE COMPANY, ITS AFFILIATES, OFFICERS, EMPLOYEES, OR AGENTS BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, EXEMPLARY, OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS, REVENUE, DATA, GOODWILL, OR BUSINESS OPPORTUNITY, ARISING OUT OF OR RELATING TO THE PLATFORM, ANY TRANSACTION, OR THESE TERMS, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.",
                "TO THE MAXIMUM EXTENT PERMITTED BY LAW, THE COMPANY'S TOTAL AGGREGATE LIABILITY TO YOU FOR ALL CLAIMS ARISING OUT OF OR RELATING TO THE PLATFORM OR THESE TERMS, WHETHER IN CONTRACT, TORT, OR OTHERWISE, SHALL NOT EXCEED THE GREATER OF (A) THE TOTAL FEES YOU PAID TO THE COMPANY (EXCLUDING PASS-THROUGH AMOUNTS TO SELLERS OR THIRD-PARTY PROVIDERS) IN THE TWELVE (12) MONTHS PRECEDING THE EVENT GIVING RISE TO THE CLAIM, OR (B) ONE HUNDRED US DOLLARS (USD 100).",
                "The limitations in this Section do not apply to: (a) liability that cannot be excluded or limited under applicable law (including, in some jurisdictions, liability for fraud, gross negligence, or willful misconduct); or (b) your indemnification obligations under Section 17.",
                "Nothing in this Section limits or excludes the Company's liability for death or personal injury caused by its negligence, or for any liability that cannot lawfully be limited.",
            ],
        },
        {
            "number": "15",
            "title": "Disputes Between Buyers and Sellers",
            "paragraphs": [
                "The Company is not responsible for resolving disputes between Buyers and Sellers regarding Diamond quality, description accuracy, delivery, or payment, except through the optional dispute-resolution assistance process described in Section 16, which is offered as a convenience and not as an admission of liability.",
                "Where the Company offers a dispute-resolution or mediation facility, its decisions on release or return of escrowed funds/goods are administrative determinations made to operationalize the escrow arrangement and do not constitute a legal adjudication of the parties' rights; either party remains free to pursue its legal remedies against the other independently.",
            ],
        },
        {
            "number": "16",
            "title": "Escrow and Transaction Dispute Process",
            "paragraphs": [
                "If a Buyer disputes a Diamond's conformity to its Listing/Certificate within the applicable inspection window, the Buyer may raise a claim through the Platform, supported by evidence (e.g., an independent re-grading report from a Certifying Body).",
                "Pending resolution, escrowed funds and/or the Diamond (if still within our logistics chain) may be held. The Company will make a reasonable, good-faith administrative determination based on the evidence submitted but does not guarantee any particular outcome and is not acting as an arbitrator, expert, or grading authority in doing so.",
                "Either party may escalate an unresolved dispute to the dispute resolution mechanism in Section 19.",
            ],
        },
        {
            "number": "17",
            "title": "Indemnification",
            "paragraphs": [
                "You agree to defend, indemnify, and hold harmless the Company, its affiliates, and their respective officers, directors, employees, and agents from and against any and all claims, liabilities, damages, losses, costs, and expenses (including reasonable legal fees) arising out of or related to: (a) your breach of these Terms, including Section 9 (Prohibited Conduct); (b) your Listings, Content, or the Diamonds you sell, including any claim that a Diamond's description, Certificate, origin, or provenance is inaccurate or unlawful; (c) any Transaction you enter into with another User; (d) your violation of any applicable law, including AML, sanctions, export control, or consumer protection law; or (e) your infringement of any third party's intellectual property or other rights.",
            ],
        },
        {
            "number": "18",
            "title": "Privacy and Data Protection",
            "paragraphs": [
                "Our collection and use of personal data, including KYC data, is governed by our Privacy Policy, which forms part of this Agreement. By using the Platform, you consent to such collection and use, including sharing KYC/AML data with Third-Party Providers and regulators as required by law.",
                "We implement reasonable technical and organizational security measures appropriate to the sensitivity of the data we hold, but no system is completely secure, and we do not guarantee absolute security against unauthorized access.",
            ],
        },
        {
            "number": "19",
            "title": "Governing Law and Dispute Resolution",
            "paragraphs": [
                "Primary Governing Law. Except as provided in the local mandatory law carve-out below, this Agreement is governed by the laws of India, without regard to conflict-of-laws principles.",
                "Arbitration. Any dispute arising out of or relating to this Agreement or the Platform (excluding small claims eligible for a local small-claims court, and excluding claims for injunctive relief to protect intellectual property) shall be referred to and finally resolved by binding arbitration administered under the Arbitration and Conciliation Act, 1996 (India) under its rules then in force, seated in Mumbai, India, conducted in the English language, before one arbitrator. The arbitration award shall be final and binding, and judgment may be entered in any court of competent jurisdiction.",
                "Local Mandatory Law Carve-Out. Where a User resides or is established in a jurisdiction whose mandatory consumer-protection, data-protection, or other non-waivable law grants that User rights or a local forum that cannot lawfully be displaced by the governing law and arbitration clauses above, such mandatory local law and forum apply solely to the extent required, and the remainder of this Agreement continues in full force.",
                "Class Action Waiver. To the extent permitted by applicable law, disputes shall be resolved on an individual basis only, and you waive any right to participate in a class, collective, or representative action against the Company.",
                "Injunctive Relief. Notwithstanding the foregoing, the Company may seek injunctive or equitable relief in any court of competent jurisdiction to prevent actual or threatened infringement, misappropriation, or violation of Section 9 (Prohibited Conduct) or its intellectual property rights.",
            ],
        },
        {
            "number": "20",
            "title": "Regulatory and Trade Compliance",
            "paragraphs": [
                "Sanctions. You represent that you are not, and are not owned or controlled by, a person or entity subject to sanctions administered by the UN, OFAC, EU, UK, or other applicable authority, and that you will not use the Platform to transact with any such sanctioned person or in any sanctioned country.",
                "Anti-Bribery and Anti-Corruption. You agree to comply with all applicable anti-bribery and anti-corruption laws in connection with your use of the Platform.",
                "Payment Services Regulation. Where our Facilitation Services require a local payment-institution, money-services-business, or escrow license in a given country, we will operate through appropriately licensed Third-Party Providers in that country, and our obligations are limited accordingly.",
                "Diamond Trade Law. You agree to comply with all import/export, customs, and diamond-trade-specific laws (including Kimberley Process implementing legislation) applicable to your Transactions.",
            ],
        },
        {
            "number": "21",
            "title": "Force Majeure",
            "paragraphs": [
                "The Company shall not be liable for any failure or delay in performance resulting from causes beyond its reasonable control, including natural disasters, pandemics, war, civil unrest, government action, sanctions changes, customs delays, internet/telecommunications failures, or failures of Third-Party Providers.",
            ],
        },
        {
            "number": "22",
            "title": "Third-Party Providers and Links",
            "paragraphs": [
                "The Platform integrates or links to services operated by independent Third-Party Providers (payment processors, escrow agents, logistics carriers, insurers, Certifying Bodies, KYC vendors). Your use of such services may be subject to their own terms and privacy policies. The Company is not responsible for the acts, omissions, security practices, or solvency of any Third-Party Provider, except to the extent we are found to have been negligent in our selection or oversight of that provider.",
            ],
        },
        {
            "number": "23",
            "title": "Modification of Terms and the Platform",
            "paragraphs": [
                'We may amend these Terms at any time by posting the updated Terms on the Platform and updating the "Last updated" / effective date, and, for material changes, by providing additional notice (e.g., in-app notice or email) at least fourteen (14) days before the change takes effect. Continued use after the effective date constitutes acceptance.',
                "We may modify, suspend, or discontinue any part of the Platform at any time, with or without notice, without liability to you, except for completing Transactions already in progress in good faith.",
            ],
        },
        {
            "number": "24",
            "title": "General Provisions",
            "paragraphs": [
                "Entire Agreement. This Agreement (Terms, Privacy Policy, and any referenced policies) constitutes the entire agreement between you and the Company regarding the Platform and supersedes all prior agreements on the subject.",
                "Severability. If any provision of these Terms is held invalid or unenforceable, that provision shall be limited or eliminated to the minimum extent necessary, and the remaining provisions shall remain in full force and effect.",
                "No Waiver. No failure or delay by the Company in exercising any right under these Terms shall operate as a waiver of that right.",
                "Assignment. You may not assign or transfer your rights or obligations under these Terms without our prior written consent. We may assign these Terms in connection with a merger, acquisition, or sale of assets.",
                "Relationship of Parties. Nothing herein creates any partnership, joint venture, agency, or employment relationship between you and the Company.",
                "Notices. Notices to you may be given by email, in-app notification, or posting on the Platform. Notices to the Company must be sent to m.gemworld@gmail.com.",
                "Grievance Officer. In accordance with applicable Indian law, grievances regarding the Platform may be addressed to our Grievance Officer at m.gemworld@gmail.com.",
                "Language. These Terms are drafted in English. Any translation is provided for convenience only, and the English version shall prevail in case of conflict.",
                "Contact. Questions about these Terms may be directed to m.gemworld@gmail.com or through the Help Center.",
            ],
        },
        {
            "number": "Appendix A",
            "title": "Open Items and Recommended Next Steps",
            "paragraphs": [
                "The following open items are flagged for review by you and your legal counsel before launch. They are points that experience with marketplace platforms suggests are commonly missed, and they sit outside the numbered Sections above:"
            ],
            "bullets": [
                "Confirm whether any Buyers could be classified as \"consumers\" rather than businesses in any target market — this changes which liability exclusions and cancellation/refund rights are enforceable (many countries mandate consumer rights that cannot be waived).",
                "Confirm licensing requirements for holding or moving funds in each country you operate in (money transmitter, payment institution, or escrow licences) — operating without one is a criminal, not merely a contractual, risk.",
                "Decide and document your Refund, Cancellation and Returns Policy — it is only referenced generally in Section 16 and needs concrete timelines (for example, inspection-window length and return-shipping cost allocation).",
                "Confirm the standalone Privacy Policy addresses GDPR (if you have EU/UK users), India's DPDP Act, and other applicable data-protection regimes, as it is referenced throughout these Terms.",
                "Draft a Community/Trust & Safety Policy covering fake-review handling, Seller rating manipulation, and counterfeit-certificate reporting.",
                "Decide the anti-circumvention policy in detail (Section 9) — many marketplaces define a specific \"no off-platform deals for N months after introduction\" rule with liquidated damages.",
                "Confirm insurance coverage: whether the Company needs its own contingent cargo/marine insurance, professional indemnity (E&O) insurance, and cyber-liability insurance, given the liability caps in Section 14.",
                "Age and eligibility: if you ever allow individual (non-business) consumer Buyers, add jewellery-specific consumer protections (for example, cooling-off periods in some countries).",
                "Confirm Google Play policy compliance separately — the Play Store has its own Payments Policy, Financial Services requirements, and User Data policy that may restrict how escrow and payment facilitation are described in-app, independently of these Terms.",
                "Set up a formal incident-response and breach-notification procedure (many jurisdictions impose statutory notification deadlines after a data breach, separate from anything in these Terms).",
                "Consider a separate, shorter Seller Agreement with commercial terms (fees, exclusivity, minimum listing standards) rather than folding everything into consumer-facing Terms.",
            ],
        },
    ],
}


BODIES_PATH = Path(__file__).resolve().parent / "terms_hi_gu_bodies.json"


def _section_shape(section: dict) -> tuple[int, int, bool]:
    return (
        len(section.get("paragraphs", [])),
        len(section.get("bullets", [])),
        bool(section.get("closing")),
    )


def build_locale_terms(
    lang: str, *, title: str, subtitle: str, intro: str, secondary: str
) -> dict:
    """Build a locale Terms bundle from the translated bodies in terms_hi_gu_bodies.json."""
    bodies = json.loads(BODIES_PATH.read_text(encoding="utf-8"))[lang]["sections"]
    en_sections = TERMS_EN["sections"]
    assert len(bodies) == len(en_sections), (
        f"{lang}: {len(bodies)} sections, expected {len(en_sections)}"
    )
    for en_section, locale_section in zip(en_sections, bodies):
        assert en_section["number"] == locale_section["number"], (
            f"{lang}: section numbering drift at {locale_section['number']}"
        )
        assert _section_shape(en_section) == _section_shape(locale_section), (
            f"{lang}: structure drift at section {locale_section['number']}"
        )
    return {
        "id": "terms",
        "title": title,
        "subtitle": subtitle,
        "eyebrow": "GemWorld Marketplace",
        "effectiveDate": EFFECTIVE,
        "intro": intro,
        "secondaryIntro": secondary,
        "sections": bodies,
    }


TERMS_HI = build_locale_terms(
    "hi",
    title="नियम एवं शर्तें",
    subtitle="B2B हीरा बाज़ार उपयोग, KYC/AML, एस्क्रो और दायित्व",
    intro=(
        'ये नियम एवं शर्तें ("शर्तें") आपके ("उपयोगकर्ता," "आप," जिसमें नीचे परिभाषित खरीदार और विक्रेता दोनों शामिल हैं) '
        "और GemWorld (भारत के कानूनों के अंतर्गत संचालित कंपनी; \"कंपनी,\" \"हम,\" \"प्लेटफ़ॉर्म\") के बीच एक कानूनी रूप से "
        "बाध्यकारी समझौता हैं, जो GemWorld मोबाइल ऐप, वेबसाइट और संबंधित सेवाओं (सामूहिक रूप से \"प्लेटफ़ॉर्म\") के "
        "उपयोग को नियंत्रित करती हैं।"
    ),
    secondary=(
        "प्लेटफ़ॉर्म डाउनलोड, इंस्टॉल, पंजीकरण, एक्सेस या किसी भी प्रकार के उपयोग से आप इन शर्तों, हमारी गोपनीयता "
        "नीति, AML/KYC आवश्यकताओं और यहाँ संदर्भित अन्य नीतियों (सामूहिक रूप से \"समझौता\") से बिना शर्त सहमत होते हैं। "
        "यदि आप सहमत नहीं हैं, तो प्लेटफ़ॉर्म का उपयोग न करें। अंग्रेज़ी संस्करण विवाद की स्थिति में प्रभावी होगा।"
    ),
)

TERMS_GU = build_locale_terms(
    "gu",
    title="નિયમો અને શરતો",
    subtitle="B2B હીરા બજાર ઉપયોગ, KYC/AML, એસ્ક્રો અને જવાબદારી",
    intro=(
        'આ નિયમો અને શરતો ("શરતો") તમારા ("વપરાશકર્તા," "તમે," જેમાં નીચે વ્યાખ્યાયિત ખરીદદારો અને વિક્રેતાઓ બંને સામેલ છે) '
        "અને GemWorld (ભારતના કાયદા હેઠળ સંચાલિત કંપની; \"કંપની,\" \"અમે,\" \"પ્લેટફોર્મ\") વચ્ચેનો કાનૂની રીતે બંધનકર્તા "
        "કરાર છે, જે GemWorld મોબાઇલ એપ, વેબસાઇટ અને સંબંધિત સેવાઓ (સામૂહિક રીતે \"પ્લેટફોર્મ\")ના ઉપયોગને નિયંત્રિત કરે છે."
    ),
    secondary=(
        "પ્લેટફોર્મ ડાઉનલોડ, ઇન્સ્ટોલ, નોંધણી, એક્સેસ અથવા કોઈપણ રીતે ઉપયોગ કરીને તમે આ શરતો, અમારી ગોપનીયતા નીતિ, "
        "AML/KYC જરૂરિયાતો અને અહીં સંદર્ભિત અન્ય નીતિઓ (સામૂહિક રીતે \"કરાર\")થી બિનશરતી સંમત થાઓ છો. જો તમે સંમત ન હો, "
        "તો પ્લેટફોર્મનો ઉપયોગ ન કરો. વિવાદની સ્થિતિમાં અંગ્રેજી સંસ્કરણ માન્ય રહેશે."
    ),
)


def replace_terms(path: Path, terms: dict) -> None:
    data = json.loads(path.read_text(encoding="utf-8"))
    policies = data["policies"]
    idx = next(i for i, p in enumerate(policies) if p["id"] == "terms")
    policies[idx] = terms
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"updated {path.name}: terms sections={len(terms['sections'])}")


def main() -> None:
    replace_terms(POLICIES_DIR / "policies.json", TERMS_EN)
    replace_terms(POLICIES_DIR / "policies_hi.json", TERMS_HI)
    replace_terms(POLICIES_DIR / "policies_gu.json", TERMS_GU)


if __name__ == "__main__":
    main()
