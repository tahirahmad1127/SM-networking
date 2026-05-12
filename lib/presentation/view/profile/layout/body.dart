import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/translation_helper.dart';
import 'package:sm_networking/infrastructure/model/user.dart';
import 'package:sm_networking/infrastructure/services/upload_file_services.dart';
import 'package:sm_networking/presentation/elements/flush_bar.dart';
import 'package:sm_networking/presentation/elements/navigation_dialog.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:sm_networking/presentation/view/auth/log_in/log_in_view.dart';
import 'package:sm_networking/presentation/view/category_listing/category_listing_view.dart';
import 'package:sm_networking/presentation/view/map/map_retailers.dart';
import 'package:sm_networking/presentation/view/profile/layout/widgets/profile_card.dart';
import 'package:launch_review_latest/launch_review_latest.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher.dart' ;

import '../../../../configurations/frontend_configs.dart';
import '../../../../infrastructure/services/retailers_cache.dart';
import '../../../elements/bottom_sheet/langauge.dart';
import '../../../elements/custom_text.dart';
import '../../privacy_policy/privacy_policy.dart';
import '../../terms_condition/terms_condition.dart';

class ProfileBody extends StatefulWidget {
  const ProfileBody({super.key});

  @override
  State<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody> {
  bool value = false;

  File? _image;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<UserProvider>(context);
    return LoadingOverlay(
      isLoading: isLoading,
      progressIndicator: const ProcessingWidget(),
      color: Colors.transparent,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              children: [
                const SizedBox(
                  height: 8,
                ),
                Container(
                  height: 97,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      borderRadius: FrontendConfigs.kAppBorder,
                      color: Colors.white),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14.0),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () async {
                            // await getProfileImage();
                            // isLoading = true;
                            // setState(() {});
                            // if (_image != null) {
                            //   try {
                            //     await UploadFileServices()
                            //         .getUrl(context,_image!)
                            //         .then((value) async {
                            //       await UserServices().updateUserImage(
                            //           UserModel(
                            //               docId: user
                            //                   .getUserDetails()!
                            //                   .docId
                            //                   .toString(),
                            //               image: value));
                            //     });
                            //     await UserServices()
                            //         .fetchUserDetails(user
                            //         .getUserDetails()!
                            //         .docId
                            //         .toString())
                            //         .then((value) {
                            //       user.saveUserDetails(value);
                            //     });
                            //     _image = null;
                            //     isLoading = false;
                            //     setState(() {});
                            //     getFlushBar(context,
                            //         title:
                            //         "Profile has been updated successfully.");
                            //   } catch (e) {
                            //     isLoading = false;
                            //     setState(() {});
                            //     getFlushBar(context, title: e.toString());
                            //   }
                            // }
                          },
                          child: _image != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.file(
                              _image!,
                              height: 55,
                              width: 55,
                              fit: BoxFit.fill,
                            ),
                          )
                              : ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: ExtendedImage.network(
                              user.getSalesUserDetails()!.user!.image.toString(),
                              height: 55,
                              width: 55,
                              fit: BoxFit.fill,
                              cache: true,
                              loadStateChanged:
                                  (ExtendedImageState state) {
                                switch (
                                state.extendedImageLoadState) {
                                  case LoadState.loading:
                                    return ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(100),
                                      child: Image.asset(
                                        "assets/images/ph.jpeg",
                                        fit: BoxFit.fill,
                                        height: 55,
                                        width: 55,
                                      ),
                                    );
                                  case LoadState.failed:
                                    return ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(100),
                                      child: Image.asset(
                                        "assets/images/ph.jpeg",
                                        fit: BoxFit.fill,
                                        height: 55,
                                        width: 55,
                                      ),
                                    );
                                  default:
                                    return state.completedWidget;
                                }
                              },
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(30.0)),
                              //cancelToken: cancellationToken,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user.getSalesUserDetails()!.user!.name.toString(),
                                style: FrontendConfigs.kTitleStyle,
                                softWrap: true,
                                maxLines: 2,
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              CustomText(
                                text: user.getSalesUserDetails()!.user!.phone.toString(),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),

                // InkWell(
                //   borderRadius: FrontendConfigs.kAppBorder,
                //   onTap: () {
                //     Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //             builder: (context) => const CategoryListingView()));
                //   },
                //   child: ProfileCard(
                //     lebal: TranslationHelper.getTranslatedText("View Products"),
                //   ),
                // ),
                // const SizedBox(
                //   height: 12,
                // ),
                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TermsConditionView()));
                  },
                  child: ProfileCard(
                    lebal: TranslationHelper.getTranslatedText("terms_condition"),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyView()));
                  },
                  child: ProfileCard(
                    lebal: TranslationHelper.getTranslatedText("privacy_policy"),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () {
                    _launchUrl(
                        "https://wa.me/+923350059585?text=${Uri.parse("Welcome to Karyana!")}");
                  },
                  child: ProfileCard(
                    lebal: TranslationHelper.getTranslatedText("help_support"),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () {
                    LaunchReviewLatest.launch();
                  },
                  child: ProfileCard(
                    lebal: TranslationHelper.getTranslatedText("rate_our_app"),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () {
                    _launchUrl("https://karyana.co");
                  },
                  child: ProfileCard(
                    lebal: 'About Us',
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () async {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    showNavigationDialog(context,
                        message: "Do you really want to logout from app?",
                        buttonText: "Yes", navigation: () async {
                          await FirebaseAuth.instance.signOut();
                          prefs.clear();
                          await RetailerCacheService.clearRetailersCache();
                          await RetailerCacheService.clearBanksCache();
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LogInView()),
                                  (route) => false);
                        }, secondButtonText: "No", showSecondButton: true);
                  },
                  child: ProfileCard(
                    lebal: TranslationHelper.getTranslatedText("logout"),
                    textColor: FrontendConfigs.kPrimaryColor,
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future getProfileImage() async {
    ImagePicker picker = ImagePicker();
    XFile? pickedFile;
    pickedFile = await picker.pickImage(
      imageQuality: 20,
      source: ImageSource.gallery,
    );

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }
}