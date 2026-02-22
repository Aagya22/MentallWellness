import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(journalViewModelProvider, (previous, next) {
      if (next.status == JournalStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
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
            fontFamily: 'PlayfairDisplay Bold',
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
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const _JournalEditorScreen(),
                  ),
                );
                if (ok == true && mounted) {
                  await notifier.fetchJournals(q: _searchController.text);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEAF1ED), width: 1.5),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 16, color: Color(0xFF2D5A44)),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _SearchBar(
                controller: _searchController,
                onSearch: () => notifier.fetchJournals(q: _searchController.text),
                onClear: () {
                  _searchController.clear();
                  notifier.fetchJournals();
                },
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => notifier.fetchJournals(q: _searchController.text),
                child: Builder(
                  builder: (context) {
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
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          _EmptyStateCard(
                            title: 'No journal entries yet',
                            subtitle: 'Write something about today and track your progress over time.',
                            ctaText: 'Write your first entry',
                            onTap: () async {
                              final ok = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => const _JournalEditorScreen(),
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
                      itemCount: state.journals.length +
                          ((state.status == JournalStatus.loading ||
                                      state.status == JournalStatus.saving) &&
                                  state.journals.isNotEmpty
                              ? 1
                              : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                          entry: entry,
                          onTap: () async {
                            final changed = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => _JournalEntryScreen(entry: entry),
                              ),
                            );
                            if (changed == true && mounted) {
                              await notifier.fetchJournals(q: _searchController.text);
                            }
                          },
                          onEdit: () async {
                            final ok = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => _JournalEditorScreen(existing: entry),
                              ),
                            );
                            if (ok == true && mounted) {
                              await notifier.fetchJournals(q: _searchController.text);
                            }
                          },
                          onDelete: () async {
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

                            if (!mounted) return;

                            if (confirmed != true) return;
                            final ok = await notifier.deleteEntry(id: entry.id);
                            if (!mounted) return;
                            if (ok) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Entry deleted')),
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

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    required this.ctaText,
    required this.onTap,
  });

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
              child: const Icon(Icons.menu_book_outlined, color: Color(0xFF2D5A44)),
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
    required this.entry,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final JournalEntity entry;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('EEE, MMM d').format(entry.date);
    final dayNum = DateFormat('d').format(entry.date);
    final month = DateFormat('MMM').format(entry.date).toUpperCase();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 10, 16),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayNum,
                    style: const TextStyle(
                      fontFamily: 'Inter Bold',
                      fontSize: 14,
                      color: Color(0xFF1F2A22),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    month,
                    style: const TextStyle(
                      fontFamily: 'Inter Bold',
                      fontSize: 10,
                      letterSpacing: 0.8,
                      color: Color(0xFF2D5A44),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay Bold',
                      fontSize: 16,
                      color: Color(0xFF1F2A22),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateText,
                    style: const TextStyle(
                      fontFamily: 'Inter Medium',
                      fontSize: 12,
                      color: Color(0xFF7B8A7E),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF7B8A7E)),
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
    );
  }
}

class _JournalEntryScreen extends ConsumerWidget {
  const _JournalEntryScreen({required this.entry});

  final JournalEntity entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(journalViewModelProvider.notifier);
    final dateText = DateFormat('EEEE, MMM d, yyyy').format(entry.date);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F1EA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2A22)),
        title: const Text(
          'Entry',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay Bold',
            fontSize: 18,
            color: Color(0xFF1F2A22),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final ok = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => _JournalEditorScreen(existing: entry),
                ),
              );
              if (ok == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: () async {
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
            icon: const Icon(Icons.delete_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEAF1ED), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay Bold',
                    fontSize: 20,
                    color: Color(0xFF1F2A22),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1ED),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    dateText,
                    style: const TextStyle(
                      fontFamily: 'Inter Bold',
                      fontSize: 11,
                      color: Color(0xFF2D5A44),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  entry.content,
                  style: const TextStyle(
                    fontFamily: 'Inter Regular',
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF3C4D42),
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

class _JournalEditorScreen extends ConsumerStatefulWidget {
  const _JournalEditorScreen({this.existing});

  final JournalEntity? existing;

  @override
  ConsumerState<_JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<_JournalEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _contentController = TextEditingController(text: existing?.content ?? '');
    _date = existing?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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
        ? await notifier.createEntry(title: title, content: content, date: _date)
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
    final saving = ref.watch(journalViewModelProvider).status == JournalStatus.saving;
    final dateText = DateFormat('EEE, MMM d, yyyy').format(_date);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F1EA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2A22)),
        title: Text(
          isEdit ? 'Edit entry' : 'New entry',
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay Bold',
            fontSize: 18,
            color: Color(0xFF1F2A22),
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
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Inter Medium',
                      color: Color(0xFF2D5A44),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Title',
                  style: TextStyle(
                    fontFamily: 'Inter Medium',
                    fontSize: 12,
                    color: Color(0xFF7B8A7E),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontFamily: 'Inter Medium',
                    fontSize: 14,
                    color: Color(0xFF1F2A22),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Today I feel...',
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Color(0xFFEAF1ED),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontFamily: 'Inter Medium',
                        fontSize: 12,
                        color: Color(0xFF7B8A7E),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: _pickDate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        child: Text(
                          dateText,
                          style: const TextStyle(
                            fontFamily: 'Inter Medium',
                            fontSize: 12,
                            color: Color(0xFF2D5A44),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Entry',
                  style: TextStyle(
                    fontFamily: 'Inter Medium',
                    fontSize: 12,
                    color: Color(0xFF7B8A7E),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _contentController,
                  minLines: 8,
                  maxLines: 14,
                  style: const TextStyle(
                    fontFamily: 'Inter Regular',
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF1F2A22),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Write your thoughts here...',
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Color(0xFFF4F1EA),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5A44),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                saving ? 'Saving...' : 'Save entry',
                style: const TextStyle(fontFamily: 'Inter Bold'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
