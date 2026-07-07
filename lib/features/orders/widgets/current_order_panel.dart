import 'package:flutter/material.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/orders/order.dart';
import '../../../data/models/orders/order_selection.dart';
import '../../../data/models/products/product.dart';
import '../../../shared/widgets/safe_app_image.dart';
import 'order_item_row.dart';

class CurrentOrderPanel extends StatefulWidget {
  const CurrentOrderPanel({
    super.key,
    required this.order,
    required this.visibleSelections,
    required this.visibleTotal,
    required this.visibleItemCount,
    required this.tableName,
    required this.onSendToKitchen,
    required this.onEditSelection,
    required this.onSaveSelectionComment,
    required this.onDeleteSelection,
    required this.resolveProductById,
    required this.sending,
    required this.canSendToKitchen,
    required this.canEditSelection,
    required this.canEditSelectionComment,
    required this.canDeleteSelection,
    required this.statusLabelForSelection,
  });

  final Order? order;
  final List<OrderSelection> visibleSelections;
  final double visibleTotal;
  final int visibleItemCount;
  final String tableName;
  final Future<bool> Function() onSendToKitchen;
  final Future<void> Function(OrderSelection selection) onEditSelection;
  final Future<bool> Function(OrderSelection selection, String comment)
  onSaveSelectionComment;
  final Future<void> Function(OrderSelection selection) onDeleteSelection;
  final Product? Function(int productId) resolveProductById;
  final bool sending;
  final bool canSendToKitchen;
  final bool Function(OrderSelection selection) canEditSelection;
  final bool Function(OrderSelection selection) canEditSelectionComment;
  final bool Function(OrderSelection selection) canDeleteSelection;
  final String Function(OrderSelection selection) statusLabelForSelection;

  @override
  State<CurrentOrderPanel> createState() => _CurrentOrderPanelState();
}

class _CurrentOrderPanelState extends State<CurrentOrderPanel> {
  bool _isSending = false;

  void _debugLog(String message) {
    assert(() {
      debugPrint('[CurrentOrderPanel] $message');
      return true;
    }());
  }

