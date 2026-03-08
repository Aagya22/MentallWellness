import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mentalwellness/core/services/sensors/ambient_light_service.dart';
import 'package:mentalwellness/core/services/sensors/light_sensor_settings_service.dart';
import 'package:mentalwellness/features/journal/domain/entities/journal_entity.dart';
import 'package:mentalwellness/features/journal/presentation/state/journal_state.dart';
import 'package:mentalwellness/features/journal/presentation/view_model/journal_viewmodel.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _searchController = TextEditingController();
  bool? _unlockDialogOpen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(journalViewModelProvider.notifier).fetchJournals();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _maybePromptUnlock(JournalState? previous, JournalState next) {
    if (_unlockDialogOpen == true) return;
    if (next.passcodeRequired != true) return;
    if (previous?.passcodeRequired == true) return;

    _unlockDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _unlockDialogOpen = false;
        return;
      }
      try {
        await _showUnlockDialog();
      } finally {
        _unlockDialogOpen = false;
      }
    });
  }

  Future<bool> _showUnlockDialog() async {
    final notifier = ref.read(journalViewModelProvider.notifier);
    final unlocked = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _UnlockJournalDialog(
          onUnlock: (passcode) => notifier.unlockJournal(passcode: passcode),
        );
      },
    );

    if (unlocked == true && mounted) {
      final journalRoute = ModalRoute.of(context);
      if (journalRoute != null && journalRoute.isCurrent != true) {
        Navigator.of(context).popUntil((route) => route == journalRoute);
      }

      final query = _searchController.text.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        notifier.fetchJournals(q: query.isEmpty ? null : query);
      });
    }

    return unlocked == true;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(journalViewModelProvider, (previous, next) {
      _maybePromptUnlock(previous, next);
      if (next.status == JournalStatus.error && next.errorMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
        });
      }
    });

    final state = ref.watch(journalViewModelProvider);
    final notifier = ref.read(journalViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F1EA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2A22)),
        title: const Text(
          'Journal',
          style: TextStyle(
            fontFamily: 'Inter Bold',
            fontSize: 18,
            color: Color(0xFF1F2A22),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final navigator = Navigator.of(context);
                if (state.passcodeRequired == true) {
                  final ok = await _showUnlockDialog();
                  if (!mounted) return;
                  if (ok != true) return;
                }
                final ok = await navigator.push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const _JournalEditorScreen(),
                  ),
                );
                if (ok == true && mounted) {
                  await notifier.fetchJournals(q: _searchController.text);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFEAF1ED),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Color(0xFF2D5A44),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'New',
                      style: TextStyle(
                        fontFamily: 'Inter Bold',
                        fontSize: 13,
                        color: Color(0xFF2D5A44),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 900;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 960 : double.infinity,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: _SearchBar(
                        controller: _searchController,
                        onSearch: () =>
                            notifier.fetchJournals(q: _searchController.text),
                        onClear: () {
                          _searchController.clear();
                          notifier.fetchJournals();
                        },
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () =>
                            notifier.fetchJournals(q: _searchController.text),
                        child: Builder(
                          builder: (context) {
                            if (state.passcodeRequired == true) {
                              return ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                children: [
                                  _EmptyStateCard(
                                    icon: Icons.lock_outline,
                                    title: 'Journal is locked',
                                    subtitle:
                                        'Enter your passcode to view your entries.',
                                    ctaText: 'Unlock journal',
                                    onTap: () {
                                      _showUnlockDialog();
                                    },
                                  ),
                                ],
                              );
                            }

                            if (state.status == JournalStatus.loading &&
                                state.journals.isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF2D5A44),
                                ),
                              );
                            }

                            if (state.journals.isEmpty) {
                              return ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                children: [
                                  _EmptyStateCard(
                                    title: 'No journal entries yet',
                                    subtitle:
                                        'Write something about today and track your progress over time.',
                                    ctaText: 'Write your first entry',
                                    onTap: () async {
                                      final ok = await Navigator.of(context)
                                          .push<bool>(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const _JournalEditorScreen(),
                                            ),
                                          );
                                      if (ok == true && mounted) {
                                        await notifier.fetchJournals();
                                      }
                                    },
                                  ),
                                ],
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount:
                                  state.journals.length +
                                  ((state.status == JournalStatus.loading ||
                                              state.status ==
                                                  JournalStatus.saving) &&
                                          state.journals.isNotEmpty
                                      ? 1
                                      : 0),
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                if (index >= state.journals.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF2D5A44),
                                      ),
                                    ),
                                  );
                                }

                                final entry = state.journals[index];
                                return _JournalEntryCard(
                                  position: index,
                                  entry: entry,
                                  onTap: () async {
                                    final changed = await Navigator.of(context)
                                        .push<bool>(
                                          MaterialPageRoute(
                                            builder: (_) => _JournalEntryScreen(
                                              entry: entry,
                                            ),
                                          ),
                                        );
                                    if (changed == true && mounted) {
                                      await notifier.fetchJournals(
                                        q: _searchController.text,
                                      );
                                    }
                                  },
                                  onEdit: () async {
                                    final ok = await Navigator.of(context)
                                        .push<bool>(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                _JournalEditorScreen(
                                                  existing: entry,
                                                ),
                                          ),
                                        );
                                    if (ok == true && mounted) {
                                      await notifier.fetchJournals(
                                        q: _searchController.text,
                                      );
                                    }
                                  },
                                  onDelete: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: const Text(
                                          'Delete entry?',
                                          style: TextStyle(
                                            fontFamily: 'Inter Bold',
                                          ),
                                        ),
                                        content: const Text(
                                          'This cannot be undone.',
                                          style: TextStyle(
                                            fontFamily: 'Inter Regular',
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              false,
                                            ),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              true,
                                            ),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (!mounted) return;

                                    if (confirmed != true) return;
                                    final ok = await notifier.deleteEntry(
                                      id: entry.id,
                                    );
                                    if (!mounted) return;
                                    if (ok) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Entry deleted'),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onSearch,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAF1ED), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF7B8A7E)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontFamily: 'Inter Regular', fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search entries',
                hintStyle: TextStyle(
                  fontFamily: 'Inter Medium',
                  fontSize: 13,
                  color: Color(0xFF7B8A7E),
                ),
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isNotEmpty) {
                return IconButton(
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFF7B8A7E),
                  ),
                );
              }
              return IconButton(
                onPressed: onSearch,
                icon: const Icon(Icons.arrow_forward, color: Color(0xFF2D5A44)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UnlockJournalDialog extends ConsumerStatefulWidget {
  const _UnlockJournalDialog({required this.onUnlock});

  final Future<String?> Function(String passcode) onUnlock;

  @override
  ConsumerState<_UnlockJournalDialog> createState() =>
      _UnlockJournalDialogState();
}

class _UnlockJournalDialogState extends ConsumerState<_UnlockJournalDialog> {
  final _passcodeController = TextEditingController();
  String? _errorText;
  var _submitting = false;

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final passcode = _passcodeController.text.trim();
    if (passcode.isEmpty) {
      setState(() => _errorText = 'Passcode is required');
      return;
    }
    if (passcode.length < 4 || passcode.length > 8) {
      setState(() => _errorText = 'Passcode must be 4 to 8 digits');
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      final err = await widget.onUnlock(passcode);
      if (!mounted) return;
      if (err == null) {
        Navigator.of(context).pop(true);
        return;
      }

      setState(() {
        _submitting = false;
        _errorText = err;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Unlock journal',
        style: TextStyle(fontFamily: 'Inter Bold'),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your 4–8 digit passcode to view your entries.',
              style: TextStyle(fontFamily: 'Inter Regular'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passcodeController,
              keyboardType: TextInputType.number,
              obscureText: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Passcode',
                errorText: _errorText,
                filled: true,
                fillColor: const Color(0xFFEAF1ED),
                border: const OutlineInputBorder(borderSide: BorderSide.none),
              ),
              onSubmitted: (_) {
                if (_submitting) return;
                _submit();
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submitting
              ? null
              : () {
                  _submit();
                },
          child: _submitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Unlock'),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    this.icon = Icons.menu_book_outlined,
    required this.title,
    required this.subtitle,
    required this.ctaText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String ctaText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAF1ED), width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1ED),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFF2D5A44)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter Medium',
                      fontSize: 13,
                      color: Color(0xFF1F2A22),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter Regular',
                      fontSize: 12,
                      height: 1.35,
                      color: Color(0xFF7B8A7E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ctaText,
                    style: const TextStyle(
                      fontFamily: 'Inter Medium',
                      fontSize: 12,
                      color: Color(0xFF2D5A44),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF7B8A7E)),
          ],
        ),
      ),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({
    this.position = 0,
    required this.entry,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final int position;

  final JournalEntity entry;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const List<Color> _accentPalette = <Color>[
    Color(0xFFEAF1ED),
    Color(0xFFF1E3DD),
    Color(0xFFE7EDF8),
    Color(0xFFF4EFD9),
  ];

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('EEE, MMM d').format(entry.date);
    final dayNum = DateFormat('d').format(entry.date);
    final month = DateFormat('MMM').format(entry.date).toUpperCase();
    final preview = _buildJournalPreview(entry.content);
    final wordCount = _countJournalWords(entry.content);
    final readMinutes = _estimateJournalReadMinutes(wordCount);
    final accentColor = _accentPalette[position % _accentPalette.length];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE3ECE6), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1F2A22).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accentColor, accentColor.withValues(alpha: 0.45)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayNum,
                          style: const TextStyle(
                            fontFamily: 'Inter Bold',
                            fontSize: 15,
                            color: Color(0xFF1F2A22),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          month,
                          style: const TextStyle(
                            fontFamily: 'Inter Bold',
                            fontSize: 10,
                            letterSpacing: 0.7,
                            color: Color(0xFF2D5A44),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: const TextStyle(
                            fontFamily: 'Inter Bold',
                            fontSize: 17,
                            color: Color(0xFF1F2A22),
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dateText,
                          style: const TextStyle(
                            fontFamily: 'Inter Medium',
                            fontSize: 12,
                            color: Color(0xFF5E6C62),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Entry options',
                    icon: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.more_horiz_rounded,
                        color: Color(0xFF5E6C62),
                        size: 18,
                      ),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              preview,
              style: const TextStyle(
                fontFamily: 'Inter Regular',
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF596A5F),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _JournalInfoPill(
                  icon: Icons.auto_stories_outlined,
                  label: '$wordCount words',
                ),
                const SizedBox(width: 8),
                _JournalInfoPill(
                  icon: Icons.schedule_rounded,
                  label: '$readMinutes min read',
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Color(0xFF6A7A70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalInfoPill extends StatelessWidget {
  const _JournalInfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF5D6E62)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter Medium',
              fontSize: 11,
              color: Color(0xFF5D6E62),
            ),
          ),
        ],
      ),
    );
  }
}

