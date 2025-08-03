import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/vocabulary_model.dart';
import 'package:kronk/riverpod/general/screen_style_state_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/riverpod/vocabulary/vocabularies_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/screen_style_state_dialog.dart';
import 'package:kronk/widgets/custom_drawer.dart';
import 'package:kronk/widgets/main_appbar.dart';
import 'package:kronk/widgets/navbar.dart';

class VocabulariesScreen extends ConsumerWidget {
  const VocabulariesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('vocabularies'));
    final bool isFloating = screenStyle.layoutStyle == LayoutStyle.floating;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: MainAppBar(titleText: 'Vocabulary', tabText1: 'vocabularies', tabText2: 'create', onTap: () => showScreenStyleStateDialog(context, 'vocabulary')),
        body: Stack(
          children: [
            /// Static background images
            if (isFloating)
              Positioned(
                left: 0,
                top: MediaQuery.of(context).padding.top - 52.dp,
                right: 0,
                bottom: 0,
                child: Opacity(
                  opacity: 0.4,
                  child: Image.asset(
                    screenStyle.backgroundImage,
                    fit: BoxFit.cover,
                    cacheHeight: (Sizes.screenHeight - MediaQuery.of(context).padding.top - 52.dp).cacheSize(context),
                    cacheWidth: Sizes.screenWidth.cacheSize(context),
                  ),
                ),
              ),

            const TabBarView(children: [VocabulariesWidget(), CreateVocabulariesWidget()]),
          ],
        ),
        bottomNavigationBar: const Navbar(),
        drawer: const CustomDrawer(),
      ),
    );
  }
}

/// VocabulariesWidget
class VocabulariesWidget extends ConsumerStatefulWidget {
  const VocabulariesWidget({super.key});

  @override
  ConsumerState<VocabulariesWidget> createState() => _VocabulariesWidgetState();
}

class _VocabulariesWidgetState extends ConsumerState<VocabulariesWidget> {
  List<VocabularyModel> _previousVocabularies = [];

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final AsyncValue<VocabulariesState> vocabulariesState = ref.watch(vocabulariesProvider);
    return RefreshIndicator(
      color: theme.primaryText,
      backgroundColor: theme.secondaryBackground,
      onRefresh: () => ref.watch(vocabulariesProvider.notifier).refresh(),
      child: vocabulariesState.when(
        error: (error, stackTrace) {
          if (error is DioException) return Center(child: Text('${error.message}'));
          return Center(child: Text('$error'));
        },
        loading: () => VocabulariesListWidget(vocabularies: _previousVocabularies, isRefreshing: true),
        data: (VocabulariesState state) {
          _previousVocabularies = state.vocabularies;
          return VocabulariesListWidget(vocabularies: state.vocabularies, isRefreshing: false);
        },
      ),
    );
  }
}

/// VocabulariesListWidget
class VocabulariesListWidget extends ConsumerWidget {
  final List<VocabularyModel> vocabularies;
  final bool isRefreshing;

  const VocabulariesListWidget({super.key, required this.vocabularies, required this.isRefreshing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final ScreenStyleState screenStyle = ref.watch(screenStyleStateProvider('vocabularies'));
    final bool isFloating = screenStyle.layoutStyle == LayoutStyle.floating;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (vocabularies.isEmpty && !isRefreshing)
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

        if (vocabularies.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.all(isFloating ? 12.dp : 0),
            sliver: SliverList.separated(
              itemCount: vocabularies.length,
              separatorBuilder: (context, index) => SizedBox(height: 12.dp),
              itemBuilder: (context, index) =>
                  VocabularyCard(key: ValueKey(vocabularies.elementAt(index).id), vocabulary: vocabularies.elementAt(index), isRefreshing: isRefreshing),
            ),
          ),
      ],
    );
  }
}

/// ChatTile
class VocabularyCard extends ConsumerWidget {
  final VocabularyModel vocabulary;
  final bool isRefreshing;

  const VocabularyCard({super.key, required this.vocabulary, required this.isRefreshing});

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
          children: [Text('vocabulary.word: ${vocabulary.word}'), Text('vocabulary.translation: ${vocabulary.translation}')],
        ),
      ),
    );
  }
}

/// CreateVocabulariesWidget
class CreateVocabulariesWidget extends ConsumerWidget {
  const CreateVocabulariesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Center(
      child: Text(
        'Will be available soon, ⌛',
        style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 24.dp, fontWeight: FontWeight.bold),
      ),
    );
  }
}
