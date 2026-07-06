import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/configurations/translation_helper.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:sm_networking/presentation/view/bottom_bar_view/bottom_nav_bar_view.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:string_validator/string_validator.dart';
import '../../../../../application/auth_bloc/login_bloc.dart';
import '../../../../../application/error_string.dart';
import '../../../../../application/user_provider.dart';
import '../../../../../configurations/enums.dart';
import '../../../../../infrastructure/model/agent.dart';
import '../../../../../infrastructure/model/user.dart';
import '../../../../../infrastructure/services/auth.dart';
import '../../../../../injection_container.dart';
import '../../../../elements/app_button.dart';
import '../../../../elements/auth_field.dart';
import '../../../../elements/error_dialog.dart';
import '../../../../elements/flush_bar.dart';
import '../../../../elements/processing_widget.dart';
import '../../widgets/auth_button.dart';

class LogInBody extends StatefulWidget {
  const LogInBody({super.key});

  @override
  State<LogInBody> createState() => _LogInBodyState();
}

class _LogInBodyState extends State<LogInBody> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool showPassword = false;
  bool isLoading = false;

  bool isPhoneNumber(String input) {
    // Remove common phone number characters
    final cleanedInput = input.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    // Check if it contains only digits and is of reasonable length (8-15 digits)
    return RegExp(r'^\d{8,15}$').hasMatch(cleanedInput);
  }

  /// Shown when the backend rejects login with ALREADY_LOGGED_IN. On
  /// confirm, re-fires LoginUserEvent with isForce: true using the
  /// credentials carried on the state, so the user doesn't have to
  /// retype anything.
  ///
  /// NOTE: I haven't seen error_dialog.dart's contents (it's imported
  /// above but I don't know its API), so this uses a plain AlertDialog
  /// rather than guessing at that helper's signature. Swap this out for
  /// your existing dialog style if error_dialog.dart fits better here.
  void _showForceLoginDialog(BuildContext context, AuthAlreadyLoggedIn state) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Already Logged In"),
          content: Text(state.message),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            if (state.canForceLogin)
              TextButton(
                child: const Text("Yes, Log In"),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  BlocProvider.of<AuthBloc>(context).add(
                    LoginUserEvent(
                      identifier: state.identifier,
                      password: state.password,
                      isPhone: state.isPhone,
                      isForce: true,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<UserProvider>(context);
    return BlocProvider(
      create: (context) => sl<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is LoginLoaded) {
            if (state.model.user!.isAdminVerified == true &&
                state.model.user!.isAdminVerified == true) {
              sl<SharedPreferences>().setString('USER_DATA', userModelToJson(state.model));

              user.saveSalesUserDetails(state.model);
              print("Userdate: ${userModelToJson(state.model)}");
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BottomNavBarView()));
            } else if (state.model.user!.isAdminVerified == false) {
              getFlushBar(context,
                  title: "Your account still under approval by an admin.");
            } else if (state.model.user!.isActive == false) {
              getFlushBar(context,
                  title: "Sorry! Your account has been disabled by an admin.");
            }
          } else if (state is AuthFailed) {
            getFlushBar(context, title: state.message.toString());
          } else if (state is AuthAlreadyLoggedIn) {
            _showForceLoginDialog(context, state);
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return LoadingOverlay(
              isLoading: state is AuthLoading,
              color: Colors.transparent,
              progressIndicator: const ProcessingWidget(),
              child: Scaffold(
                bottomNavigationBar: Padding(
                  padding:
                  const EdgeInsets.only(bottom: 18.0, right: 18, left: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton(
                          onPressed: () {
                            if (emailController.text.isEmpty) {
                              getFlushBar(context,
                                  title: "Email or Phone cannot be empty.");
                              return;
                            }

                            if (passwordController.text.isEmpty) {
                              getFlushBar(context,
                                  title: "Password cannot be empty.");
                              return;
                            }

                            final input = emailController.text.trim().toLowerCase();
                            final isPhone = isPhoneNumber(input);

                            BlocProvider.of<AuthBloc>(context).add(
                              LoginUserEvent(
                                identifier: input,
                                password: passwordController.text,
                                isPhone: isPhone,
                              ),
                            );
                          },
                          btnLabel: TranslationHelper.getTranslatedText("login")),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
                body: SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 80,
                          ),
                          Text(
                            TranslationHelper.getTranslatedText("login"),
                            style: FrontendConfigs.kHeadingStyle,
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          CustomText(
                            text: TranslationHelper.getTranslatedText(
                                "enter_mobile_number"),
                            fontSize: 14,
                            color: FrontendConfigs.kAuthTextColor,
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          const SizedBox(height: 30),
                          CustomTextField(
                            text: 'Email or Phone',
                            onTap: () {},
                            controller: emailController,
                            textInputAction: TextInputAction.next,
                            keyBoardType: TextInputType.emailAddress,
                            icon: 'assets/icons/email.svg',
                          ),
                          const SizedBox(height: 22),
                          CustomTextField(
                            text: 'Password',
                            isSecure: !showPassword,
                            onTap: () {
                              showPassword = !showPassword;
                              setState(() {});
                            },
                            controller: passwordController,
                            keyBoardType: TextInputType.text,
                            textInputAction: TextInputAction.done,
                            isPasswordField: true,
                            icon: 'assets/icons/pwd.svg',
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}