String _buildJournalPreview(String text, {int maxChars = 150}) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) {
    return 'No notes written in this entry yet.';
  }
  if (normalized.length <= maxChars) {
    return normalized;
  }
  return '${normalized.substring(0, maxChars).trimRight()}...';
}

int _countJournalWords(String text) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) return 0;
  return normalized.split(' ').length;
}

int _estimateJournalReadMinutes(int wordCount) {
  if (wordCount <= 0) return 1;
  final minutes = (wordCount / 180).ceil();
  return minutes < 1 ? 1 : minutes;
}

class _JournalEntryScreen extends ConsumerWidget {
  const _JournalEntryScreen({required this.entry});

  final JournalEntity entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(journalViewModelProvider.notifier);
    final dateText = DateFormat('EEEE, MMM d, yyyy').format(entry.date);
    final updatedText = DateFormat(
      'MMM d, yyyy • h:mm a',
    ).format(entry.updatedAt);
    final wordCount = _countJournalWords(entry.content);
    final readMinutes = _estimateJournalReadMinutes(wordCount);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F1EA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2A22)),
        title: const Text(
          'Journal entry',
          style: TextStyle(
            fontFamily: 'Inter Bold',
            fontSize: 18,
            color: Color(0xFF1F2A22),
          ),
        ),
        actions: [
          _EntryActionButton(
            icon: Icons.edit_outlined,
            onTap: () async {
              final ok = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => _JournalEditorScreen(existing: entry),
                ),
              );
              if (ok == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
          _EntryActionButton(
            icon: Icons.delete_outline,
            iconColor: const Color(0xFFB04A45),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text(
                    'Delete entry?',
                    style: TextStyle(fontFamily: 'Inter Bold'),
                  ),
                  content: const Text(
                    'This cannot be undone.',
                    style: TextStyle(fontFamily: 'Inter Regular'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (!context.mounted) return;
              if (confirmed != true) return;

              final ok = await notifier.deleteEntry(id: entry.id);
              if (ok && context.mounted) {
                messenger.hideCurrentSnackBar();
                Navigator.of(context).pop(true);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2D5A44), Color(0xFF3A6A52)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1F2A22).withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JOURNAL ENTRY',
                  style: TextStyle(
                    fontFamily: 'Inter Bold',
                    fontSize: 11,
                    letterSpacing: 1.3,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontFamily: 'Inter Bold',
                    fontSize: 30,
                    height: 1.1,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateText,
                  style: TextStyle(
                    fontFamily: 'Inter Medium',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _JournalHeaderPill(
                      icon: Icons.auto_stories_outlined,
                      label: '$wordCount words',
                    ),
                    _JournalHeaderPill(
                      icon: Icons.schedule_rounded,
                      label: '$readMinutes min read',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE3ECE6), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1F2A22).withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.format_quote_rounded,
                        size: 20,
                        color: Color(0xFF2D5A44),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Reflection',
                      style: TextStyle(
                        fontFamily: 'Inter Bold',
                        fontSize: 18,
                        color: Color(0xFF1F2A22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  entry.content.trim(),
                  style: const TextStyle(
                    fontFamily: 'Inter Regular',
                    fontSize: 14,
                    height: 1.65,
                    color: Color(0xFF3E5045),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F1EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Last updated $updatedText',
                    style: const TextStyle(
                      fontFamily: 'Inter Medium',
                      fontSize: 12,
                      color: Color(0xFF627267),
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

class _EntryActionButton extends StatelessWidget {
  const _EntryActionButton({
    required this.icon,
    required this.onTap,
    this.iconColor = const Color(0xFF1F2A22),
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3ECE6), width: 1.1),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}

class _JournalHeaderPill extends StatelessWidget {
  const _JournalHeaderPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.88)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter Medium',
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalEditorScreen extends ConsumerStatefulWidget {
  const _JournalEditorScreen({this.existing});

  final JournalEntity? existing;

  @override
  ConsumerState<_JournalEditorScreen> createState() =>
      _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<_JournalEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final FocusNode _contentFocusNode = FocusNode();
  DateTime _date = DateTime.now();

  static const List<String> _writingPrompts = <String>[
    'Today I felt most at peace when...',
    'A small win I want to remember is...',
    'Right now my mind keeps returning to...',
    'One kind thing I can do for myself tonight is...',
  ];

  StreamSubscription<AmbientLightSample>? _ambientLightSub;
  AmbientLightLevel _ambientLightLevel = AmbientLightLevel.unknown;
  double? _ambientLightLux;
  bool _ambientLightEnabled = true;
  bool _ambientLightAvailable = true;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _contentController = TextEditingController(text: existing?.content ?? '');
    _date = existing?.date ?? DateTime.now();

    _ambientLightEnabled = ref
        .read(lightSensorSettingsServiceProvider)
        .isLightSensorEnabled();

    if (_ambientLightEnabled) {
      _startAmbientLightTracking();
    } else {
      _ambientLightLevel = AmbientLightLevel.unknown;
      _ambientLightLux = null;
      _ambientLightAvailable = false;
    }
  }

  @override
  void dispose() {
    unawaited(_stopAmbientLightTracking());
    _contentFocusNode.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _insertWritingPrompt(String prompt) {
    final current = _contentController.text;
    final separator = current.trim().isEmpty
        ? ''
        : (current.endsWith('\n') ? '\n' : '\n\n');
    final next = '$current$separator$prompt';

    _contentController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _contentFocusNode.requestFocus();
  }

  void _startAmbientLightTracking() {
    _ambientLightSub?.cancel();

    final service = ref.read(ambientLightServiceProvider);
    service.start();

    _ambientLightSub = service.stream.listen((sample) {
      if (!mounted) return;
      setState(() {
        _ambientLightLevel = sample.level;
        _ambientLightLux = sample.lux;
        _ambientLightAvailable = sample.sensorAvailable;
      });
    });
  }

  Future<void> _stopAmbientLightTracking() async {
    await _ambientLightSub?.cancel();
    _ambientLightSub = null;
    await ref.read(ambientLightServiceProvider).stop();
  }

  String _ambientLevelLabel(AmbientLightLevel level) {
    switch (level) {
      case AmbientLightLevel.dark:
        return 'Dark';
      case AmbientLightLevel.dim:
        return 'Dim';
      case AmbientLightLevel.normal:
        return 'Comfortable';
      case AmbientLightLevel.bright:
        return 'Bright';
      case AmbientLightLevel.unknown:
        return 'Unknown';
    }
  }

  String _ambientThemeHint(AmbientLightLevel level) {
    switch (level) {
      case AmbientLightLevel.dark:
        return 'Very low light detected. Add a soft lamp to reduce eye strain.';
      case AmbientLightLevel.dim:
        return 'Calm low light. Great for reflective writing.';
      case AmbientLightLevel.normal:
        return 'Balanced lighting for comfortable focus.';
      case AmbientLightLevel.bright:
        return 'Bright environment detected. Lower screen brightness if needed.';
      case AmbientLightLevel.unknown:
        return 'Waiting for ambient light...';
    }
  }

  IconData _ambientLevelIcon(AmbientLightLevel level) {
    switch (level) {
      case AmbientLightLevel.dark:
        return Icons.dark_mode_rounded;
      case AmbientLightLevel.dim:
        return Icons.nights_stay_rounded;
      case AmbientLightLevel.normal:
        return Icons.wb_sunny_outlined;
      case AmbientLightLevel.bright:
        return Icons.wb_sunny_rounded;
      case AmbientLightLevel.unknown:
        return Icons.light_mode_rounded;
    }
  }

  Color _ambientLevelColor(AmbientLightLevel level) {
    switch (level) {
      case AmbientLightLevel.dark:
        return const Color(0xFF6187A1);
      case AmbientLightLevel.dim:
        return const Color(0xFF7A8F63);
      case AmbientLightLevel.normal:
        return const Color(0xFF2D5A44);
      case AmbientLightLevel.bright:
        return const Color(0xFFC7862B);
      case AmbientLightLevel.unknown:
        return const Color(0xFF748278);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content are required.')),
      );
      return;
    }

    final notifier = ref.read(journalViewModelProvider.notifier);
    final existing = widget.existing;
    final ok = existing == null
        ? await notifier.createEntry(
            title: title,
            content: content,
            date: _date,
          )
        : await notifier.updateEntry(
            id: existing.id,
            title: title,
            content: content,
            date: _date,
          );
    if (!ok || !mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final saving =
        ref.watch(journalViewModelProvider).status == JournalStatus.saving;
    final dateText = DateFormat('EEE, MMM d, yyyy').format(_date);
    final palette = _JournalEnvironmentPalette.fromAmbientLevel(
      _ambientLightLevel,
    );
    final ambientLevelText = !_ambientLightEnabled
        ? 'Disabled'
        : _ambientLightAvailable
        ? _ambientLevelLabel(_ambientLightLevel)
        : 'Unavailable';
    final ambientLuxText = _ambientLightLux == null
        ? '-- lx'
        : '${_ambientLightLux!.toStringAsFixed(0)} lx';
    final ambientHintText = !_ambientLightEnabled
        ? 'Ambient light guidance is turned off in Privacy & Security.'
        : _ambientLightAvailable
        ? _ambientThemeHint(_ambientLightLevel)
        : 'Ambient light sensor is not available on this device';
    final ambientIcon = _ambientLightEnabled
        ? _ambientLevelIcon(_ambientLightLevel)
        : Icons.light_mode_outlined;
    final ambientLevelColor = _ambientLightEnabled
        ? _ambientLevelColor(_ambientLightLevel)
        : const Color(0xFF748278);
    const ambientMaxLux = 500.0;
    final clampedLux = _ambientLightLux == null
        ? 0.0
        : _ambientLightLux!.clamp(0.0, ambientMaxLux).toDouble();
    final ambientProgress = _ambientLightEnabled
        ? clampedLux / ambientMaxLux
        : 0.0;
    final heroStart =
        Color.lerp(
          palette.buttonBackground,
          palette.scaffoldBackground,
          0.12,
        ) ??
        palette.buttonBackground;
    final heroEnd =
        Color.lerp(palette.buttonBackground, palette.cardBackground, 0.34) ??
        palette.buttonBackground;

    return Scaffold(
      backgroundColor: palette.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: palette.appBarBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: palette.primaryText),
        title: Text(
          isEdit ? 'Edit entry' : 'New entry',
          style: TextStyle(
            fontFamily: 'Inter Bold',
            fontSize: 18,
            color: palette.primaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : _save,
            child: saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Inter Medium',
                      color: palette.accent,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        color: palette.scaffoldBackground,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [heroStart, heroEnd],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1F2A22).withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: palette.buttonForeground.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.edit_note_rounded,
                          size: 22,
                          color: palette.buttonForeground,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isEdit ? 'EDIT MODE' : 'WRITING MODE',
                          style: TextStyle(
                            fontFamily: 'Inter Bold',
                            fontSize: 11,
                            letterSpacing: 1.2,
                            color: palette.buttonForeground.withValues(
                              alpha: 0.82,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: palette.buttonForeground.withValues(
                              alpha: 0.16,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: palette.buttonForeground.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Text(
                            dateText,
                            style: TextStyle(
                              fontFamily: 'Inter Bold',
                              fontSize: 11,
                              color: palette.buttonForeground,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isEdit
                        ? 'Refine your reflection'
                        : 'Write what this day felt like',
                    style: TextStyle(
                      fontFamily: 'Inter Bold',
                      fontSize: 29,
                      height: 1.06,
                      color: palette.buttonForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Capture the highlights, honest feelings, and what you want to carry forward.',
                    style: TextStyle(
                      fontFamily: 'Inter Regular',
                      fontSize: 13,
                      height: 1.45,
                      color: palette.buttonForeground.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _contentController,
                    builder: (context, value, _) {
                      final words = _countJournalWords(value.text);
                      final minutes = _estimateJournalReadMinutes(words);
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _EditorStatChip(
                            icon: Icons.auto_stories_outlined,
                            label: '$words words',
                            background: palette.buttonForeground.withValues(
                              alpha: 0.16,
                            ),
                            foreground: palette.buttonForeground,
                          ),
                          _EditorStatChip(
                            icon: Icons.schedule_rounded,
                            label: '$minutes min read',
                            background: palette.buttonForeground.withValues(
                              alpha: 0.16,
                            ),
                            foreground: palette.buttonForeground,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: palette.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.outline, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need a starting line?',
                    style: TextStyle(
                      fontFamily: 'Inter Medium',
                      fontSize: 12,
                      color: palette.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 9),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final prompt in _writingPrompts)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _WritingPromptChip(
                              label: prompt,
                              onTap: () => _insertWritingPrompt(prompt),
                              background: palette.titleFieldBackground,
                              borderColor:
                                  Color.lerp(
                                    palette.outline,
                                    palette.accent,
                                    0.28,
                                  ) ??
                                  palette.outline,
                              foreground: palette.primaryText,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    palette.cardBackground,
                    palette.titleFieldBackground,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.outline, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 34,
                        width: 34,
                        decoration: BoxDecoration(
                          color: ambientLevelColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          ambientIcon,
                          size: 18,
                          color: ambientLevelColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ambient light',
                              style: TextStyle(
                                fontFamily: 'Inter Medium',
                                fontSize: 11,
                                color: palette.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ambientLuxText,
                              style: TextStyle(
                                fontFamily: 'Inter Bold',
                                fontSize: 15,
                                color: palette.primaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ambientLevelColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          ambientLevelText,
                          style: TextStyle(
                            fontFamily: 'Inter Bold',
                            fontSize: 11,
                            color: ambientLevelColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      end: _ambientLightAvailable ? ambientProgress : 0,
                    ),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: value,
                          backgroundColor: palette.contentFieldBackground,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ambientLevelColor,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ambientHintText,
                    style: TextStyle(
                      fontFamily: 'Inter Regular',
                      fontSize: 11,
                      height: 1.35,
                      color: palette.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: palette.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.outline, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Title',
                        style: TextStyle(
                          fontFamily: 'Inter Medium',
                          fontSize: 12,
                          color: palette.secondaryText,
                        ),
                      ),
                      const Spacer(),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _titleController,
                        builder: (context, value, _) {
                          return Text(
                            '${value.text.trim().length}/80',
                            style: TextStyle(
                              fontFamily: 'Inter Medium',
                              fontSize: 11,
                              color: palette.secondaryText,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    maxLength: 80,
                    buildCounter:
                        (
                          BuildContext context, {
                          required int currentLength,
                          required bool isFocused,
                          required int? maxLength,
                        }) => null,
                    onSubmitted: (_) => _contentFocusNode.requestFocus(),
                    style: TextStyle(
                      fontFamily: 'Inter Medium',
                      fontSize: 14,
                      color: palette.primaryText,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Today I feel...',
                      hintStyle: TextStyle(
                        fontFamily: 'Inter Medium',
                        fontSize: 13,
                        color: palette.secondaryText,
                      ),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: palette.titleFieldBackground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: palette.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.outline, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Entry',
                        style: TextStyle(
                          fontFamily: 'Inter Medium',
                          fontSize: 12,
                          color: palette.secondaryText,
                        ),
                      ),
                      const Spacer(),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _contentController,
                        builder: (context, value, _) {
                          final words = _countJournalWords(value.text);
                          return Text(
                            '$words words',
                            style: TextStyle(
                              fontFamily: 'Inter Medium',
                              fontSize: 11,
                              color: palette.secondaryText,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 10,
                    maxLines: 18,
                    style: TextStyle(
                      fontFamily: 'Inter Regular',
                      fontSize: 14,
                      height: 1.6,
                      color: palette.primaryText,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Write your thoughts here. Be honest and specific.',
                      hintStyle: TextStyle(
                        fontFamily: 'Inter Regular',
                        fontSize: 13,
                        color: palette.secondaryText,
                      ),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: palette.contentFieldBackground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saving ? null : _save,
                icon: saving
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            palette.buttonForeground,
                          ),
                        ),
                      )
                    : Icon(
                        isEdit ? Icons.check_rounded : Icons.save_outlined,
                        size: 18,
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.buttonBackground,
                  foregroundColor: palette.buttonForeground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                label: Text(
                  saving
                      ? 'Saving...'
                      : (isEdit ? 'Update entry' : 'Save entry'),
                  style: const TextStyle(fontFamily: 'Inter Bold'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorStatChip extends StatelessWidget {
  const _EditorStatChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter Medium',
              fontSize: 11,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _WritingPromptChip extends StatelessWidget {
  const _WritingPromptChip({
    required this.label,
    required this.onTap,
    required this.background,
    required this.borderColor,
    required this.foreground,
  });

  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color borderColor;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter Medium',
              fontSize: 12,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}

class _JournalEnvironmentPalette {
  final Color scaffoldBackground;
  final Color appBarBackground;
  final Color cardBackground;
  final Color titleFieldBackground;
  final Color contentFieldBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color outline;
  final Color buttonBackground;
  final Color buttonForeground;

  const _JournalEnvironmentPalette({
    required this.scaffoldBackground,
    required this.appBarBackground,
    required this.cardBackground,
    required this.titleFieldBackground,
    required this.contentFieldBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.outline,
    required this.buttonBackground,
    required this.buttonForeground,
  });

  factory _JournalEnvironmentPalette.fromAmbientLevel(AmbientLightLevel level) {
    switch (level) {
      case AmbientLightLevel.dark:
        return const _JournalEnvironmentPalette(
          scaffoldBackground: Color(0xFF1D2421),
          appBarBackground: Color(0xFF1D2421),
          cardBackground: Color(0xFF25302B),
          titleFieldBackground: Color(0xFF314039),
          contentFieldBackground: Color(0xFF2B3832),
          primaryText: Color(0xFFE7F0E9),
          secondaryText: Color(0xFF9AB0A4),
          accent: Color(0xFF8AC8A6),
          outline: Color(0xFF3A4D44),
          buttonBackground: Color(0xFF3D7F60),
          buttonForeground: Color(0xFFF2FAF4),
        );
      case AmbientLightLevel.dim:
        return const _JournalEnvironmentPalette(
          scaffoldBackground: Color(0xFFEEE8DC),
          appBarBackground: Color(0xFFEEE8DC),
          cardBackground: Colors.white,
          titleFieldBackground: Color(0xFFF1ECE2),
          contentFieldBackground: Color(0xFFF6F2EA),
          primaryText: Color(0xFF1F2A22),
          secondaryText: Color(0xFF6F7D73),
          accent: Color(0xFF2D5A44),
          outline: Color(0xFFE2DBCF),
          buttonBackground: Color(0xFF2D5A44),
          buttonForeground: Colors.white,
        );
      case AmbientLightLevel.bright:
        return const _JournalEnvironmentPalette(
          scaffoldBackground: Color(0xFFF8F6EF),
          appBarBackground: Color(0xFFF8F6EF),
          cardBackground: Colors.white,
          titleFieldBackground: Color(0xFFE9F4EE),
          contentFieldBackground: Color(0xFFF1F7F3),
          primaryText: Color(0xFF1D2720),
          secondaryText: Color(0xFF6C7D72),
          accent: Color(0xFF2A5D45),
          outline: Color(0xFFE4EEE8),
          buttonBackground: Color(0xFF2A5D45),
          buttonForeground: Colors.white,
        );
      case AmbientLightLevel.normal:
      case AmbientLightLevel.unknown:
        return const _JournalEnvironmentPalette(
          scaffoldBackground: Color(0xFFF4F1EA),
          appBarBackground: Color(0xFFF4F1EA),
          cardBackground: Colors.white,
          titleFieldBackground: Color(0xFFEAF1ED),
          contentFieldBackground: Color(0xFFF4F1EA),
          primaryText: Color(0xFF1F2A22),
          secondaryText: Color(0xFF7B8A7E),
          accent: Color(0xFF2D5A44),
          outline: Color(0xFFEAF1ED),
          buttonBackground: Color(0xFF2D5A44),
          buttonForeground: Colors.white,
        );
    }
  }
}
