import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';

/// Marketplace Terms & Conditions for GemWorld.
class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  static const String effectiveDate = '27 July 2026';

  static const List<_TermsSection> _sections = [
    _TermsSection(
      number: '1',
      title: 'Definitions',
      paragraphs: [
        'In these Terms:',
      ],
      bullets: [
        'Platform means the GemWorld online marketplace, including its websites, applications, and related services.',
        'Buyer means any registered user purchasing products or participating in auctions.',
        'Seller means any registered business or individual authorized to list products.',
        'Products include Natural Diamonds, Lab-Grown Diamonds, Gemstones, Jewelry, Watches, Bullion Products, and Accessories.',
        'Auction means any timed bidding event conducted through the Platform.',
        'User means any buyer, seller, visitor, or auction participant using the Platform.',
        'Order means a request to purchase one or more Products through the Platform.',
      ],
    ),
    _TermsSection(
      number: '2',
      title: 'Eligibility',
      paragraphs: [
        'Users must be at least 18 years old or otherwise have full legal capacity under applicable law.',
        'The Platform reserves the right to refuse registration or terminate any account without prior notice if fraudulent, illegal, or policy-violating activity is suspected.',
        'Businesses registering as sellers must provide accurate business identity, tax, and KYC information as requested during onboarding.',
      ],
    ),
    _TermsSection(
      number: '3',
      title: 'Account Registration',
      paragraphs: [
        'Users must:',
      ],
      bullets: [
        'Provide accurate information.',
        'Keep account information updated.',
        'Maintain password and credential confidentiality.',
        'Be responsible for all activity under their account.',
        'Notify the Platform promptly of any unauthorized access.',
      ],
      closing:
          'Providing false identity, fake documents, or stolen credentials may result in immediate suspension or permanent termination.',
    ),
    _TermsSection(
      number: '4',
      title: 'Marketplace Role',
      paragraphs: [
        'The Platform provides technology to connect buyers and sellers.',
        'Unless specifically stated for a particular listing or transaction, GemWorld is not the owner, manufacturer, or certifier of products listed by independent sellers.',
        'The Platform reserves the right to verify, remove, suspend, or reject any listing, seller, or buyer activity.',
        'GemWorld may act as a facilitator for payments, messaging, dispute handling, and logistics coordination, but that does not make GemWorld a party to every buyer–seller contract unless expressly stated.',
      ],
    ),
    _TermsSection(
      number: '5',
      title: 'Products',
      paragraphs: [
        'Products may include certified natural diamonds, certified lab-grown diamonds, colored gemstones, jewelry, watches, bullion products, and accessories.',
        'Product specifications, grading reports, certifications, weights, measurements, colors, clarity, metal purity, and images are provided for informational purposes.',
        'Slight variations due to photography, monitor settings, lighting, manufacturing tolerances, or natural characteristics are not considered defects.',
      ],
    ),
    _TermsSection(
      number: '6',
      title: 'Product Certifications',
      paragraphs: [
        'Where applicable:',
      ],
      bullets: [
        'Diamonds may include grading reports from recognized gemological laboratories (for example GIA, IGI, or other labs shown on the listing).',
        'Gemstones may include certificates where available.',
        'Bullion products may include purity markings and assay documentation where applicable.',
        'Watches may include authenticity documentation, warranty cards, or serial verification where applicable.',
      ],
      closing:
          'Buyers are encouraged to review all available documentation before purchasing. Certification does not guarantee future resale value.',
    ),
    _TermsSection(
      number: '7',
      title: 'Pricing',
      paragraphs: [
        'Prices are displayed in the applicable marketplace currency (primarily Indian Rupees (INR) unless otherwise stated).',
        'The Platform reserves the right to:',
      ],
      bullets: [
        'Correct pricing errors.',
        'Cancel orders with obvious pricing mistakes.',
        'Modify pricing without prior notice.',
        'Apply taxes (including GST where applicable), duties, shipping charges, insurance, or service fees.',
        'Display seller commissions or marketplace fees separately where required.',
      ],
    ),
    _TermsSection(
      number: '8',
      title: 'Orders',
      paragraphs: [
        'Placing an order does not guarantee acceptance. An order becomes binding only when confirmed by the Platform and/or seller according to checkout terms.',
        'Orders may be cancelled due to:',
      ],
      bullets: [
        'Product unavailability',
        'Pricing errors',
        'Suspected fraud',
        'Payment failure',
        'Compliance or KYC requirements',
        'Government or trade restrictions',
        'Seller policy or inventory conflicts',
      ],
      closing:
          'If payment has already been received for a cancelled order, the amount will be refunded according to the Refund Policy. The Platform may accept an order in whole or in part.',
    ),
    _TermsSection(
      number: '9',
      title: 'Payment',
      paragraphs: [
        'Accepted payment methods may include:',
      ],
      bullets: [
        'Bank Transfer / NEFT / RTGS / IMPS',
        'Credit / Debit Cards',
        'Online Payment Gateways UPI and similar methods',
        'Wallet Payments',
        'Other approved payment methods',
      ],
      closing:
          'Orders will not be processed until payment is successfully verified. The Platform may request identity verification, source-of-funds information, or additional documentation before processing high-value transactions. Chargebacks filed in bad faith may result in account restrictions.',
    ),
    _TermsSection(
      number: '10',
      title: 'Auction Terms',
      paragraphs: [
        '10.1 Auction Participation — Only verified users may participate. Every bid placed is legally binding. Users must bid responsibly. Fake bidding, shill bidding, bid manipulation, or collusion is strictly prohibited.',
        '10.2 Winning an Auction — The highest valid bidder at auction close becomes the winning buyer. Winning an auction creates a legally binding obligation to purchase.',
        '10.3 Payment Deadline — The winning bidder must complete payment within 48 hours (1–2 calendar days) after the auction ends. Failure to pay within this period may result in temporary suspension from auctions, cancellation of the winning bid, loss of bidding privileges, account restrictions, and/or additional verification before future participation. Repeated violations may result in permanent removal from the Platform.',
        '10.4 Non-Payment — If payment is not received, the seller may offer the product to another buyer, the auction may be restarted, and the Platform may charge applicable penalties where permitted by law.',
        '10.5 Auction Cancellation — The Platform may cancel or suspend an auction if fraud is suspected, listing errors exist, the product becomes unavailable, technical issues affect bidding, or the seller violates marketplace rules.',
        '10.6 Bid Retraction — Bids generally cannot be withdrawn. Bid cancellation requests may only be accepted under exceptional circumstances determined solely by the Platform.',
      ],
    ),
    _TermsSection(
      number: '11',
      title: 'Seller Terms',
      paragraphs: [
        'Sellers agree to:',
      ],
      bullets: [
        'List only genuine products.',
        'Accurately describe products.',
        'Upload authentic images of the actual or representative item as disclosed.',
        'Provide correct certifications.',
        'Maintain inventory accuracy.',
        'Ship products within required timelines.',
        'Comply with applicable laws, tax obligations, and trade regulations.',
        'Pay applicable marketplace fees and commissions on time.',
      ],
    ),
    _TermsSection(
      number: '12',
      title: 'Seller Responsibilities',
      paragraphs: [
        'Sellers must not:',
      ],
      bullets: [
        'Sell counterfeit, stolen, or illegally sourced goods.',
        'Misrepresent product quality, origin, treatment, or certification.',
        'Use misleading descriptions or images.',
        'Manipulate prices or reviews.',
        'Circumvent platform fees.',
        'Conduct transactions outside the Platform after a buyer introduction made through GemWorld.',
        'List products subject to unresolved legal claims or export restrictions.',
      ],
      closing:
          'Violations may result in listing removal, fee recovery, suspension, or permanent removal.',
    ),
    _TermsSection(
      number: '13',
      title: 'Inventory Accuracy',
      paragraphs: [
        'Sellers must ensure listed inventory is available for sale.',
        'Repeated order cancellations due to unavailable inventory may result in penalties, reduced visibility, or account restrictions.',
      ],
    ),
    _TermsSection(
      number: '14',
      title: 'Shipping',
      paragraphs: [
        'Shipping times are estimates only.',
        'Delays caused by customs, natural disasters, transportation disruptions, government actions, courier delays, or similar events shall not constitute a breach of these Terms.',
        'Risk of loss and title transfer according to the applicable shipping terms stated at checkout (for example, when handed to the carrier or upon delivery).',
        'Buyers are responsible for providing accurate shipping addresses and for any duties, taxes, or clearance requirements applicable in the destination jurisdiction unless otherwise stated.',
      ],
    ),
    _TermsSection(
      number: '15',
      title: 'Delivery',
      paragraphs: [
        'Buyers must inspect products upon delivery.',
        'Any shipping damage, shortage, or obvious discrepancy should be reported promptly with supporting photographs and documentation through official support channels.',
        'Failure to report visible damage within a reasonable time may affect eligibility for remedies under the Return or Refund Policy.',
      ],
    ),
    _TermsSection(
      number: '16',
      title: 'Returns',
      paragraphs: [
        'Returns are accepted only in accordance with the Platform\'s Return Policy.',
        'Returned products must generally be unused, unworn, unaltered, in original packaging, and accompanied by certificates and accessories.',
        'Customized, engraved, specially ordered, or made-to-order items may not be eligible for return unless defective or misrepresented.',
        'Certain categories (including opened bullion, cut-to-order stones, or items marked non-returnable) may have limited or no return rights except where required by law.',
      ],
    ),
    _TermsSection(
      number: '17',
      title: 'Refunds',
      paragraphs: [
        'Approved refunds will be processed using the original payment method where possible.',
        'Refund processing times may vary depending on payment providers and financial institutions.',
        'Partial refunds may apply where only part of an order is cancelled, returned, or unavailable.',
      ],
    ),
    _TermsSection(
      number: '18',
      title: 'Authenticity',
      paragraphs: [
        'The Platform reserves the right to verify the authenticity of any product before shipment or after a dispute is raised.',
        'If a listed product is determined to be counterfeit or materially misrepresented, the listing may be removed and the seller\'s account may be suspended or terminated.',
        'Buyers may be offered a refund, replacement, or other remedy according to Platform policies and applicable law.',
      ],
    ),
    _TermsSection(
      number: '19',
      title: 'Bullion Products',
      paragraphs: [
        'Bullion prices fluctuate with market conditions.',
        'Once an order for bullion is confirmed, it may not be cancelled except where required by applicable law.',
        'Premiums, making charges, and assay or packaging fees may apply in addition to spot-related pricing.',
      ],
    ),
    _TermsSection(
      number: '20',
      title: 'Watches',
      paragraphs: [
        'Mechanical watches may have normal manufacturing tolerances in accuracy.',
        'Water resistance ratings apply only under manufacturer-specified testing conditions and do not guarantee suitability for all environments.',
        'Service history, box/papers completeness, and modification status (where disclosed) form part of the product description buyers should review before purchase.',
      ],
    ),
    _TermsSection(
      number: '21',
      title: 'Trade Compliance & Ethical Sourcing',
      paragraphs: [
        'Users must comply with applicable export, import, customs, sanctions, and anti-money-laundering laws.',
        'Sellers of natural diamonds represent that goods are not knowingly conflict diamonds and, where applicable, comply with Kimberley Process or equivalent trade requirements.',
        'GemWorld may request sourcing declarations, KYC documents, or transaction records for compliance review.',
        'Users must not use the Platform to launder money, evade taxes, or circumvent trade sanctions.',
      ],
    ),
    _TermsSection(
      number: '22',
      title: 'Prohibited Activities',
      paragraphs: [
        'Users may not:',
      ],
      bullets: [
        'Commit fraud',
        'Use stolen payment methods',
        'Engage in money laundering',
        'Manipulate auctions',
        'Submit fake reviews',
        'Impersonate others',
        'Upload malicious software',
        'Attempt unauthorized access to the Platform',
        'Scrape or copy marketplace data without authorization',
        'Harass other users or Platform staff',
        'Interfere with Platform security, availability, or fair pricing',
      ],
    ),
    _TermsSection(
      number: '23',
      title: 'Intellectual Property',
      paragraphs: [
        'All Platform content, including logos, trademarks, software, text, graphics, photographs, videos, and designs, is protected by applicable intellectual property laws.',
        'Unauthorized use, reproduction, or redistribution is prohibited.',
        'Seller product images and descriptions remain subject to the seller\'s rights and the license granted to GemWorld to operate the marketplace.',
      ],
    ),
    _TermsSection(
      number: '24',
      title: 'User Content',
      paragraphs: [
        'Users granting reviews, photographs, messages, chatbot conversations, or other content provide the Platform with a non-exclusive, worldwide, royalty-free license to host, display, and use such content for marketplace operations and promotional purposes.',
        'Users represent that their content does not infringe third-party rights and is not unlawful, defamatory, or misleading.',
        'GemWorld may remove user content that violates these Terms or applicable law.',
      ],
    ),
    _TermsSection(
      number: '25',
      title: 'AI Chatbot & Model Training',
      paragraphs: [
        'GemWorld may offer an AI-powered chatbot and similar automated assistants to help users browse products, get support, and navigate the marketplace.',
        'By using the chatbot or any automated assistant on the Platform, you expressly agree that GemWorld may collect, store, retain, and process your chat conversations, including messages you send and responses you receive.',
        'Chat data may be used to:',
      ],
      bullets: [
        'Improve chatbot accuracy, relevance, and overall user experience.',
        'Train, fine-tune, evaluate, and develop artificial intelligence and machine-learning models.',
        'Analyze usage patterns, detect abuse, and troubleshoot technical issues.',
        'Maintain records for customer support, quality assurance, and compliance.',
      ],
      closing:
          'Where reasonably practicable, GemWorld may remove or anonymize personal identifiers before using chat data for model training. Do not share passwords, payment card numbers, government ID numbers, or other highly sensitive information in chatbot conversations. Chat data may be retained according to the Privacy Policy and applicable law. Your use of the chatbot constitutes consent to this data use. Continued use after updates to these Terms constitutes acceptance of the revised data-use terms.',
    ),
    _TermsSection(
      number: '26',
      title: 'Fraud Prevention',
      paragraphs: [
        'The Platform may:',
      ],
      bullets: [
        'Verify identity',
        'Verify payment methods',
        'Request additional documentation',
        'Delay shipment for security review',
        'Suspend suspicious transactions',
        'Share information with payment partners or authorities where legally required',
      ],
    ),
    _TermsSection(
      number: '27',
      title: 'Indemnification',
      paragraphs: [
        'Users agree to indemnify and hold harmless GemWorld, its affiliates, officers, and employees from claims, losses, damages, and expenses (including reasonable legal fees) arising from their misuse of the Platform, breach of these Terms, infringement of third-party rights, or unlawful listings or purchases.',
      ],
    ),
    _TermsSection(
      number: '28',
      title: 'Limitation of Liability',
      paragraphs: [
        'To the maximum extent permitted by law, the Platform shall not be liable for indirect, incidental, special, punitive, or consequential damages arising from the use of the marketplace, including lost profits, lost data, or business interruption.',
        'Except where prohibited by law, GemWorld\'s aggregate liability related to any claim shall not exceed the fees paid to GemWorld for the specific transaction giving rise to the claim, or a reasonable limited amount where no fee was paid.',
        'Nothing in these Terms excludes liability for fraud, willful misconduct, or other liability that cannot be limited under applicable law.',
      ],
    ),
    _TermsSection(
      number: '29',
      title: 'Force Majeure',
      paragraphs: [
        'The Platform shall not be liable for delays or failures caused by events beyond reasonable control, including natural disasters, war, cyberattacks, labor disputes, governmental actions, epidemic events, or communication failures.',
      ],
    ),
    _TermsSection(
      number: '30',
      title: 'Privacy',
      paragraphs: [
        'Personal information is collected and processed in accordance with the Platform\'s Privacy Policy.',
        'This includes chatbot conversation data collected under Section 25 (AI Chatbot & Model Training).',
        'By using the Platform, you consent to electronic communications related to your account, orders, security alerts, and service notices.',
      ],
    ),
    _TermsSection(
      number: '31',
      title: 'Account Suspension & Termination',
      paragraphs: [
        'Accounts may be suspended or permanently terminated for fraud, non-payment, counterfeit listings, repeated policy violations, abuse of the Platform, auction manipulation, chargeback abuse, or illegal activities.',
        'Users may request account closure through official support channels, subject to completion of open orders, disputes, and outstanding fees.',
        'Provisions that by nature should survive (including intellectual property, indemnification, limitation of liability, and dispute resolution) survive termination.',
      ],
    ),
    _TermsSection(
      number: '32',
      title: 'Dispute Resolution',
      paragraphs: [
        'Users should first attempt to resolve disputes through the Platform\'s dispute process.',
        'If unresolved, disputes shall be governed by the applicable laws and courts specified below, unless mandatory consumer protection laws provide otherwise.',
        'Nothing in this section prevents either party from seeking interim injunctive relief for intellectual property or security threats.',
      ],
    ),
    _TermsSection(
      number: '33',
      title: 'Governing Law',
      paragraphs: [
        'These Terms shall be governed by the laws of India.',
        'Subject to mandatory consumer protection rights, courts in India shall have jurisdiction over disputes arising from these Terms, unless the Platform designates a specific city or forum in a later update.',
      ],
    ),
    _TermsSection(
      number: '34',
      title: 'Changes to Terms',
      paragraphs: [
        'The Platform may modify these Terms at any time by posting an updated version on the Platform.',
        'Continued use of the Platform after updates constitutes acceptance of the revised Terms.',
        'Material changes may also be communicated through account notices or email where reasonably practicable.',
      ],
    ),
    _TermsSection(
      number: '35',
      title: 'General Provisions',
      paragraphs: [
        'Severability — If any provision of these Terms is held invalid or unenforceable, the remaining provisions continue in full force.',
        'Waiver — Failure by GemWorld to enforce any right is not a waiver of that right.',
        'Assignment — Users may not assign these Terms without prior written consent. GemWorld may assign these Terms in connection with a merger, acquisition, or corporate reorganization.',
        'Entire Agreement — These Terms, together with the Privacy Policy, Return Policy, Refund Policy, and any category-specific policies referenced on the Platform, constitute the entire agreement between you and GemWorld regarding use of the marketplace.',
        'Language — These Terms are provided in English. If translated, the English version controls to the extent permitted by law.',
        'Third-party services — The Platform may integrate payment, logistics, authentication, or analytics providers. Their terms may apply to the relevant service.',
      ],
    ),
    _TermsSection(
      number: '36',
      title: 'Contact',
      paragraphs: [
        'Questions regarding these Terms may be submitted through the official customer support channels provided on the Platform, including the Help Center.',
      ],
    ),
  ];

  static const List<String> _buyerAcknowledgement = [
    'All information provided is accurate.',
    'They understand the product specifications and available documentation.',
    'They agree to complete payment within the required timeframe.',
    'They understand auction bids are binding.',
    'They consent to the collection and use of chatbot conversations for AI model training as described in these Terms.',
    'They accept these Terms and related marketplace policies.',
  ];

  static const List<String> _sellerAcknowledgement = [
    'All listed products are genuine.',
    'Product information is accurate.',
    'They possess the legal right to sell the listed products.',
    'They will fulfill orders promptly.',
    'They will comply with all marketplace policies and applicable laws.',
    'They consent to the collection and use of chatbot conversations for AI model training as described in these Terms.',
    'They understand that repeated policy violations may result in suspension or permanent removal from the Platform.',
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 720;
    final horizontal = isWide ? AppSpacing.s48 : AppSpacing.s20;

    return AppScaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        backgroundColor: AppColors.creamBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRouteNames.home),
        ),
        title: Text(
          'Terms & Conditions',
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              AppSpacing.s8,
              horizontal,
              AppSpacing.s48,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'GemWorld Marketplace',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.bronze,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Terms & Conditions',
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Effective Date: $effectiveDate',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                Text(
                  'Welcome to GemWorld. These Terms & Conditions ("Terms") '
                  'govern the use of our platform by buyers, sellers, '
                  'visitors, and auction participants.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondaryLight,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                Text(
                  'By creating an account, browsing the platform, listing '
                  'products, placing bids, purchasing products, using our '
                  'AI chatbot, or using any services offered through the '
                  'platform, you agree to comply with these Terms — including '
                  'consent to chatbot conversation data being used to train '
                  'and improve our AI models.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondaryLight,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
                for (final section in _sections) ...[
                  _SectionCard(section: section),
                  const SizedBox(height: AppSpacing.s16),
                ],
                _AcknowledgementCard(
                  title: 'Buyer Acknowledgement',
                  intro:
                      'By placing an order or participating in an auction, '
                      'the buyer confirms that:',
                  bullets: _buyerAcknowledgement,
                ),
                const SizedBox(height: AppSpacing.s16),
                _AcknowledgementCard(
                  title: 'Seller Acknowledgement',
                  intro:
                      'By listing products, the seller confirms that:',
                  bullets: _sellerAcknowledgement,
                ),
                const SizedBox(height: AppSpacing.s24),
                _SupportCard(
                  onHelpTap: () =>
                      context.push(AppRouteNames.buyerHelpCenter),
                  onAboutTap: () => context.push(AppRouteNames.aboutUs),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsSection {
  const _TermsSection({
    required this.number,
    required this.title,
    required this.paragraphs,
    this.bullets = const [],
    this.closing,
  });

  final String number;
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  final String? closing;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final _TermsSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${section.number}. ${section.title}',
            style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.s12),
          for (var i = 0; i < section.paragraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.s8),
            Text(
              section.paragraphs[i],
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.55,
                fontSize: 15,
              ),
            ),
          ],
          if (section.bullets.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s8),
            for (final bullet in section.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.bronze,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Text(
                        bullet,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondaryLight,
                          height: 1.55,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (section.closing != null) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              section.closing!,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.55,
                fontSize: 15,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AcknowledgementCard extends StatelessWidget {
  const _AcknowledgementCard({
    required this.title,
    required this.intro,
    required this.bullets,
  });

  final String title;
  final String intro;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: AppColors.charcoal.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            intro,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.55,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppColors.bronze,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(
                      bullet,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondaryLight,
                        height: 1.55,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.onHelpTap,
    required this.onAboutTap,
  });

  final VoidCallback onHelpTap;
  final VoidCallback onAboutTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need help?',
            style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'For questions about these Terms, orders, or account issues, '
            'contact support through the Help Center.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.55,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              OutlinedButton(
                onPressed: onHelpTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: const BorderSide(color: AppColors.warmBorder),
                ),
                child: const Text('Help Center'),
              ),
              TextButton(
                onPressed: onAboutTap,
                child: Text(
                  'About GemWorld',
                  style: AppTypography.label.copyWith(
                    color: AppColors.bronze,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
