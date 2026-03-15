import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/base/assets/svgs/app_svgs.dart';
import 'package:open_player/presentation/common/widgets/social_media_icon_button.dart/social_media_icon_button.dart';
import 'package:url_launcher/link.dart';
import '../../../../../base/strings/app_strings.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appLogo = Theme.of(context).brightness == Brightness.dark
        ? AppSvgs.logoDarkMode
        : AppSvgs.logoLightMode;
    final mq = MediaQuery.sizeOf(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: FadeIn(
          duration: const Duration(milliseconds: 800),
          child: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(CupertinoIcons.back),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    const Gap(20),
                    // Logo Section
                    SlideInDown(
                      duration: const Duration(milliseconds: 1000),
                      child: Hero(
                        tag: 'app_logo',
                        child: Link(
                          uri: Uri.parse("https://frkudn.github.io/player/"),
                          target: LinkTarget.blank,
                          builder: (context, followLink) => InkWell(
                            onTap: () {
                              followLink!();
                            },
                            child: SvgPicture.asset(
                              appLogo,
                              height: mq.height * 0.25,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Version Info
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Version ${AppStrings.appVersion}",
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ),

                    const Gap(20),

                    // Open Source Section
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      duration: const Duration(milliseconds: 800),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Text(
                              "Open Source Project",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Gap(12),
                            Text(
                              "A powerful media player built with love and care, free from ads and tracking.",
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    height: 1.5,
                                    fontFamily: AppFonts.sourceCodePro,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Gap(32),

                    // GitHub/Website Section
                    FadeInUp(
                      delay: const Duration(milliseconds: 800),
                      duration: const Duration(milliseconds: 800),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              //---- GitHub
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .cardColor
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const SocialMediaIconButton(
                                  url: "https://github.com/frkudn/player",
                                  icon: HugeIcons.strokeRoundedGithub,
                                  iconSize: 40.0,
                                ),
                              ),
                              Gap(5),
                              //---- GitLab
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .cardColor
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const SocialMediaIconButton(
                                  url: "https://gitlab.com/frkudn/player",
                                  icon: HugeIcons.strokeRoundedGitlab,
                                  iconSize: 40.0,
                                ),
                              ),
                            ],
                          ),
                          const Gap(8),
                          Text(
                            " ⭐ on",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            "GitHub | GitLab",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Social Links Section
                    FadeInUp(
                      delay: const Duration(milliseconds: 1000),
                      duration: const Duration(milliseconds: 800),
                      child: Column(
                        children: [
                          Text(
                            "Connect With Me",
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Gap(16),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SocialMediaIconButton(
                                url: "https://www.linkedin.com/in/frkudn/",
                                icon: HugeIcons.strokeRoundedLinkedin01,
                              ),
                              Gap(24),
                              SocialMediaIconButton(
                                url: "https://www.twitter.com/frkudn",
                                icon: HugeIcons.strokeRoundedTwitter,
                              ),
                              Gap(24),
                              SocialMediaIconButton(
                                url: "",
                                icon: HugeIcons.strokeRoundedMail01,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Gap(24),

                    // Footer
                    FadeInUp(
                      delay: const Duration(milliseconds: 1200),
                      child: Text(
                        "Made with ❤️ by Furqan Uddin",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    const Gap(24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
