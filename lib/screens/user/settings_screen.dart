import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/main.dart';
import 'package:kronk/models/navbar_model.dart';
import 'package:kronk/models/statistics_model.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/riverpod/general/navbar_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/riverpod/settings/settings_statistics.dart';
import 'package:kronk/services/api_service/user_service.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/storage.dart';
import 'package:kronk/utility/url_launches.dart';
import 'package:kronk/widgets/profile/custom_painters.dart';
import 'package:kronk/widgets/settings/custom_toggle.dart';
import 'package:kronk/widgets/settings/stats_bar_chart.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'package:vector_graphics/vector_graphics.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeNotifierProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            leading: const BackButtonWidget(),
            title: Text(
              'Settings',
              style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 24.dp, fontWeight: FontWeight.w500),
            ),
            floating: true,
            snap: true,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(0.5.dp),
              child: Divider(height: 0.1, color: theme.outline),
            ),
          ),
          const SectionLabelWidget(title: 'appearance'),
          const AppearanceSectionWidget(),
          SliverToBoxAdapter(child: SizedBox(height: 12.dp)),
          const SectionLabelWidget(title: 'services', isServie: true),
          const ServicesSectionWidget(),
          SliverToBoxAdapter(child: SizedBox(height: 12.dp)),
          const SectionLabelWidget(title: 'statistics'),
          const StatisticsSectionWidget(),
          SliverToBoxAdapter(child: SizedBox(height: 12.dp)),
          const SectionLabelWidget(title: 'support'),
          const SupportSectionWidget(),
          const MaraudersMapFootprints(),
          const DisappointingSectionWidget(),
          SliverToBoxAdapter(child: SizedBox(height: 12.dp)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 16.dp),
              child: Column(
                spacing: 8.dp,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await customURLLauncher(isWebsite: true, url: 'https://api.kronk.uz/privacy');
                        },
                        child: Text(
                          'Privacy Policy',
                          style: GoogleFonts.quicksand(
                            color: theme.primaryText,
                            fontSize: 18.dp,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: theme.primaryText,
                            decorationThickness: 1,
                          ),
                        ),
                      ),

                      GestureDetector(
                        onTap: () async {
                          await customURLLauncher(isWebsite: true, url: 'https://api.kronk.uz/terms');
                        },
                        child: Text(
                          'Terms of Service',
                          style: GoogleFonts.quicksand(
                            color: theme.primaryText,
                            fontSize: 18.dp,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: theme.primaryText,
                            decorationThickness: 1,
                          ),
                        ),
                      ),
                    ],
                  ),

                  Text(
                    'version: 1.0.0 (beta)',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 18.dp, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 16.dp)),
        ],
      ),
    );
  }
}

class SectionLabelWidget extends ConsumerWidget {
  final String title;
  final bool isServie;

  const SectionLabelWidget({super.key, required this.title, this.isServie = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeNotifierProvider);
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(left: 16.dp, bottom: isServie ? 0 : 4.dp),
        child: Text(
          title,
          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 20.dp, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class AppearanceSectionWidget extends ConsumerWidget {
  const AppearanceSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeNotifierProvider);
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    final List<Themes> allThemes = themeNotifier.getThemes();

    return SliverToBoxAdapter(
      child: SizedBox(
        width: Sizes.screenWidth - 32.dp,
        height: 105.dp,
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.transparent, Colors.black, Colors.black, Colors.black, Colors.black, Colors.transparent],
              stops: [0.0, 0.05, 0.1, 0.9, 0.95, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: ListView.separated(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 16.dp),
            scrollDirection: Axis.horizontal,
            itemCount: allThemes.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () async => await themeNotifier.changeTheme(theme: allThemes.elementAt(index)),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8.dp, horizontal: 12.dp),
                  decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(12.dp)),
                  child: Column(
                    spacing: 8.dp,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: MyTheme.fromThemes(theme: allThemes.elementAt(index)).primaryText,
                            width: 2.dp,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CustomPaint(
                          size: Size(56.dp, 56.dp),
                          painter: HalfCirclePainter(
                            firstColor: MyTheme.fromThemes(theme: allThemes.elementAt(index)).primaryBackground,
                            secondColor: MyTheme.fromThemes(theme: allThemes.elementAt(index)).secondaryBackground,
                          ),
                        ),
                      ),
                      Text(
                        allThemes.elementAt(index).name,
                        style: GoogleFonts.quicksand(
                          color: MyTheme.fromThemes(theme: allThemes.elementAt(index)).primaryText,
                          fontSize: 16.dp,
                          fontWeight: FontWeight.w500,
                          height: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => SizedBox(width: 8.dp),
          ),
        ),
      ),
    );
  }
}

