import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/app_snackbar.dart';

class NumberListScreen extends ConsumerStatefulWidget {
  final String mode; // 'whitelist' or 'blacklist'

  const NumberListScreen({super.key, required this.mode});

  @override
  ConsumerState<NumberListScreen> createState() => _NumberListScreenState();
}

class _NumberListScreenState extends ConsumerState<NumberListScreen> {
  final _inputCtrl = TextEditingController();
  late List<String> _numbers;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsNotifierProvider).valueOrNull;
    _numbers = List<String>.from(settings?.numberList ?? []);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  void _add() {
    final raw = _inputCtrl.text.trim();
    if (raw.isEmpty) return;
    // Basic phone number validation
    final cleaned = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.isEmpty || !RegExp(r'^\+?\d{7,15}$').hasMatch(cleaned)) {
      AppSnackbar.showError(context, 'Enter a valid phone number');
      return;
    }
    if (_numbers.contains(cleaned)) {
      AppSnackbar.showError(context, 'Number already in list');
      return;
    }
    setState(() {
      _numbers.add(cleaned);
      _dirty = true;
    });
    _inputCtrl.clear();
  }

  void _remove(String number) {
    setState(() {
      _numbers.remove(number);
      _dirty = true;
    });
  }

  Future<void> _save() async {
    try {
      await ref.read(settingsNotifierProvider.notifier).updateRecordingRules(
            numberList: _numbers,
          );
      if (mounted) {
        AppSnackbar.showSuccess(context, 'Number list saved');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'Failed to save');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = widget.mode == 'whitelist' ? 'Whitelist Numbers' : 'Blacklist Numbers';
    final hint = widget.mode == 'whitelist'
        ? 'Only record these numbers'
        : 'Exclude these numbers from recording';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_dirty)
            TextButton(
              onPressed: _save,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hint banner
          Container(
            width: double.infinity,
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(hint,
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.primary)),
                ),
              ],
            ),
          ),

          // Add number input
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _add(),
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      hintText: '+91 98765 43210',
                      prefixIcon: Icon(Icons.phone_outlined, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: _add,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(56, 56),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          // Count header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              '${_numbers.length} number${_numbers.length == 1 ? '' : 's'}',
              style: textTheme.labelMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Number list
          Expanded(
            child: _numbers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.format_list_bulleted,
                            size: 48, color: AppColors.primaryLight),
                        const SizedBox(height: AppSpacing.md),
                        Text('No numbers added yet',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _numbers.length,
                    separatorBuilder: (_, i) =>
                        const Divider(height: 1, indent: AppSpacing.lg),
                    itemBuilder: (ctx, i) {
                      final number = _numbers[i];
                      return ListTile(
                        leading: const Icon(Icons.phone,
                            color: AppColors.primary, size: 20),
                        title: Text(number, style: textTheme.bodyLarge),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error),
                          onPressed: () => _confirmRemove(ctx, number),
                          tooltip: 'Remove',
                        ),
                      );
                    },
                  ),
          ),

          // Save button
          if (_dirty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save Changes'),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context, String number) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove number?'),
        content: Text('Remove $number from the list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx, true);
              _remove(number);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
