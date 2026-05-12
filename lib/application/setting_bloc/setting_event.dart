part of 'setting_bloc.dart';

@immutable
abstract class SettingEvent extends Equatable {
  const SettingEvent();

  @override
  List<Object> get props => [];
}

class GetTermsConditionEvent extends SettingEvent {
  const GetTermsConditionEvent();
}

class GetPrivacyPolicyEvent extends SettingEvent {
  const GetPrivacyPolicyEvent();
}
