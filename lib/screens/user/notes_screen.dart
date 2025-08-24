import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/note_model.dart';
import 'package:kronk/riverpod/general/screen_style_state_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/riverpod/notes/notes_state_provider.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/router.dart';
import 'package:kronk/widgets/custom_appbar.dart';

/// NotesScreen
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenConfigurator(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(screenName: 'notes', tabController: _tabController, titleText: 'Notes', tabText1: 'personal', tabText2: 'shared'),
      body: TabBarView(
        controller: _tabController,
        children: [
          const NotesTab(noteScope: NoteScope.personal),
          const NotesTab(noteScope: NoteScope.shared),
        ],
      ),
    );
  }
}

/// NotesTab
class NotesTab extends ConsumerStatefulWidget {
  final NoteScope noteScope;

  const NotesTab({super.key, required this.noteScope});

  @override
  ConsumerState<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<NotesTab> with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _scrollListener() {
    final isAtBottom = _scrollController.position.pixels >= _scrollController.position.maxScrollExtent;
    final notesState = ref.read(notesStateProvider(widget.noteScope));
    if (isAtBottom && !notesState.isLoading && notesState.value != null && notesState.value!.hasMore) {
      ref.read(notesStateProvider(widget.noteScope).notifier).loadMore(widget.noteScope);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = ref.watch(themeProvider);
    final notesState = ref.watch(notesStateProvider(widget.noteScope));

    return RefreshIndicator(
      color: theme.primaryText,
      backgroundColor: theme.secondaryBackground,
      onRefresh: () => ref.read(notesStateProvider(widget.noteScope).notifier).refresh(widget.noteScope),
      child: notesState.when(
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        loading: () => NoteList(notes: notesState.value?.notes ?? [], scrollController: _scrollController, isLoading: true),
        data: (notesState) => NoteList(notes: notesState.notes, scrollController: _scrollController),
      ),
    );
  }
}

/// NoteList
class NoteList extends ConsumerWidget {
  final List<NoteModel> notes;
  final ScrollController scrollController;
  final bool isLoading;

  const NoteList({super.key, required this.notes, required this.scrollController, this.isLoading = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final screenStyle = ref.watch(screenStyleStateProvider('notes'));
    final isFloating = screenStyle.layoutStyle == LayoutStyle.floating;

    return Scrollbar(
      controller: scrollController,
      child: CustomScrollView(
        cacheExtent: 3000,
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          if (notes.isEmpty && !isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No feeds yet. 🦄',
                      style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 32.dp, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'You can add the first!',
                      style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 32.dp, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

          if (notes.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.all(isFloating ? 12.dp : 0),
              sliver: SliverList.separated(
                itemCount: notes.length + (isLoading ? 1 : 0),
                addAutomaticKeepAlives: true,
                separatorBuilder: (context, index) => SizedBox(height: 12.dp),
                itemBuilder: (context, index) {
                  if (index == notes.length) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.dp),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  final note = notes.elementAt(index);
                  return NoteCard(key: ValueKey(note.id), initialNote: note, isLoading: isLoading);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  final NoteModel initialNote;
  final bool isLoading;

  const NoteCard({super.key, required this.initialNote, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