  Future<void> _handleSendToKitchen() async {
    _debugLog(
      'Tap enviar: canSend=${widget.canSendToKitchen}, '
      'widgetSending=${widget.sending}, localSending=$_isSending, '
      'visibleSelections=${widget.visibleSelections.length}',
    );

    if (_isSending || widget.sending || !widget.canSendToKitchen) {
      _debugLog('Envio bloqueado antes de iniciar.');
      return;
    }

    setState(() {
      _isSending = true;
    });
    _debugLog('Spinner local activado.');

    try {
      final success = await widget.onSendToKitchen();
      _debugLog('Callback onSendToKitchen completado con success=$success.');

      if (!mounted) return;
      if (!success) {
        setState(() {
          _isSending = false;
        });
        _debugLog('Envio sin exito. Boton restaurado.');
        return;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      _debugLog('Excepcion en el callback. Boton restaurado.');
      rethrow;
    }

    if (!mounted) return;
    setState(() {
      _isSending = false;
    });
    _debugLog('Envio exitoso. Estado local restablecido.');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final responsive = AppResponsive.of(context);
    final selections = widget.visibleSelections;
    final hasSelections = selections.isNotEmpty;
    final order = widget.order;
    final isSending = widget.sending || _isSending;
    final legacyItems = order?.items ?? const [];
    final itemCount = hasSelections
        ? widget.visibleItemCount
        : legacyItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final computedTotal = hasSelections
        ? widget.visibleTotal
        : (order?.total ??
              legacyItems.fold<double>(0, (sum, item) => sum + item.total));
    final hasItemsToSend = widget.canSendToKitchen;
    final hasOrderSummary = itemCount > 0 || computedTotal > 0;
    final showPendingSyncState =
        !hasSelections && legacyItems.isEmpty && hasOrderSummary;
    final shouldShowEmptyState = !hasSelections && legacyItems.isEmpty;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(responsive.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(responsive.productListCardPadding),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(
                  responsive.productListCardRadius,
                ),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: responsive.productListImageSize,
                    height: responsive.productListImageSize,
                    padding: EdgeInsets.all(responsive.productListImagePadding),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F1E6),
                      borderRadius: BorderRadius.circular(
                        responsive.productListImageRadius,
                      ),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: responsive.iconSize,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: responsive.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orden actual',
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: responsive.orderTitleFontSize,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: responsive.spacingXs / 2),
                        Text(
                          widget.tableName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: responsive.captionFontSize,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacingSm,
                      vertical: responsive.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      hasSelections
                          ? (itemCount == 1
                                ? '1 seleccion'
                                : '$itemCount selecciones')
                          : (itemCount == 1 ? '1 item' : '$itemCount items'),
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacingMd),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  responsive.spacingSm,
                  responsive.spacingSm,
                  responsive.spacingSm,
                  responsive.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softBackground,
                  borderRadius: BorderRadius.circular(
                    responsive.productListCardRadius,
                  ),
                  border: Border.all(color: AppColors.border),
                ),
                child: shouldShowEmptyState
                    ? Center(
                        child: Text(
                          showPendingSyncState
                              ? 'Estamos actualizando los productos de esta orden.'
                              : 'Aun no hay productos agregados.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: responsive.orderBodyFontSize,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : hasSelections
                    ? ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(bottom: responsive.spacingSm),
                        itemCount: selections.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: responsive.spacingSm),
                        itemBuilder: (context, index) {
                          final selection = selections[index];
                          return _SelectionCard(
                            selection: selection,
                            responsive: responsive,
                            canEdit: widget.canEditSelection(selection),
                            canEditComment: widget.canEditSelectionComment(
                              selection,
                            ),
                            canDelete: widget.canDeleteSelection(selection),
                            statusLabel: widget.statusLabelForSelection(
                              selection,
                            ),
                            onEdit: () => widget.onEditSelection(selection),
                            onEditComment: () =>
                                _showEditCommentDialog(context, selection),
                            onDelete: () =>
                                _confirmDeleteSelection(context, selection),
                            resolveProductById: widget.resolveProductById,
                          );
                        },
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(bottom: responsive.spacingSm),
                        itemCount: legacyItems.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: responsive.spacingSm),
                        itemBuilder: (context, index) => OrderItemRow(
                          item: legacyItems[index],
                          responsive: responsive,
                          showActions: false,
                        ),
                      ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                responsive.spacingLg,
                responsive.spacingMd,
                responsive.spacingLg,
                responsive.spacingLg,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 22,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total',
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: responsive.orderTitleFontSize,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(computedTotal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(
                          fontSize: responsive.orderTotalFontSize,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacingMd),
                  SizedBox(
                    height: responsive.orderActionButtonHeight,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSending || !hasItemsToSend
                          ? null
                          : _handleSendToKitchen,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor: AppColors.primary.withValues(
                          alpha: 0.55,
                        ),
                        disabledForegroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: TextStyle(
                          fontSize: responsive.orderBodyFontSize.clamp(
                            15.0,
                            17.0,
                          ),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: isSending
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: const AlwaysStoppedAnimation(
                                      AppColors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: responsive.spacingSm),
                                const Text('Enviando...'),
                              ],
                            )
                          : const Text('Enviar a Cocina'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSelection(
    BuildContext context,
    OrderSelection selection,
  ) async {
    final responsive = AppResponsive.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.productListCardRadius),
        ),
        title: Text(
          'Eliminar seleccion',
          style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
            fontSize: responsive.orderTitleFontSize,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Seguro que quieres eliminar esta seleccion?',
          style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
            fontSize: responsive.orderBodyFontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        actionsPadding: EdgeInsets.fromLTRB(
          responsive.spacingXl,
          0,
          responsive.spacingXl,
          responsive.spacingXl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              minimumSize: const Size(96, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.onDeleteSelection(selection);
    }
  }

  Future<void> _showEditCommentDialog(
    BuildContext context,
    OrderSelection selection,
  ) async {
    final responsive = AppResponsive.of(context);
    var comment = selection.displayComment;
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.white,
          surfaceTintColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              responsive.productListCardRadius,
            ),
          ),
          title: Text(
            'Editar comentario',
            style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
              fontSize: responsive.orderTitleFontSize,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          content: TextFormField(
            initialValue: comment,
            enabled: !isSaving,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              comment = value;
            },
            decoration: const InputDecoration(hintText: 'Agrega un comentario'),
          ),
          actionsPadding: EdgeInsets.fromLTRB(
            responsive.spacingXl,
            0,
            responsive.spacingXl,
            responsive.spacingXl,
          ),
          actions: [
            TextButton(
              onPressed: isSaving
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() {
                        isSaving = true;
                      });

                      final saved = await widget.onSaveSelectionComment(
                        selection,
                        comment.trim(),
                      );

                      if (!dialogContext.mounted) {
                        return;
                      }

                      if (saved) {
                        Navigator.of(dialogContext).pop();
                        return;
                      }

                      setDialogState(() {
                        isSaving = false;
                      });
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                minimumSize: const Size(96, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(AppColors.white),
                      ),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.selection,
    required this.responsive,
    required this.canEdit,
    required this.canEditComment,
    required this.canDelete,
    required this.statusLabel,
    required this.onEdit,
    required this.onEditComment,
    required this.onDelete,
    required this.resolveProductById,
  });

