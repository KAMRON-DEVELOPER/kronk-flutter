import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/vocabulary_model.dart';
import 'package:kronk/riverpod/general/screen_style_state_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/riverpod/vocabulary/sentences_provider.dart';
import 'package:kronk/riverpod/vocabulary/vocabularies_state_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/router.dart';
import 'package:kronk/widgets/custom_appbar.dart';

class VocabulariesScreen extends ConsumerStatefulWidget {
  const VocabulariesScreen({super.key});

  @override
  ConsumerState<VocabulariesScreen> createState() => _VocabulariesScreenState();
}

class _VocabulariesScreenState extends ConsumerState<VocabulariesScreen> with SingleTickerProviderStateMixin {
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
      appBar: CustomAppBar(screenName: 'vocabularies', tabController: _tabController, titleText: 'Feeds', tabText1: 'discover', tabText2: 'following'),
      body: TabBarView(controller: _tabController, children: [const VocabulariesTab(), const SentencesTab()]),
    );
  }
}

/// VocabulariesTab
class VocabulariesTab extends ConsumerWidget {
  const VocabulariesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final vocabulariesState = ref.watch(vocabulariesProvider);
    return RefreshIndicator(
      color: theme.primaryText,
      backgroundColor: theme.secondaryBackground,
      onRefresh: () => ref.watch(vocabulariesProvider.notifier).refresh(),
      child: vocabulariesState.when(
        data: (VocabulariesState state) => VocabulariesListWidget(vocabularies: state.vocabularies, isLoading: false),
        loading: () => VocabulariesListWidget(vocabularies: vocabulariesState.valueOrNull?.vocabularies ?? [], isLoading: vocabulariesState.isLoading),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
      ),
    );
  }
}

/// VocabulariesListWidget
class VocabulariesListWidget extends ConsumerWidget {
  final List<VocabularyModel> vocabularies;
  final bool isLoading;

  const VocabulariesListWidget({super.key, required this.vocabularies, required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('vocabularies'));
    final bool isFloating = screenStyle.layoutStyle == LayoutStyle.floating;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (vocabularies.isEmpty && !isLoading)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No vocabularies yet. 🔠',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 30.dp, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Upload images.',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 30.dp, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

        if (vocabularies.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.all(isFloating ? 12.dp : 0),
            sliver: SliverList.separated(
              itemCount: vocabularies.length,
              separatorBuilder: (context, index) => SizedBox(height: isFloating ? 12.dp : 0),
              itemBuilder: (context, index) => VocabularyCard(key: ValueKey(vocabularies.elementAt(index).id), vocabulary: vocabularies.elementAt(index), isRefreshing: isLoading),
            ),
          ),
      ],
    );
  }
}

/// VocabularyCard
class VocabularyCard extends ConsumerStatefulWidget {
  final VocabularyModel vocabulary;
  final bool isRefreshing;

  const VocabularyCard({super.key, required this.vocabulary, required this.isRefreshing});

  @override
  ConsumerState<VocabularyCard> createState() => _VocabularyCardState();
}

class _VocabularyCardState extends ConsumerState<VocabularyCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final screenStyle = ref.watch(screenStyleStateProvider('vocabularies'));
    final bool isFloating = screenStyle.layoutStyle == LayoutStyle.floating;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: 12.dp),
        padding: EdgeInsets.all(12.dp),
        decoration: BoxDecoration(
          color: theme.primaryBackground.withValues(alpha: screenStyle.opacity),
          borderRadius: BorderRadius.circular(isFloating ? screenStyle.borderRadius : 0),
          border: isFloating ? Border.all(color: theme.secondaryBackground, width: 0.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.vocabulary.word,
              style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 18.dp, fontWeight: FontWeight.w600),
            ),
            Text(widget.vocabulary.translation, style: GoogleFonts.quicksand(color: theme.primaryText.withValues(alpha: 0.7))),

            if (_expanded) ...[
              const SizedBox(height: 8),

              // Phonetics
              Wrap(
                spacing: 8,
                children: widget.vocabulary.phonetics.map((p) => Text(p.text, style: TextStyle(color: theme.primaryText))).toList(),
              ),

              // Meanings
              ...widget.vocabulary.meanings.map(
                (meaning) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meaning.partOfSpeech,
                        style: GoogleFonts.quicksand(color: theme.primaryText, fontWeight: FontWeight.bold),
                      ),
                      ...meaning.definitions.map(
                        (d) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('• ${d.definition}', style: GoogleFonts.quicksand(color: theme.primaryText.withValues(alpha: 0.85))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// SentencesTab
class SentencesTab extends ConsumerStatefulWidget {
  const SentencesTab({super.key});

  @override
  ConsumerState<SentencesTab> createState() => _SentenceWidgetState();
}

class _SentenceWidgetState extends ConsumerState<SentencesTab> with AutomaticKeepAliveClientMixin {
  List<SentenceModel> _previousSentences = [];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = ref.watch(themeProvider);
    final AsyncValue<SentencesState> sentencesState = ref.watch(sentencesProvider);
    return RefreshIndicator(
      color: theme.primaryText,
      backgroundColor: theme.secondaryBackground,
      onRefresh: () => ref.watch(sentencesProvider.notifier).refresh(),
      child: sentencesState.when(
        error: (error, stackTrace) {
          if (error is DioException) return Center(child: Text('${error.message}'));
          return Center(child: Text('$error'));
        },
        loading: () => SentencesListWidget(sentences: _previousSentences, isRefreshing: true),
        data: (SentencesState state) {
          _previousSentences = state.sentences;
          return SentencesListWidget(sentences: state.sentences, isRefreshing: false);
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// SentencesListWidget
class SentencesListWidget extends ConsumerWidget {
  final List<SentenceModel> sentences;
  final bool isRefreshing;

  const SentencesListWidget({super.key, required this.sentences, required this.isRefreshing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('vocabularies'));
    final bool isFloating = screenStyle.layoutStyle == LayoutStyle.floating;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (sentences.isEmpty && !isRefreshing)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No chats yet. 💬',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 32.dp, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Find people to chat.',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 32.dp, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

        if (sentences.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.all(isFloating ? 12.dp : 0),
            sliver: SliverList.separated(
              itemCount: sentences.length,
              separatorBuilder: (context, index) => SizedBox(height: 12.dp),
              itemBuilder: (context, index) => SentenceCard(key: ValueKey(sentences.elementAt(index).id), sentence: sentences.elementAt(index), isRefreshing: isRefreshing),
            ),
          ),
      ],
    );
  }
}

/// SentenceCard
class SentenceCard extends ConsumerWidget {
  final SentenceModel sentence;
  final bool isRefreshing;

  const SentenceCard({super.key, required this.sentence, required this.isRefreshing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('vocabularies'));
    final bool isFloating = screenStyle.layoutStyle == LayoutStyle.floating;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(0),
      color: theme.primaryBackground.withValues(alpha: screenStyle.opacity),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isFloating ? screenStyle.borderRadius : 0),
        side: isFloating ? BorderSide(color: theme.secondaryBackground, width: 0.5) : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.all(8.dp),
        child: Column(
          spacing: 8.dp,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('vocabulary.word: ${sentence.sentence}', style: GoogleFonts.quicksand(color: theme.primaryText)),
            Text('vocabulary.translation: ${sentence.translation}', style: GoogleFonts.quicksand(color: theme.primaryText)),
          ],
        ),
      ),
    );
  }
}