class ServicesSectionWidget extends ConsumerWidget {
  const ServicesSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeNotifierProvider);
    final List<NavbarModel> services = ref.watch(navbarProvider);

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.dp),
      sliver: SliverReorderableList(
        itemCount: services.length,
        onReorder: (int oldIndex, int newIndex) async {
          if (newIndex > oldIndex) newIndex--;
          await ref.read(navbarProvider.notifier).reorderNavbarItem(oldIndex: oldIndex, newIndex: newIndex);
        },
        itemBuilder: (context, index) {
          final service = services.elementAt(index);

          return ReorderableDelayedDragStartListener(
            key: ValueKey(service.route),
            index: index,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.dp, horizontal: 12.dp),
              margin: EdgeInsets.symmetric(vertical: 4.dp),
              decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(12.dp)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    spacing: 8.dp,
                    children: [
                      Icon(Icons.drag_indicator_rounded, size: 20.dp, color: service.isEnabled ? theme.primaryText : theme.secondaryText),
                      Text(
                        service.route.replaceFirst('/', '').toTitleCaseWithSpaces(),
                        style: GoogleFonts.quicksand(color: service.isEnabled ? theme.primaryText : theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500, height: 0),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 8.dp,
                    children: [
                      if (service.isComingSoon)
                        Text(
                          'Coming Soon',
                          style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 12.dp, fontWeight: FontWeight.w500),
                        ),
                      if (service.isPlanned)
                        Text(
                          'Planned',
                          style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 12.dp, fontWeight: FontWeight.w500),
                        ),
                      CustomToggle(index: index, isEnabled: service.isEnabled, toggleable: !service.isPlanned),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class StatisticsSectionWidget extends ConsumerWidget {
  const StatisticsSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeNotifierProvider);
    AsyncValue<StatisticsModel> statistics = ref.watch(settingsStatisticsWsStreamProvider);

    final List<String> statNames = ['weekly', 'monthly', 'yearly'];
    return statistics.when(
      data: (StatisticsModel data) {
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.dp),
          sliver: SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(12.dp)),
              child: DefaultTabController(
                length: 3,
                child: Column(
                  spacing: 12.dp,
                  children: [
                    /// Label & heart animation
                    Padding(
                      padding: EdgeInsets.only(left: 12.dp, top: 12.dp, right: 12.dp),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total users: ${data.total}',
                            style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 24.dp, fontWeight: FontWeight.w500),
                          ),
                          SizedBox(width: 36.dp, height: 36.dp, child: const RiveAnimation.asset('assets/animations/heart.riv')),
                        ],
                      ),
                    ),

                    /// Tabs
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.dp),
                      child: Container(
                        decoration: BoxDecoration(color: theme.primaryBackground, borderRadius: BorderRadius.circular(8.dp)),
                        child: TabBar(
                          padding: EdgeInsets.all(2.dp),
                          dividerHeight: 0,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(6.dp)),
                          labelStyle: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 12.dp, fontWeight: FontWeight.w500),
                          unselectedLabelStyle: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 12.dp, fontWeight: FontWeight.w500),
                          indicatorAnimation: TabIndicatorAnimation.elastic,
                          tabs: List.generate(3, (index) => Tab(height: 24.dp, text: statNames.elementAt(index))),
                        ),
                      ),
                    ),

                    /// Stats
                    Container(
                      width: double.infinity,
                      height: 240.dp,
                      padding: EdgeInsets.only(right: 16.dp),
                      child: TabBarView(
                        children: [
                          StatsBarChart(stats: data.weekly),
                          StatsBarChart(stats: data.monthly),
                          StatsBarChart(stats: data.yearly),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        return SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            height: 200.dp,
            decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(12.dp)),
            child: const RiveAnimation.asset('assets/animations/error_glitch.riv'),
          ),
        );
      },
      loading: () {
        return SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            height: 200.dp,
            decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(12.dp)),
            child: const CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

