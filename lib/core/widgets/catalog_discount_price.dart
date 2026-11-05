import 'package:flutter/material.dart';
import 'package:gemworld/core/theme/app_fonts.dart';

import '../theme/app_colors.dart';
import '../utils/app_currency.dart';
import '../utils/format_catalog_price.dart';

/// Net sale price in green with optional struck-through list / RAP total.
class CatalogDiscountPrice extends StatelessWidget {
  const CatalogDiscountPrice({
    required this.net,
    super.key,
    this.discount,
    this.listOverride,
    this.textColor,
    this.fontSize = 14,
    this.format = formatCatalogPrice,
  });

  final double net;
  final double? discount;
  final double? listOverride;
  final Color? textColor;
  final double fontSize;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final markdown = catalogMarkdownPercent(discount);
    final inferred = markdown == null
        ? null
        : catalogListFromNet(net, markdown);
    final list = listOverride != null && listOverride! > net
        ? listOverride
        : (inferred != null && inferred > net ? inferred : null);
    final primary = textColor ?? AppColors.textPrimary(context);
    final saleStyle = AppFonts.primary(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      height: 1.2,
    ).copyWith(color: list != null ? AppColors.success : primary);

    if (list == null) {
      return Text(
        AppCurrency.format(format(net)),
        style: saleStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppCurrency.format(format(list)),
          style:
              AppFonts.primary(
                fontSize: fontSize * 0.78,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ).copyWith(
                color: AppColors.textMuted(context),
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.textMuted(context),
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          AppCurrency.format(format(net)),
          style: saleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