  final OrderSelection selection;
  final AppResponsive responsive;
  final bool canEdit;
  final bool canEditComment;
  final bool canDelete;
  final String statusLabel;
  final Future<void> Function() onEdit;
  final Future<void> Function() onEditComment;
  final Future<void> Function() onDelete;
  final Product? Function(int productId) resolveProductById;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final comment = selection.displayComment;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canEdit ? () => onEdit() : null,
        borderRadius: BorderRadius.circular(responsive.productListCardRadius),
        child: Ink(
          padding: EdgeInsets.all(responsive.productListCardPadding),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(
              responsive.productListCardRadius,
            ),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selection.label.isNotEmpty
                              ? selection.label
                              : 'Seleccion ${selection.sequenceNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: responsive.orderTitleFontSize,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: responsive.spacingXs / 2),
                        _SelectionStatusChip(
                          label: statusLabel,
                          responsive: responsive,
                        ),
                      ],
                    ),
                  ),
                  if (canEdit) ...[
                    SizedBox(width: responsive.spacingSm),
                    _SelectionActionButton(
                      icon: Icons.edit_outlined,
                      responsive: responsive,
                      onPressed: () {
                        onEdit();
                      },
                    ),
                  ],
                  if (canEditComment) ...[
                    SizedBox(width: responsive.spacingSm),
                    _SelectionActionButton(
                      icon: Icons.edit_note_rounded,
                      responsive: responsive,
                      onPressed: () {
                        onEditComment();
                      },
                    ),
                  ],
                  if (canDelete) ...[
                    SizedBox(width: responsive.spacingSm),
                    _SelectionActionButton(
                      icon: Icons.delete_outline_rounded,
                      responsive: responsive,
                      onPressed: () {
                        onDelete();
                      },
                    ),
                  ],
                  if (canEdit || canEditComment || canDelete)
                    SizedBox(width: responsive.spacingSm),
                  Text(
                    CurrencyFormatter.format(selection.total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: responsive.orderBodyFontSize,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (comment.isNotEmpty) ...[
                SizedBox(height: responsive.spacingXs),
                Text(
                  comment,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: responsive.captionFontSize,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              SizedBox(height: responsive.spacingSm),
              ..._buildItems(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildItems(BuildContext context) {
    if (selection.items.isEmpty) {
      return [
        Container(
          padding: EdgeInsets.all(responsive.productListCardPadding),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(
              responsive.productListCardRadius,
            ),
          ),
          child: Text(
            'Los detalles de esta seleccion se estan actualizando.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: responsive.captionFontSize,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ];
    }

    final sortedItems =
        selection.items.where((item) => item.quantity > 0).toList()
          ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));

    if (sortedItems.isEmpty) {
      return const [];
    }

    return [
      for (var index = 0; index < sortedItems.length; index++) ...[
        _SelectionItemRow(
          product: resolveProductById(sortedItems[index].productId),
          productName: sortedItems[index].productName.trim().isEmpty
              ? 'Producto no disponible'
              : sortedItems[index].productName,
          quantity: sortedItems[index].quantity,
          unitPrice: sortedItems[index].unitPrice,
          total: sortedItems[index].total,
          roleLabel: _roleLabel(sortedItems[index].role),
          responsive: responsive,
        ),
        if (index < sortedItems.length - 1)
          SizedBox(height: responsive.spacingSm),
      ],
    ];
  }

  String _roleLabel(int role) {
    switch (role) {
      case 1:
        return 'Platillo principal';
      case 2:
        return 'Bebida';
      case 3:
      default:
        return 'Extra';
    }
  }
}

class _SelectionStatusChip extends StatelessWidget {
  const _SelectionStatusChip({required this.label, required this.responsive});

  final String label;
  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacingSm,
          vertical: responsive.spacingXs / 2,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SelectionActionButton extends StatelessWidget {
  const _SelectionActionButton({
    required this.icon,
    required this.responsive,
    required this.onPressed,
  });

  final IconData icon;
  final AppResponsive responsive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final buttonSize = responsive.productDetailCounterButtonSize
        .clamp(44.0, 48.0)
        .toDouble();

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.zero,
          minimumSize: Size(buttonSize, buttonSize),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, size: responsive.iconSize.clamp(22.0, 26.0)),
      ),
    );
  }
}

class _SelectionItemRow extends StatelessWidget {
  const _SelectionItemRow({
    required this.product,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.roleLabel,
    required this.responsive,
  });

  final Product? product;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double total;
  final String roleLabel;
  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final imagePath = _resolveSelectionItemImage(
      product,
      roleLabel,
      productName,
    );
    final fallbackIcon = _resolveSelectionItemIcon(roleLabel);

    return Container(
      padding: EdgeInsets.all(responsive.productListCardPadding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(responsive.productListCardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: responsive.productListImageSize.clamp(52.0, 64.0),
            height: responsive.productListImageSize.clamp(52.0, 64.0),
            padding: EdgeInsets.all(responsive.spacingXs + 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1E6),
              borderRadius: BorderRadius.circular(
                responsive.productListImageRadius,
              ),
            ),
            child: SafeAppImage.asset(
              assetPath: imagePath,
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.circular(
                responsive.productListImageRadius - 6,
              ),
              fallbackIcon: fallbackIcon,
              fit: BoxFit.contain,
              iconSize: responsive.iconSize + 4,
              iconColor: AppColors.primary,
              backgroundColor: const Color(0xFFF7F1E6),
            ),
          ),
          SizedBox(width: responsive.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  roleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: responsive.captionFontSize,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: responsive.spacingXs / 2),
                Text(
                  productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: responsive.orderBodyFontSize,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacingXs),
                Text(
                  quantity == 1 ? '1x' : '${quantity}x',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: responsive.captionFontSize,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: responsive.spacingXs / 2),
                Text(
                  '${CurrencyFormatter.format(unitPrice)} c/u',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: responsive.captionFontSize,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: responsive.spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total',
                style: textTheme.bodySmall?.copyWith(
                  fontSize: responsive.captionFontSize,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: responsive.spacingXs / 2),
              Text(
                CurrencyFormatter.format(total),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontSize: responsive.orderBodyFontSize,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const String _productImagesBasePath = 'assets/images/businesses/products/';

String _resolveSelectionItemImage(
  Product? product,
  String roleLabel,
  String productName,
) {
  final imageName = product?.imageName?.trim();

  if (imageName != null && imageName.isNotEmpty) {
    if (imageName.startsWith('assets/')) {
      return imageName;
    }

    return '$_productImagesBasePath$imageName';
  }

  final normalizedRole = roleLabel.toLowerCase();
  final normalizedName = productName.toLowerCase();
  final value = '$normalizedRole $normalizedName';

  if (value.contains('bebida') ||
      value.contains('agua') ||
      value.contains('refresco')) {
    return '${_productImagesBasePath}refresco_base.png';
  }

  if (value.contains('extra') ||
      value.contains('aderezo') ||
      value.contains('tostada extra') ||
      value.contains('tostadas')) {
    return '${_productImagesBasePath}tostadas_extras_base.png';
  }

  if (value.contains('tostada')) {
    return '${_productImagesBasePath}tostada_base.png';
  }

  if (value.contains('tostito')) {
    return '${_productImagesBasePath}tostitos_base.png';
  }

  if (value.contains('coctel')) {
    return '${_productImagesBasePath}coctel_camaron_base.png';
  }

  if (value.contains('aguachile')) {
    return '${_productImagesBasePath}aguachile_base.png';
  }

  if (value.contains('chicharron')) {
    return '${_productImagesBasePath}chicharron_pescado_base.png';
  }

  if (value.contains('ceviche') || value.contains('especial')) {
    return '${_productImagesBasePath}ceviche_base.png';
  }

  return '${_productImagesBasePath}tostada_base.png';
}

IconData _resolveSelectionItemIcon(String roleLabel) {
  final normalizedRole = roleLabel.toLowerCase();

  if (normalizedRole.contains('bebida')) {
    return Icons.local_drink_rounded;
  }

  if (normalizedRole.contains('extra')) {
    return Icons.add_circle_outline_rounded;
  }

  return Icons.restaurant_rounded;
}