class SupportSectionWidget extends ConsumerWidget {
  const SupportSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeNotifierProvider);
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.dp),
      sliver: SliverToBoxAdapter(
        child: Column(
          spacing: 8.dp,
          children: [
            /// buymeacoffee
            ElevatedButton(
              onPressed: () async {
                await customURLLauncher(isWebsite: true, url: 'https://buymeacoffee.com/kamronbek');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffFFDD00),
                fixedSize: Size(Sizes.screenWidth - 32.dp, 52.dp),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
              ),
              child: const VectorGraphic(loader: AssetBytesLoader('assets/svg/bmc-button.svg')),
            ),

            /// tirikchilik
            ElevatedButton(
              onPressed: () async {
                await customURLLauncher(isWebsite: true, url: 'https://tirikchilik.uz/kamronbek');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                fixedSize: Size(Sizes.screenWidth - 32.dp, 52.dp),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
              ),
              child: VectorGraphic(loader: const AssetBytesLoader('assets/svg/tirikchilik.svg'), height: 16.dp),
            ),

            /// Motivational text
            Text(
              "Hey, I'm Kamronbek — the solo *junior* developer behind Kronk.\n\n"
              'I built this app completely on my own, under constant pressure, with a lot of stress and family problems.\n\n'
              'It was made in survival mode.\n\n'
              "Now it's finally live — but keeping it online costs \$110 every month. I don’t have a steady income yet, and I can’t do this alone.\n\n"
              'If you like the app, please help — sponsor, share, or just tell a friend.\n\n'
              "Thanks for reading this far. You’re either really kind or really bored. Either way, you're part of it now.",
              style: GoogleFonts.quicksand(color: theme.primaryText),
            ),
          ],
        ),
      ),
    );
  }
}

class DisappointingSectionWidget extends ConsumerWidget {
  const DisappointingSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeNotifierProvider);
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 12.dp),
      sliver: SliverToBoxAdapter(
        child: Column(
          spacing: 8.dp,
          children: [
            /// logout
            ElevatedButton(
              onPressed: () async {
                final Storage storage = Storage();
                await storage.logOut();
                if (!context.mounted) return;
                context.push('/welcome');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                fixedSize: Size(Sizes.screenWidth - 32.dp, 52.dp),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
              ),
              child: Text(
                'Log out',
                style: GoogleFonts.quicksand(color: theme.primaryBackground, fontSize: 18.dp, fontWeight: FontWeight.w700),
              ),
            ),

            /// Delete account
            OutlinedButton(
              onPressed: () async {
                final Storage storage = Storage();
                final UserService userService = UserService();
                final UserModel? user = storage.getUser();
                if (user == null) return;

                try {
                  final bool _ = await userService.fetchDeleteProfile();
                } catch (error) {
                  if (!context.mounted) return;
                  if (GoRouterState.of(context).path == '/settings') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: theme.secondaryBackground,
                        behavior: SnackBarBehavior.floating,
                        dismissDirection: DismissDirection.horizontal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                        margin: EdgeInsets.only(left: 28.dp, right: 28.dp, bottom: Sizes.screenHeight - 96.dp),
                        content: Text(
                          error.toString(),
                          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, height: 0),
                        ),
                      ),
                    );
                  }
                }

                await storage.logOut();
                googleSignIn.signOut();
                if (!context.mounted) return;
                context.push('/welcome');
              },
              style: OutlinedButton.styleFrom(
                fixedSize: Size(Sizes.screenWidth - 32.dp, 52.dp),
                side: BorderSide(color: Colors.redAccent, width: 2.dp),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
              ),
              child: Text(
                'Delete account',
                style: GoogleFonts.quicksand(color: Colors.redAccent, fontSize: 18.dp, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MaraudersMapFootprints extends ConsumerWidget {
  const MaraudersMapFootprints({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    return SliverToBoxAdapter(
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [Colors.transparent, theme.secondaryText, theme.primaryText, Colors.redAccent, Colors.redAccent.withAlpha(128), Colors.redAccent.withAlpha(0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: const VectorGraphic(loader: AssetBytesLoader('assets/svg/footprints.svg')),
      ),
    );
  }
}

class BackButtonWidget extends ConsumerWidget {
  const BackButtonWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeNotifierProvider);
    final bool isAnyServiceEnabled = ref.watch(navbarProvider).any((service) => service.isEnabled);

    return IconButton(
      onPressed: () {
        if (!isAnyServiceEnabled) {
          context.go('/welcome');
        } else {
          final Storage storage = Storage();
          storage.setSettingsAll({'isDoneSettings': true});
          String firstRoute = storage.getRoute();
          context.go(firstRoute);
        }
      },
      icon: Icon(Icons.arrow_back_rounded, color: theme.primaryText, size: 24.dp),
    );
  }
}
